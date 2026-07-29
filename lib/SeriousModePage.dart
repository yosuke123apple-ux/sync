import 'package:flutter/material.dart';
import 'main.dart';

class SeriousModePage extends StatelessWidget {
  const SeriousModePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xff020710),
      body: ProjectList(
        roleFilter: '本気モード',
      ),
    );
  }
}