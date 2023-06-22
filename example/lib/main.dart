import 'package:flutter/material.dart';
import 'package:widget_spinning_wheel/widget_spinning_wheel.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Spinning Wheel Example'),
        ),
        body: Center(
          child: WidgetSpinningWheel(
            labels: ['Option 1', 'Option 2', 'Option 3'],
            onSpinComplete: (String label) {
              print(label);
            },
            size: 400,
          ),
        ),
      ),
    );
  }
}
