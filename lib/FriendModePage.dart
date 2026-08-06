import 'package:flutter/material.dart';
import 'main.dart';

class FriendModePage extends StatelessWidget {
  const FriendModePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
     
      body: ProjectList(
        roleFilter: 'フレンド機能',
      ),
    );
  }
}