import 'package:flutter/material.dart';

// app builder wrapper for facilitating redrawing of the entire app
// supporting live light / dark mode update

class AppBuilder extends StatefulWidget {
  final Function(BuildContext) builder;

  const AppBuilder({Key? key, required this.builder}) : super(key: key);

  @override
  AppBuilderState createState() => new AppBuilderState();

  static AppBuilderState of(BuildContext context) {
    return context.findAncestorStateOfType<AppBuilderState>()!;
  }
}

class AppBuilderState extends State<AppBuilder> {
  @override
  Widget build(BuildContext context) {
    return widget.builder(context);
  }

  void rebuild() {
    setState(() {});
  }
}
