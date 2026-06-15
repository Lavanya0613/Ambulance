// Entry point stub for Ambulance Flutter app.
// UI screens are not generated yet — this file wires the app shell and providers.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(ProviderScope(child: PlaceholderApp()));
}

class PlaceholderApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: Replace with real App widget and routing once screens are implemented.
    return MaterialApp(
      title: 'Ambulance App',
      home: Scaffold(
        body: Center(child: Text('App scaffold — UI not implemented yet')),
      ),
    );
  }
}
