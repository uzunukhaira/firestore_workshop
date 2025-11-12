import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'todo_page.dart';
import 'firebase_options.dart'; // pastikan file ini ada (hasil dari flutterfire configure)

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // inisialisasi untuk web
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Firestore To-Do List (Web)',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const TodoPage(),
    );
  }
}
