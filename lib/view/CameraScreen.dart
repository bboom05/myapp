import 'package:flutter/material.dart';
import 'package:myapp/view/QRScannerPage.dart';
// นำเข้า NavigationBar

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('',
            style: TextStyle(
              color: Colors.white,
            )),
        backgroundColor: const Color(0xFFFF8C00),
        iconTheme: const IconThemeData(
          color: Colors.white, // ตั้งค่าสีของไอคอนย้อนกลับ
        ),
      ),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.camera_alt), // เพิ่มไอคอนกล้อง
          label: const Text('สแกน'), // ตั้งค่าข้อความของปุ่ม
          onPressed: () => {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      // DisplayContentScreen(content: barcodeScanRes),
                      QRScannerPage()),
            )
          },
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: const Color(0xFFFF8C00),
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            minimumSize: const Size(200, 60),
          ),
        ),
      ),
    );
  }
}
