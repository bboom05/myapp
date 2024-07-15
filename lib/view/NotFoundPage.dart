import 'package:flutter/material.dart';

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Page Not Found'),
        backgroundColor: Colors.red, // Red to indicate an error.
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.error_outline, size: 80, color: Colors.red),
            SizedBox(height: 20),
            Text(
              '404',
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.red),
            ),
            SizedBox(height: 10),
            Text(
              'The page you are looking for does not exist.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            // ElevatedButton(
            //   onPressed: () => Navigator.of(context).pop(),
            //   child: Text('Go Back'),
            // ),
          ],
        ),
      ),
    );
  }
}
