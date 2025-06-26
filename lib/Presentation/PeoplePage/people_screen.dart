import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
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

  void _addPerson() async {
    if (!_formKey.currentState!.validate()) return;

    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User not logged in.')));
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

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('User not logged in.')));
    }

    final uid = user.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('People in Group')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Form(
              key: _formKey,
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Enter Name',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                    ),
                  ),

                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _addPerson,
                  ),
                ],
              ),
            ),
          ),
          Column(
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("Add Expense"),
                onPressed: () {
                  Get.to(() => AddExpenseScreen());
                },
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.analytics),
                label: const Text("View Settlements"),
                onPressed: () {
                  Get.to(() => SettlementsScreen());
                },
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.pie_chart),
                label: const Text("View Chart"),
                onPressed: () {
                  // Get.to(() => const ChartsScreen());
                },
              ),

            ],
          ),
          // SizedBox(height: 100,),
          const Divider(),
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
                  return const Center(child: Text('No people added yet.'));
                }

                final peopleDocs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: peopleDocs.length,
                  itemBuilder: (ctx, index) {
                    final data =
                        peopleDocs[index].data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(data['name']),
                      subtitle: Text(
                        'Paid: ₹${data['totalPaid'] ?? 0} | Owes: ₹${data['totalOwes'] ?? 0}',
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
