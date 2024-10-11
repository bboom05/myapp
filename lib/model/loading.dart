import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class LoadingCustom extends StatefulWidget {
  const LoadingCustom({Key? key}) : super(key: key);

  @override
  _LoadingCustomState createState() => _LoadingCustomState();
}

class _LoadingCustomState extends State<LoadingCustom> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // พื้นหลังสีขาว
      body: Center(
        child: DotLoadingIndicator(), // ใช้ DotLoadingIndicator
      ),
    );
  }
}

class DotLoadingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SpinKitThreeBounce(
        color: Colors.orange, // สีของ dot เป็นสีส้ม
        size: 50.0, // ขนาดของ dot
      ),
    );
  }
}
