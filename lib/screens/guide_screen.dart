import 'package:flutter/material.dart';

class GuideScreen extends StatelessWidget {
  final bool showAppBar;

  const GuideScreen({
    super.key,
    this.showAppBar = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar
          ? AppBar(
        title: const Text('Guide'),
      )
          : null,
      body: const Center(
        child: Text(
          'Guide Screen',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}