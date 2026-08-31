import 'package:flutter/material.dart';

class SavedScansScreen extends StatelessWidget {
  final bool showAppBar;

  const SavedScansScreen({
    super.key,
    this.showAppBar = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar
          ? AppBar(
        title: const Text('Saved Scans'),
      )
          : null,
      body: const Center(
        child: Text(
          'Saved Scans Screen',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}