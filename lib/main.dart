import 'package:flutter/material.dart';

void main() {
  runApp(const TheCarrierApp());
}

class TheCarrierApp extends StatelessWidget {
  const TheCarrierApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'The Carrier',
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(
                Icons.delivery_dining,
                color: Colors.orange,
                size: 100,
              ),
              SizedBox(height: 20),
              Text(
                'THE CARRIER',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'From Bicycle To Cargo Plane',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
