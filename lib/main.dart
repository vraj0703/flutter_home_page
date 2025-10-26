import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_home_page/project/app/bloc/space.dart';
import 'package:flutter_home_page/project/app/bloc/space_bloc.dart';
import 'package:three_dart/three3d/dart_helpers.dart';

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
      home: SpaceScene(child: App()),
      debugShowCheckedModeBanner: false,
    );
  }
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    var controller = TextEditingController();
    return Scaffold(
      body: Column(

      ),
      backgroundColor: Colors.transparent,
    );
  }
}

double pd(String a) => parseFloat(a);
