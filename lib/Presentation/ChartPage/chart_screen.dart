// import 'package:charts_flutter/flutter.dart' as charts;
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
//
// class ChartsScreen extends StatefulWidget {
//   const ChartsScreen({super.key});
//
//   @override
//   State<ChartsScreen> createState() => _ChartsScreenState();
// }
//
// class _ChartsScreenState extends State<ChartsScreen> {
//   final _auth = FirebaseAuth.instance;
//   Map<String, double> _contributions = {};
//   Map<String, String> _personNames = {};
//
//   @override
//   void initState() {
//     super.initState();
//     _loadContributions();
//   }
//
//   Future<void> _loadContributions() async {
//     final user = _auth.currentUser;
//     if (user == null) return;
//
//     final uid = user.uid;
//
//     final peopleSnap = await FirebaseFirestore.instance
//         .collection('users')
//         .doc(uid)
//         .collection('people')
//         .get();
//
//     for (var doc in peopleSnap.docs) {
//       final name = doc['name'];
//       final paid = (doc['totalPaid'] ?? 0).toDouble();
//
//       _personNames[doc.id] = name;
//       _contributions[name] = paid;
//     }
//
//     setState(() {});
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (_contributions.isEmpty) {
//       return const Scaffold(body: Center(child: Text("No data to show yet.")));
//     }
//
//     final data = _contributions.entries
//         .map((e) => _ChartEntry(e.key, e.value))
//         .toList();
//
//     // final series = [
//     //   charts.Series<_ChartEntry, String>(
//     //     id: 'Contributions',
//     //     domainFn: (entry, _) => entry.name,
//     //     measureFn: (entry, _) => entry.amount,
//     //     colorFn: (_, __) => charts.MaterialPalette.teal.shadeDefault,
//     //     data: data,
//     //     labelAccessorFn: (entry, _) => '${entry.name}: ₹${entry.amount.toStringAsFixed(0)}',
//     //   )
//     // ];
//
//     return Scaffold(
//       appBar: AppBar(title: const Text('Contributions Chart')),
//       body: Padding(
//         padding: const EdgeInsets.all(12),
//         child: charts.PieChart<String>(
//           series,
//           animate: true,
//           defaultRenderer: charts.ArcRendererConfig(
//             arcRendererDecorators: [
//               charts.ArcLabelDecorator(labelPosition: charts.ArcLabelPosition.auto),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class _ChartEntry {
//   final String name;
//   final double amount;
//
//   _ChartEntry(this.name, this.amount);
// }
