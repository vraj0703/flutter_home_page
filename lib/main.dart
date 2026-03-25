import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_home_page/project/app/views/scene.dart';
import 'package:flutter_home_page/project/testimonial/di.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyCLNmdfPXgRquqKOy_X5rF2RxD1S6ubrRY',
      appId: '1:731034902829:web:35e0f296090bf9cf3ef3a4',
      messagingSenderId: '731034902829',
      projectId: 'vishal-raj-space-firebase-home',
      authDomain: 'vishal-raj-space-firebase-home.firebaseapp.com',
      storageBucket: 'vishal-raj-space-firebase-home.firebasestorage.app',
    ),
  );

  TestimonialDI.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vishal Raj',
      theme: ThemeData.dark(),
      home: FlameScene(onClick: () {}),
      debugShowCheckedModeBanner: false,
    );
  }
}
