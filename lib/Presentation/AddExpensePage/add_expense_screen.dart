import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _uuid = Uuid();

  String? _selectedPayerId;
  Map<String, String> _personNames = {}; // id => name
  Set<String> _selectedParticipantIds = {};

  @override
  void initState() {
    super.initState();
    _fetchPeople();
  }

  Future<void> _fetchPeople() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('people')
        .get();

    final names = <String, String>{};
    for (var doc in snapshot.docs) {
      names[doc.id] = doc['name'];
    }

    setState(() {
      _personNames = names;
    });
  }

  void _submitExpense() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) return;

    if (_selectedPayerId == null || _selectedParticipantIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select payer and at least one participant"),
        ),
      );
      return;
    }

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      final uid = user.uid;
      final expenseId = _uuid.v4();
      final amount = double.tryParse(_amountController.text);
      if (amount == null) throw Exception("Invalid amount");

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('expenses')
          .doc(expenseId)
          .set({
            'id': expenseId,
            'title': _titleController.text.trim(),
            'amount': amount,
            'paidBy': _selectedPayerId,
            'participants': _selectedParticipantIds.toList(),
            'dateTime': DateTime.now().toIso8601String(),
          });
      final double share = amount / _selectedParticipantIds.length;

      // 1. Update totalPaid for payer
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('people')
          .doc(_selectedPayerId)
          .update({'totalPaid': FieldValue.increment(amount)});

      // 2. Update totalOwes for each participant (except payer)
      for (String participantId in _selectedParticipantIds) {
        if (participantId == _selectedPayerId) continue;

        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('people')
            .doc(participantId)
            .update({'totalOwes': FieldValue.increment(share)});
      }

      if (context.mounted) {
        Navigator.of(context).pop(); // Go back safely
      }
    } catch (e) {
      print("Error adding expense: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add expense: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Add Expense',
          style: GoogleFonts.braahOne(color: Colors.black, fontSize: 24),
        ),
      ),
      body: _personNames.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Expense Title',
                        labelStyle: GoogleFonts.braahOne(
                          color: Colors.black,
                          fontSize: 14,
                        ),
                        hintText: 'Enter expense title',
                        hintStyle: GoogleFonts.braahOne(
                          color: Colors.black,
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: Colors.blue.withOpacity(0.1),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Colors.blue,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Enter a title'
                          : null,
                    ),

                    SizedBox(height: 10),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Total Amount (₹)',
                        labelStyle: GoogleFonts.braahOne(
                          color: Colors.black,
                          fontSize: 14,
                        ),
                        hintText: 'Enter amount',
                        hintStyle: GoogleFonts.braahOne(
                          color: Colors.black,
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: Colors.blue.withOpacity(0.1),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.black54),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Colors.blue,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Enter an amount'
                          : null,
                    ),

                    SizedBox(height: 20),

                    DropdownButtonFormField<String>(
                      value: _selectedPayerId,
                      items: _personNames.entries
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        setState(() => _selectedPayerId = val);
                      },
                      validator: (val) =>
                          val == null ? 'Select who paid' : null,
                      style: GoogleFonts.braahOne(
                        color: Colors.black,
                        fontSize: 17,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Who Paid?',
                        labelStyle: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                        filled: true,
                        fillColor: Colors.blue.withOpacity(0.1),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.black54),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Colors.blue,
                            width: 2,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 20),
                    Text(
                      "Who all were involved?",
                      style: GoogleFonts.braahOne(
                        color: Colors.black,
                        fontSize: 16,
                      ),
                    ),
                    ..._personNames.entries.map((entry) {
                      final id = entry.key;
                      final name = entry.value;
                      return CheckboxListTile(
                        checkColor: Colors.white,
                        fillColor:MaterialStateProperty.all<Color>(Colors.blue),
                        value: _selectedParticipantIds.contains(id),
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedParticipantIds.add(id);
                            } else {
                              _selectedParticipantIds.remove(id);
                            }
                          });
                        },
                        title: Text(
                          name,
                          style: GoogleFonts.braahOne(
                            color: Colors.black,
                            fontSize: 18,
                          ),
                        ),
                      );
                    }),
                    SizedBox(height: 10),
                    ElevatedButton.icon(
                      icon: Icon(Icons.add, color: Colors.white, size: 20),
                      label: Text(
                        "Add Expense",
                        style: GoogleFonts.braahOne(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),

                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        minimumSize: Size(340, 45), // button color
                        // full width, height = 50
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            12,
                          ), // rounded corners
                        ),
                      ),
                      onPressed: () {
                        _submitExpense();
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
