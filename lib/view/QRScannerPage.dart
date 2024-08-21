import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../model/user.dart';
import '../system/info.dart';
import 'ProductDetailPage.dart';
import 'HomeView.dart'; // Import the HomeView

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

          print('Scanned QR Code init: $qrText');

          if (Uri.tryParse(qrText)?.hasAbsolutePath ?? false) {
            Uri uri = Uri.parse(qrText);
            String qrId = uri.queryParameters['qr_id'] ?? '';

            if (qrId.isEmpty) {
              _showPopup(context, 'ไม่พบข้อมูลสินค้าสำหรับ QR Code นี้');
            } else {
              var productDetails = await getQr(qrText);

              print('Product Details init: $productDetails');

              if (productDetails != null) {
                var productData = productDetails['data']?.first ?? {};
                var promotionData = productDetails['promotion'] ?? {};
                print("ProductData $productData");
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
    print("jsonMap :${jsonMap}");
    var usernameKey = Info().userAPIProduct;
    var passwordKey = Info().passAPIProduct;
    final encodedCredentials =
        base64Encode(utf8.encode('$usernameKey:$passwordKey'));
    final response = await client.post(Uri.parse(Info().getProduct),
        headers: {
          'Authorization': 'Basic $encodedCredentials',
          'Content-Type': 'application/json',
        },
        body: jsonMap);
    print("response ${response}");
    var rs = json.decode(response.body);
    if (rs['status'] == 200) {
      print("rs : ${rs}");
      if (rs['status'] == 200 && rs['data'].isNotEmpty) {
        return rs;
      } else {
        return null;
      }
    } else {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getQr(String strQr) async {
    Uri uri = Uri.parse(strQr);
    String qrId = uri.queryParameters['qr_id'] ?? '';
    Map<String, String> map = {"qr_id": qrId, "branch_code": brance_code};
    print("brance_code: $brance_code");
    print("qr_id: $qrId");
    var body = json.encode(map);
    return await fetchProductDetail(http.Client(), body);
  }

  void _showPopup(BuildContext context, String message) {
    setState(() {
      isProcessing = false;
      showLoading = false;
    });
    showDialog(
      context: context,
      barrierDismissible: false, // Prevents dismissing by tapping outside
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
      appBar: AppBar(
        title: const Text('QR Code Scanner',
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFFF8C00),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              Expanded(
                flex: 5,
                child: MobileScanner(
                  key: qrKey,
                  controller: controller,
                  onDetect: (BarcodeCapture capture) async {
                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      if (!isProcessing) {
                        setState(() {
                          qrText = barcode.rawValue!;
                          isProcessing = true;
                          showLoading = true;
                        });
                        controller.stop();

                        print('Scanned QR Code: $qrText');

                        if (Uri.tryParse(qrText)?.hasAbsolutePath ?? false) {
                          Uri uri = Uri.parse(qrText);
                          String qrId = uri.queryParameters['qr_id'] ?? '';

                          if (qrId.isEmpty) {
                            _showPopup(context, 'ไม่พบข้อมูลสินค้าสำหรับ QR Code นี้');
                          } else {
                            var productDetails = await getQr(qrText);

                            print('Product Details: $productDetails');

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
                  },
                ),
              ),
            ],
          ),
          if (showLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
      backgroundColor: Colors.transparent,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
