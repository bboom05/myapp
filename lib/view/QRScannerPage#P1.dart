import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../model/user.dart';
import '../system/info.dart';
import 'ProductDetailPage.dart';

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
  final ImagePicker _picker = ImagePicker();

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
          });
          controller.stop();

          print('Scanned QR Code: $qrText');

          var productDetails = await getQr(qrText);

          print('Product Details: $productDetails');

          if (productDetails != null) {
            var productData = productDetails['data'][0];
            var promotionData = productDetails['promotion'];
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailPage(
                    data: productData, promotion: promotionData),
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
            controller.start();
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
    var usernameKey = Info().userAPI;
    var passwordKey = Info().passAPI;
    final encodedCredentials =
        base64Encode(utf8.encode('$usernameKey:$passwordKey'));
    final response = await client.post(Uri.parse(Info().getProduct),
        headers: {
          'Authorization': 'Basic $encodedCredentials',
          'Content-Type': 'application/json',
        },
        body: jsonMap);

    if (response.statusCode == 200) {
      var rs = json.decode(response.body);
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
    Map<String, String> map = {
      "product_name": strQr,
      "warehouse": brance_code
    };
    print("brance_code: $brance_code");
    print("product_name: $strQr");
    var body = json.encode(map);
    return await fetchProductDetail(http.Client(), body);
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

  // Future<void> _scanQRCodeFromImage() async {
  //   final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
  //   print("pickedFile: $pickedFile");
  //   if (pickedFile != null) {
  //     setState(() {
  //       isProcessing = true;
  //     });

  //     try {
  //       final bool scanned = await controller.analyzeImage(pickedFile.path);

  //       if (scanned) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(
  //             content: Text('QR Code ถูกวิเคราะห์จากภาพสำเร็จ'),
  //           ),
  //         );
  //         print('Scanned QR Code from image.');

  //         // Wait for the next barcode capture event to get the scanned data
  //         controller.barcodes.listen((capture) async {
  //           final List<Barcode> barcodes = capture.barcodes;
  //           for (final barcode in barcodes) {
  //             if (!isProcessing) {
  //               setState(() {
  //                 qrText = barcode.rawValue!;
  //                 isProcessing = true;
  //               });
  //               controller.stop();

  //               print('Scanned QR Code: $qrText');

  //               var productDetails = await getQr(qrText);

  //               print('Product Details: $productDetails');

  //               if (productDetails != null) {
  //                 var productData = productDetails['data'][0];
  //                 var promotionData = productDetails['promotion'];
  //                 Navigator.pushReplacement(
  //                   context,
  //                   MaterialPageRoute(
  //                     builder: (context) => ProductDetailPage(
  //                         data: productData, promotion: promotionData),
  //                   ),
  //                 ).then((_) {
  //                   setState(() {
  //                     isProcessing = false;
  //                   });
  //                 });
  //               } else {
  //                 ScaffoldMessenger.of(context).showSnackBar(
  //                   const SnackBar(
  //                     content: Text('ไม่พบข้อมูลสินค้าสำหรับ QR Code นี้'),
  //                   ),
  //                 );
  //                 setState(() {
  //                   isProcessing = false;
  //                 });
  //                 controller.start();
  //               }
  //             }
  //           }
  //         });
  //       } else {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(
  //             content: Text('ไม่สามารถวิเคราะห์ QR Code จากรูปภาพได้'),
  //           ),
  //         );
  //         setState(() {
  //           isProcessing = false;
  //         });
  //       }
  //     } catch (e) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('เกิดข้อผิดพลาดในการอ่าน QR Code: $e'),
  //         ),
  //       );
  //       setState(() {
  //         isProcessing = false;
  //       });
  //     }
  //   }
  // }

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
                        });
                        controller.stop();

                        print('Scanned QR Code: $qrText');

                        var productDetails = await getQr(qrText);

                        print('Product Details: $productDetails');

                        if (productDetails != null) {
                          var productData = productDetails['data'][0];
                          var promotionData = productDetails['promotion'];
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetailPage(
                                  data: productData, promotion: promotionData),
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
                          controller.start();
                        }
                      }
                    }
                  },
                ),
              ),
            ],
          ),
          // Positioned(
          //   right: 20,
          //   bottom: 60, // Adjust the bottom position as needed
          //   child: FloatingActionButton(
          //     backgroundColor: Colors.transparent,
          //     shape: RoundedRectangleBorder(
          //         side: BorderSide(width: 2, color: Colors.white),
          //         borderRadius: BorderRadius.circular(100)),
          //     onPressed: _scanQRCodeFromImage,
          //     child: const Icon(Icons.photo, color: Colors.white),
          //   ),
          // ),
          // if (isProcessing)
          //   Container(
          //     color: Colors.black54,
          //     child: const Center(
          //       child: CircularProgressIndicator(
          //         valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          //       ),
          //     ),
          //   ),
        ],
      ),
      backgroundColor:
          Colors.transparent, // Set background color to transparent
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
