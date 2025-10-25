import 'package:flutter/material.dart';
import 'package:flutter_home_page/project/app/bloc/space.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Planet Scroll Animation',
      theme: ThemeData.dark(),
      home: SpaceScene(),
      debugShowCheckedModeBanner: false,
    );
  }
}
