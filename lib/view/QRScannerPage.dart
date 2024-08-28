import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../model/user.dart';
import '../system/info.dart';
import 'ProductDetailPage.dart';
import 'HomeView.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<StatefulWidget> createState() => _QRViewCreatedPageState();
}

class _QRViewCreatedPageState extends State<QRScannerPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  MobileScannerController controller = MobileScannerController();
  String qrText = '';
  bool isProcessing = false;
  bool showLoading = false;

  var user = User();
  bool isLogin = false;
  var fullname = "";
  var brance_code = "";
  var brance_name = "";

  @override
  void initState() {
    super.initState();
    getUsers();
    controller.barcodes.listen((capture) async {
      final List<Barcode> barcodes = capture.barcodes;
      for (final barcode in barcodes) {
        if (!isProcessing) {
          setState(() {
            qrText = barcode.rawValue!;
            isProcessing = true;
            showLoading = true;
          });
          controller.stop();

          if (Uri.tryParse(qrText)?.hasAbsolutePath ?? false) {
            Uri uri = Uri.parse(qrText);
            String qrId = uri.queryParameters['qr_id'] ?? '';

            if (qrId.isEmpty) {
              _showPopup(context, 'ไม่พบข้อมูลสินค้าสำหรับ QR Code นี้');
            } else {
              var productDetails = await getQr(qrText);

              if (productDetails != null) {
                var productData = productDetails['data']?.first ?? {};
                var promotionData = productDetails['promotion'] ?? {};
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetailPage(
                        data: Map<String, dynamic>.from(productData),
                        promotion: Map<String, dynamic>.from(promotionData)),
                  ),
                ).then((_) {
                  setState(() {
                    isProcessing = false;
                    showLoading = false;
                  });
                });
              } else {
                _showPopup(context, 'ไม่พบข้อมูลสินค้าสำหรับ QR Code นี้');
              }
            }
          } else {
            _showPopup(context, 'QR Code ไม่ถูกต้อง');
          }
        }
      }
    });
  }

  Future<void> getUsers() async {
    await user.init();
    setState(() {
      isLogin = user.isLogin;
      fullname = user.fullname;
      brance_code = user.brance_code;
      brance_name = user.brance_name;
    });
  }

  Future<Map<String, dynamic>?> fetchProductDetail(
      http.Client client, String jsonMap) async {
    var usernameKey = Info().userAPIProd;
    var passwordKey = Info().passAPIProd;
    final encodedCredentials =
        base64Encode(utf8.encode('$usernameKey:$passwordKey'));
    final response = await client.post(Uri.parse(Info().getProduct),
        headers: {
          'Authorization': 'Basic $encodedCredentials',
          'Content-Type': 'application/json',
        },
        body: jsonMap);
    var rs = json.decode(response.body);
    print("RS : ${rs}");
    if (rs['status'] == 200 && rs['data'].isNotEmpty) {
      return rs;
    }
    return null;
  }

  Future<Map<String, dynamic>?> getQr(String strQr) async {
    Uri uri = Uri.parse(strQr);
    String qrId = uri.queryParameters['qr_id'] ?? '';
    Map<String, String> map = {"qr_id": qrId, "branch_code": brance_code};
    var body = json.encode(map);
    print("BODY MAP : ${body}");
    return await fetchProductDetail(http.Client(), body);
  }

  void _showPopup(BuildContext context, String message) {
    setState(() {
      isProcessing = false;
      showLoading = false;
    });
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('ตกลง'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => HomeView()),
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller.stop();
    } else if (Platform.isIOS) {
      controller.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('QR Code Scanner', style: TextStyle(color: Colors.white)),
      //   // backgroundColor: const Color(0xFFFF8C00),
      //   backgroundColor: Colors.transparent,
      //   shadowColor: Colors.transparent,
      //   elevation: 0,
      //   iconTheme: const IconThemeData(color: Colors.white),
      // ),
      appBar: AppBar(
        title: const Text('QR Code Scanner',
            style: TextStyle(color: Colors.white)),
        backgroundColor:
            Colors.transparent, // ตั้งค่าพื้นหลัง AppBar ให้โปร่งใส
        elevation: 0, // ลบเงาใต้ AppBar
        iconTheme: const IconThemeData(
            color: Colors.white), // ตั้งค่าสีของไอคอนใน AppBar เป็นสีขาว
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFFFA726), // สีส้มอ่อน
                Color(0xFFFF5722), // สีส้มเข้ม
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Stack(
        children: <Widget>[
          MobileScanner(
            key: qrKey,
            controller: controller,
          ),
          // Focus overlay with rounded corners
          Positioned.fill(
            child: CustomPaint(
              painter: QRScannerOverlayPainter(),
              child: Container(),
            ),
          ),
          if (showLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
          // Centered text instruction
          const Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Center(
                // child: Text(
                //   "Align QR code within the frame",
                //   style: TextStyle(
                //     fontSize: 16,
                //     color: Colors.white,
                //     fontWeight: FontWeight.bold,
                //   ),
                // ),
                ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

class QRScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final width = size.width * 0.75;
    final height = size.height * 0.4;

    final left = (size.width - width) / 2;
    final top = (size.height - height) / 2;
    final right = left + width;
    final bottom = top + height;

    final cornerLength = 40.0;
    final radius = Radius.circular(10);

    // Draw top-left corner
    canvas.drawLine(Offset(left, top), Offset(left + cornerLength, top), paint);
    canvas.drawLine(Offset(left, top), Offset(left, top + cornerLength), paint);

    // Draw top-right corner
    canvas.drawLine(
        Offset(right, top), Offset(right - cornerLength, top), paint);
    canvas.drawLine(
        Offset(right, top), Offset(right, top + cornerLength), paint);

    // Draw bottom-left corner
    canvas.drawLine(
        Offset(left, bottom), Offset(left + cornerLength, bottom), paint);
    canvas.drawLine(
        Offset(left, bottom), Offset(left, bottom - cornerLength), paint);

    // Draw bottom-right corner
    canvas.drawLine(
        Offset(right, bottom), Offset(right - cornerLength, bottom), paint);
    canvas.drawLine(
        Offset(right, bottom), Offset(right, bottom - cornerLength), paint);

    // Draw blur effect for areas outside the scanning frame
    // final overlayPaint = Paint()..color = Colors.black.withOpacity(0.5);
    // canvas.drawRect(Rect.fromLTRB(0, 0, size.width, top), overlayPaint);
    // canvas.drawRect(Rect.fromLTRB(0, bottom, size.width, size.height), overlayPaint);
    // canvas.drawRect(Rect.fromLTRB(0, top, left, bottom), overlayPaint);
    // canvas.drawRect(Rect.fromLTRB(right, top, size.width, bottom), overlayPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
