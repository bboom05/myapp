import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:myapp/model/loading.dart';
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
  var branch_code = "";
  var branch_name = "";
  var select_branch_code = "";
  var select_branch_name = "";

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
              print("QR ID is empty");
              _showPopup(context, 'ไม่พบข้อมูลสินค้าสำหรับ QR Code นี้');
            } else {
              var productDetails = await getQr(qrText);

              if (productDetails != null) {
                // เมื่อได้รับข้อมูลแล้ว แสดงรายการให้เลือก
                _navigateToPromotionSelectionPage(
                    productDetails['products'], productDetails['premium']);
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
      branch_code = user.brance_code;
      branch_name = user.brance_name;
      select_branch_code = user.select_branch_code;
      select_branch_name = user.select_branch_name;
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
    print('rs: $rs');
    // if (rs['status'] == 200 && rs['data'].isNotEmpty) {
    //   return rs['data'];
    // }
    // return null;

    if (rs['status'] == 200 && rs['data'] != null) {
      final data = rs['data'];
      if (data['products'] != null && data['products'].isNotEmpty) {
        return data;
      }
    }
    return null;
  }

  Future<Map<String, dynamic>?> getQr(String strQr) async {
    Uri uri = Uri.parse(strQr);
    String qrId = uri.queryParameters['qr_id'] ?? '';
    print('qrId: $qrId');
    print('select_branch_code: $select_branch_code');

    Map<String, String> map = {
      "qr_id": qrId,
      "branch_code": select_branch_code,
      "type": "app"
    };
    var body = json.encode(map);

    final response = await fetchProductDetail(http.Client(), body);
    return response ?? {}; // คืนค่าว่างถ้า response เป็น null
  }


  void _navigateToPromotionSelectionPage(
      List<dynamic>? products, List<dynamic>? premiumData) {
    if (products == null || products.isEmpty) {
      _showPopup(context, 'ไม่มีสินค้าในระบบ');
      return;
    }

    var product = products[0]; // ใช้สินค้าตัวแรก
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PromotionSelectionPage(
            product: product, premium: premiumData ?? []),
      ),
    );
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code Scanner',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFFFA726),
                Color(0xFFFF5722),
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
          Positioned.fill(
            child: CustomPaint(
              painter: QRScannerOverlayPainter(),
              child: Container(),
            ),
          ),
          if (showLoading)
            Center(
              // child: CircularProgressIndicator(),
              child: DotLoadingIndicator(),
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

class PromotionSelectionPage extends StatelessWidget {
  final Map<String, dynamic> product;
  final List<dynamic> premium;

  const PromotionSelectionPage(
      {required this.product, required this.premium, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var branchDetails = product['branch_details'];
    List<Map<String, dynamic>> availablePromotions = [];

    if (branchDetails != null) {
      if (branchDetails['promotions_flash_sale'] != null &&
          branchDetails['promotions_flash_sale'].isNotEmpty) {
        availablePromotions.add({
          'type': 'flash_sale',
          'text': 'Best Price',
          'icon': Icons.flash_on,
          'color': Colors.red,
        });
      }

      if (branchDetails['promotions_flash_sale_second'] != null &&
          branchDetails['promotions_flash_sale_second'].isNotEmpty) {
        availablePromotions.add({
          'type': 'flash_sale_secondary',
          'text': 'Best Price รอง',
          'icon': Icons.flash_auto,
          'color': Colors.orange,
        });
      }

      if (branchDetails['promotions_main'] != null &&
          branchDetails['promotions_main'].isNotEmpty) {
        availablePromotions.add({
          'type': 'general',
          'text': 'ทั่วไป หลัก',
          'icon': Icons.store,
          'color': Colors.green,
        });
      }

      if (branchDetails['promotions_second'] != null &&
          branchDetails['promotions_second'].isNotEmpty) {
        availablePromotions.add({
          'type': 'general_secondary',
          'text': 'ทั่วไป รอง',
          'icon': Icons.storefront,
          'color': Colors.blue,
        });
      }
    }

    // ตรวจสอบถ้ามีโปรโมชั่นเดียว ให้นำทางไปยังหน้าถัดไปทันที
    print('availablePromotions: $availablePromotions');
    // ถ้าไม่มีโปรโมชั่นใดๆ เลย ให้นำทางไปที่หน้า general
    if (availablePromotions.isEmpty) {
      Future.delayed(Duration.zero, () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(
              productData: [product],
              premiumData: List<Map<String, dynamic>>.from(premium),
              selectedType: 'general', // นำทางไปหน้า general
            ),
          ),
        );
      });
      return const SizedBox.shrink();
    } else if (availablePromotions.length == 1) {
      Future.delayed(Duration.zero, () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(
              productData: [product],
              premiumData: List<Map<String, dynamic>>.from(premium),
              selectedType: availablePromotions[0]['type'],
            ),
          ),
        );
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(
          color: Colors.white, // เปลี่ยนสีไอคอน
        ),
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
        elevation: 0,
        title: const Text(
          'เลือกโปรโมชั่น',
          style: TextStyle(
            fontFamily: 'Kanit',
            color: Colors.white,
            fontWeight: FontWeight.w300, // ใช้ตัวอักษรแบบบาง
          ),
        ),
        backgroundColor: Colors.white,
      ),
      body: availablePromotions.isEmpty
          ? Center(child: Text('ไม่มีโปรโมชั่นที่สามารถเลือกได้'))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16.0,
                  crossAxisSpacing: 16.0,
                ),
                itemCount: availablePromotions.length,
                itemBuilder: (context, index) {
                  var promotion = availablePromotions[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetailPage(
                            productData: [product],
                            premiumData:
                                List<Map<String, dynamic>>.from(premium),
                            selectedType: promotion['type'],
                          ),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            promotion['icon'],
                            color: promotion['color'],
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            promotion['text'],
                            style: const TextStyle(
                              fontFamily:'Kanit',
                              fontSize: 16,
                              // fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
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
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
