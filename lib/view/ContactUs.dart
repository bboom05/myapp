import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:myapp/system/info.dart';
import 'package:myapp/model/user.dart';
import 'package:myapp/model/loading.dart';

class Contactus extends StatefulWidget {
  const Contactus({Key? key}) : super(key: key);

  @override
  State<Contactus> createState() => _ContactusState();
}

class _ContactusState extends State<Contactus> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _detailsController = TextEditingController();
  String? _selectedType;
  bool _isLoading = false;
  String? employeeCode;

  final List<Map<String, dynamic>> _typeOptions = [
    {'type': 'ข้อเสนอแนะ', 'icon': Icons.thumb_up, 'color': Color(0xFF4CAF50)},
    {
      'type': 'ปัญหาการใช้งาน',
      'icon': Icons.bug_report,
      'color': Color(0xFFF44336)
    },
    {
      'type': 'สอบถามข้อมูล',
      'icon': Icons.info_outline,
      'color': Color(0xFF2196F3)
    },
    {
      'type': 'อื่นๆ',
      'icon': Icons.chat_bubble_outline,
      'color': Color(0xFF9C27B0)
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    var user = User();
    await user.init();
    setState(() {
      employeeCode = user.employee_code;
    });
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> sendContactData() async {
    if (employeeCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่พบข้อมูล employee_code')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // แสดงการโหลด DotLoadingIndicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child:
                DotLoadingIndicator(), // ใช้ DotLoadingIndicator แทน CircularProgressIndicator
          ),
        );
      },
    );

    var usernameKey = Info().userAPIProd;
    var passwordKey = Info().passAPIProd;
    final encodedCredentials =
        base64Encode(utf8.encode('$usernameKey:$passwordKey'));
    final uri = Uri.parse(Info().contactus);

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Basic $encodedCredentials',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'tage': _selectedType,
        'details': _detailsController.text,
        'emcode': employeeCode,
      }),
    );

    // ปิดการโหลดหลังจากส่งข้อมูลเสร็จ
    Navigator.of(context).pop();

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 201) {
      _showSuccessDialog();
      _detailsController.clear();
      setState(() {
        _selectedType = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('การส่งข้อมูลล้มเหลว')),
      );
    }
  }

  // Future<void> sendContactData() async {
  //   if (employeeCode == null) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('ไม่พบข้อมูล employee_code')),
  //     );
  //     return;
  //   }

  //   setState(() {
  //     _isLoading = true;
  //   });

  //   var usernameKey = Info().userAPIProd;
  //   var passwordKey = Info().passAPIProd;
  //   final encodedCredentials =
  //       base64Encode(utf8.encode('$usernameKey:$passwordKey'));
  //   final uri = Uri.parse(Info().contactus);

  //   final response = await http.post(
  //     uri,
  //     headers: {
  //       'Authorization': 'Basic $encodedCredentials',
  //       'Content-Type': 'application/json',
  //     },
  //     body: jsonEncode({
  //       'tage': _selectedType,
  //       'details': _detailsController.text,
  //       'emcode': employeeCode,
  //     }),
  //   );

  //   setState(() {
  //     _isLoading = false;
  //   });

  //   if (response.statusCode == 201) {
  //     _showSuccessDialog();
  //     _detailsController.clear();
  //     setState(() {
  //       _selectedType = null;
  //     });
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('การส่งข้อมูลล้มเหลว')),
  //     );
  //   }
  // }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFF4CAF50),
                  size: 60,
                ),
                const SizedBox(height: 20),
                const Text(
                  'ส่งข้อมูลสำเร็จ!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    fontFamily: 'Kanit',
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'ข้อมูลถูกส่งเรียบร้อยแล้ว',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontFamily: 'Kanit',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _detailsController.clear();
                      _selectedType = null;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 12),
                    backgroundColor: const Color(0xFFFFA726),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'ตกลง',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Kanit',
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่สามารถเปิด $url ได้')),
      );
    }
  }

  void _confirmSend() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'ยืนยันการส่งข้อมูล',
            style: TextStyle(fontFamily: 'Kanit'),
          ),
          content: const Text(
            'คุณต้องการส่งข้อมูลนี้หรือไม่?',
            style: TextStyle(fontFamily: 'Kanit'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'ยกเลิก',
                style: TextStyle(color: Colors.red, fontFamily: 'Kanit'),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                sendContactData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text(
                'ยืนยัน',
                style: TextStyle(fontFamily: 'Kanit', color: Colors.white),
              ),
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
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFA726), Color(0xFFFF5722)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'ติดต่อเรา',
          style: TextStyle(
            fontFamily: 'Kanit',
            color: Colors.white,
            fontWeight: FontWeight.w300,
          ),
        ),
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? Center(child: DotLoadingIndicator())
            : Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ประเภท',
                      style: TextStyle(
                        fontFamily: 'Kanit',
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      children: _typeOptions.map((option) {
                        return ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                option['icon'],
                                color: _selectedType == option['type']
                                    ? Colors.orange
                                    : option['color'],
                                size: 18,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                option['type'],
                                style: TextStyle(
                                  fontFamily: 'Kanit',
                                  color: _selectedType == option['type']
                                      ? Colors.orange
                                      : Colors.black,
                                ),
                              ),
                            ],
                          ),
                          selected: _selectedType == option['type'],
                          onSelected: (isSelected) {
                            setState(() {
                              _selectedType =
                                  isSelected ? option['type'] : null;
                            });
                          },
                          selectedColor: Colors.white,
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: _selectedType == option['type']
                                  ? Colors.orange
                                  : Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'รายละเอียด',
                      style: TextStyle(
                        fontFamily: 'Kanit',
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _detailsController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'กรุณาระบุรายละเอียด',
                        hintStyle: const TextStyle(fontFamily: 'Kanit'),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25.0),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25.0),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25.0),
                          borderSide: const BorderSide(color: Colors.orange),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'กรุณากรอกรายละเอียด';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                if (_formKey.currentState!.validate()) {
                                  _confirmSend();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25.0),
                          ),
                          backgroundColor: Colors.orange,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              )
                            : const Text(
                                'ตกลง',
                                style: TextStyle(
                                  fontFamily: 'Kanit',
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
