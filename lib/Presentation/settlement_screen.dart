import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SettlementsScreen extends StatefulWidget {
  const SettlementsScreen({super.key});

  @override
  State<SettlementsScreen> createState() => _SettlementsScreenState();
}

class _SettlementsScreenState extends State<SettlementsScreen> {
  final _auth = FirebaseAuth.instance;
  Map<String, String> _personNames = {};
  Map<String, Map<String, double>> _owedMap = {}; // from → to → amount

  @override
  void initState() {
    super.initState();
    _calculateAndSimplify();
  }

  Future<void> _calculateAndSimplify() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final uid = user.uid;

    // 1. Load people
    final peopleSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('people')
        .get();

    for (var doc in peopleSnap.docs) {
      _personNames[doc.id] = doc['name'];
    }

    // 2. Load expenses
    final expenseSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('expenses')
        .get();

    // 3. Build owed map
    for (var expenseDoc in expenseSnap.docs) {
      final data = expenseDoc.data();
      final double amount = data['amount'] * 1.0;
      final String paidBy = data['paidBy'];
      final List participants = data['participants'];
      final double share = amount / participants.length;

      for (String participantId in participants) {
        if (participantId == paidBy) continue;

        _owedMap.putIfAbsent(participantId, () => {});
        _owedMap[participantId]!.putIfAbsent(paidBy, () => 0.0);
        _owedMap[participantId]![paidBy] =
        (_owedMap[participantId]![paidBy]! + share);
      }
    }

    // 4. Simplify debts
    _simplifyOwedMap();

    setState(() {});
  }

  void _simplifyOwedMap() {
    final people = _owedMap.keys.toSet().union(
      _owedMap.values.expand((map) => map.keys).toSet(),
    );

    for (final k in people) {
      for (final i in people) {
        for (final j in people) {
          if (i == j || i == k || j == k) continue;

          final ik = _owedMap[i]?[k] ?? 0.0;
          final kj = _owedMap[k]?[j] ?? 0.0;

          final minTransfer = ik < kj ? ik : kj;

          if (ik > 0 && kj > 0) {
            _owedMap[i]![j] = (_owedMap[i]?[j] ?? 0) + minTransfer;
            _owedMap[i]![k] = ik - minTransfer;
            _owedMap[k]![j] = kj - minTransfer;

            if (_owedMap[i]![k] == 0) _owedMap[i]!.remove(k);
            if (_owedMap[k]![j] == 0) _owedMap[k]!.remove(j);
          }
        }
      }
    }

    // Clean zero values
    _owedMap.removeWhere((from, toMap) => toMap.isEmpty);
  }

  @override
  Widget build(BuildContext context) {
    if (_owedMap.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("No data to show yet.")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Simplified Settlements')),
      body: ListView(
        children: _owedMap.entries.expand((entry) {
          final fromId = entry.key;
          final debts = entry.value;

          return debts.entries.map((e) {
            final toId = e.key;
            final amount = e.value;

            return ListTile(
              leading: const Icon(Icons.payments),
              title: Text(
                "${_personNames[fromId] ?? 'Someone'} owes ${_personNames[toId] ?? 'Someone'} ₹${amount.toStringAsFixed(2)}",
              ),
            );
          });
        }).toList(),
      ),
    );
  }
}
