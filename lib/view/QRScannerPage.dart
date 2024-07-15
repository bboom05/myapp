import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:myapp/system/info.dart';
import 'package:myapp/view/ProductDetailPage.dart';
import 'package:myapp/view/HomeView.dart'; // import HomeView
import 'package:qr_code_scanner/qr_code_scanner.dart' as qr;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:qr_code_tools/qr_code_tools.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<StatefulWidget> createState() => _QRViewCreatedPageState();
}

class _QRViewCreatedPageState extends State<QRScannerPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  qr.QRViewController? controller;
  String qrText = '';
  bool isProcessing = false;
  final ImagePicker _picker = ImagePicker();

  Future<Map<String, dynamic>?> fetchProductDetail(http.Client client, String jsonMap) async {
    var usernameKey = Info().userAPI;
    var passwordKey = Info().passAPI;
    final encodedCredentials = base64Encode(utf8.encode('$usernameKey:$passwordKey'));
    final response = await client.post(Uri.parse(Info().getProduct), headers: {
      'Authorization': 'Basic $encodedCredentials',
      'Content-Type': 'application/json',
    }, body: jsonMap);

    print(jsonMap);
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      var rs = json.decode(response.body);
      print(rs);
      if (rs['status'] == 'success' && rs['data'].isNotEmpty) {
        return rs;
      } else {
        return null;
      }
    } else {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getQr(String strQr) async {
    Map<String, String> map = {"product_name": strQr, "warehouse": "MBKE2"};
    var body = json.encode(map);
    return await fetchProductDetail(http.Client(), body);
  }

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    } else if (Platform.isIOS) {
      controller?.resumeCamera();
    }
  }

  Future<void> _scanQRCodeFromImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        isProcessing = true;
      });

      try {
        String? scannedQrCode = await QrCodeToolsPlugin.decodeFrom(pickedFile.path);

        if (scannedQrCode != null && scannedQrCode.isNotEmpty) {
          qrText = scannedQrCode;
          var productDetails = await getQr(qrText);
          if (productDetails != null) {
            var productData = productDetails['data'][0];
            var promotionData = productDetails['promotion'];
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailPage(data: productData, promotion: promotionData),
              ),
            ).then((_) {
              setState(() {
                isProcessing = false;
              });
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('ไม่พบข้อมูลสินค้าสำหรับ QR Code นี้'),
              ),
            );
            setState(() {
              isProcessing = false;
            });
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ไม่สามารถอ่าน QR Code จากรูปภาพได้'),
            ),
          );
          setState(() {
            isProcessing = false;
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการอ่าน QR Code: $e'),
          ),
        );
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code Scanner', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFFF8C00),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              Expanded(
                flex: 5,
                child: qr.QRView(
                  key: qrKey,
                  onQRViewCreated: _onQRViewCreated,
                  overlay: qr.QrScannerOverlayShape(
                    borderColor: Colors.red,
                    borderRadius: 10,
                    borderLength: 30,
                    borderWidth: 10,
                    cutOutSize: 300,
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            right: 20,
            bottom: 60, // Adjust the bottom position as needed
            child: FloatingActionButton(
              backgroundColor:Colors.transparent,
              shape: RoundedRectangleBorder(side: BorderSide(width: 2,color: Colors.white),borderRadius: BorderRadius.circular(100)),
              onPressed: _scanQRCodeFromImage,
              child: const Icon(Icons.photo, color: Colors.white),
            ),
          ),
          if (isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      backgroundColor: Colors.transparent, // Set background color to transparent
    );
  }

  void _onQRViewCreated(qr.QRViewController controller) {
    this.controller = controller;

    controller.scannedDataStream.listen((scanData) async {
      if (!isProcessing) {
        setState(() {
          qrText = scanData.code!;
          isProcessing = true;
        });
        controller.pauseCamera();

        var productDetails = await getQr(qrText);

        if (productDetails != null) {
          var productData = productDetails['data'][0];
          var promotionData = productDetails['promotion'];
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailPage(data: productData, promotion: promotionData),
            ),
          ).then((_) {
            setState(() {
              isProcessing = false;
            });
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ไม่พบข้อมูลสินค้าสำหรับ QR Code นี้'),
            ),
          );
          setState(() {
            isProcessing = false;
          });
          controller.resumeCamera();
        }
      }
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
