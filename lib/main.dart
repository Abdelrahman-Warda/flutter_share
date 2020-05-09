import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_share/pages/home.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Firestore.instance.settings(timestampsInSnapshotsEnabled: true).then((_) {
    // print('Timestamp enabled in snapshots\n');
  }, onError: (_) {
    // print('Error enabling timestamps in snapshots\n');
  });
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlutterShare',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        accentColor: Colors.teal,
      ),
      debugShowCheckedModeBanner: false,
      home: Home(),
    );
  }
}
