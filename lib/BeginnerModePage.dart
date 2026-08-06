import 'package:flutter/material.dart';
import 'main.dart';

class BeginnerModePage extends StatelessWidget {
  const BeginnerModePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
     
      body: ProjectList(
        roleFilter: '初心者モード',
      ),
    );
  }
}