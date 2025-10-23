import 'package:flutter/material.dart';
import 'package:flutter_home_page/project/app/bloc/space.dart';
import 'package:flutter_home_page/project/app/earth.dart';
import 'package:flutter_home_page/project/app/earth_1.dart';
import 'package:flutter_home_page/project/app/three_example.dart';
import 'package:flutter_home_page/project/app/tryshape.dart';


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
