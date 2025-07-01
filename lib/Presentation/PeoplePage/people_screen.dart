import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../Models/personal_model.dart'; // Make sure this file exists
import 'package:uuid/uuid.dart';

import '../AddExpensePage/add_expense_screen.dart';
import '../ChartPage/chart_screen.dart';
import '../settlement_screen.dart';

class PeopleScreen extends StatefulWidget {
  const PeopleScreen({super.key});

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final _uuid = const Uuid();

  String _tripTitle = 'My Trip';

  @override
  void initState() {
    super.initState();
    _loadTripTitle();
  }

  // All methods ---------------------------------------------------

  Future<void> _loadTripTitle() async {
    final uid = _auth.currentUser!.uid;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('meta')
        .doc('trip')
        .get();

    if (doc.exists) {
      setState(() {
        _tripTitle = doc['title'];
      });
    }
  }

  Future<void> _confirmResetAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          "Reset Trip",
          style: GoogleFonts.braahOne(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        content: Text(
          "This will delete all people and expenses. Do you want to start a new trip?",
          style: GoogleFonts.braahOne(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              "Cancel",
              style: GoogleFonts.braahOne(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              "Yes, Reset",
              style: GoogleFonts.braahOne(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _resetTripData();
    }
  }

  Future<void> _resetTripData() async {
    final uid = _auth.currentUser!.uid;

    // Delete people
    final peopleSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('people')
        .get();
    for (var doc in peopleSnap.docs) {
      await doc.reference.delete();
    }

    // Delete expenses
    final expenseSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('expenses')
        .get();
    for (var doc in expenseSnap.docs) {
      await doc.reference.delete();
    }

    // Ask for new trip title
    final controller = TextEditingController();
    final newTitle = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          "Enter New Trip Name",
          style: GoogleFonts.braahOne(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: "Trip Title",
            hintStyle: GoogleFonts.braahOne(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              "Cancel",
              style: GoogleFonts.braahOne(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(
              "Save",
              style: GoogleFonts.braahOne(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );

    if (newTitle != null && newTitle.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('meta')
          .doc('trip')
          .set({'title': newTitle});

      setState(() {
        _tripTitle = newTitle;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Trip reset to '$newTitle'")));
    }
  } // ResetTrip function

  void _addPerson() async {
    if (!_formKey.currentState!.validate()) return;

    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'User not logged in.',
            style: GoogleFonts.braahOne(fontSize: 18, color: Colors.black),
          ),
        ),
      );
      return;
    }

    final uid = user.uid;
    final personId = _uuid.v4();

    final person = PersonModel(
      id: personId,
      name: _nameController.text.trim(),
      totalPaid: 0.0,
      totalOwes: 0.0,
    );

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('people')
        .doc(personId)
        .set(person.toJson());

    _nameController.clear();
  }
  //  ---------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('User not logged in.')));
    }

    final uid = user.uid;

    return Scaffold(
      appBar: AppBar(
        leading: Icon(Icons.view_headline),
        title: Text(
          "Tittle :- " + _tripTitle,
          style: GoogleFonts.braahOne(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            tooltip: "Start New Trip",
            onPressed: _confirmResetAllData,
          ),
        ],
      ),

      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      width: 50,
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.people, color: Colors.black),
                          hintText: "Enter Name",
                          hintStyle: GoogleFonts.braahOne(
                            fontWeight: FontWeight.w200,
                            color: Colors.black,
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a name';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.add,
                        color: Colors.black,
                        size: 28,
                      ),
                      onPressed: _addPerson,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Column(
            children: [
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
                    borderRadius: BorderRadius.circular(12), // rounded corners
                  ),
                ),
                onPressed: () {
                  Get.to(() => AddExpenseScreen());
                },
              ),
              SizedBox(height: 8),
              ElevatedButton.icon(
                icon: Icon(Icons.leaderboard, color: Colors.white, size: 20),
                label: Text(
                  "View Settlements",
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
                    borderRadius: BorderRadius.circular(12), // rounded corners
                  ),
                ),
                onPressed: () {
                  Get.to(() => AddExpenseScreen());
                },
              ),
            ],
          ),
          SizedBox(height: 20),
          Divider(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('people')
                  .snapshots(),
              builder: (ctx, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No people added yet.',
                      style: GoogleFonts.braahOne(
                        color: Colors.black,
                        fontSize: 16,
                      ),
                    ),
                  );
                }

                final peopleDocs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: peopleDocs.length,
                  itemBuilder: (ctx, index) {
                    final data =
                        peopleDocs[index].data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(
                        data['name'],
                        style: GoogleFonts.braahOne(
                          color: Colors.black,
                          fontSize: 18,
                        ),
                      ),
                      subtitle: Text(
                        'Paid: ₹${data['totalPaid'] ?? 0} | Owes: ₹${data['totalOwes'] ?? 0}',
                        style: GoogleFonts.braahOne(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
