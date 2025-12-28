import 'package:flutter/material.dart';
import 'package:flutter_home_page/project/app/bloc/space.dart';
import 'package:flutter_home_page/project/app/widgets/flame.dart';

void main() {
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
