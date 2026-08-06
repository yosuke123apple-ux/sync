import 'package:flutter/material.dart';
import 'main.dart';

class StudyModePage extends StatelessWidget {
  const StudyModePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xff020710),
      body: ProjectList(
        roleFilter: '勉強モード',
      ),
    );
  }
}