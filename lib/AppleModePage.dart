import 'package:flutter/material.dart';
import 'main.dart';

class AppleModePage extends StatelessWidget {
  const AppleModePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
    
    body:  ProjectList(
  showOnlyJoined: true,
),
    );
  }
}