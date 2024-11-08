import 'package:flutter/material.dart';
import 'package:myapp/model/user.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HeaderHome extends StatefulWidget {
  const HeaderHome({super.key});

  @override
  State<HeaderHome> createState() => _HeaderHomeState();
}

class _HeaderHomeState extends State<HeaderHome> {
  var user = User();
  bool isLogin = false;
  var fullname = "";
  var brance_code = "";
  var brance_name = "";
  List<Map<String, dynamic>> products = [];

  @override
  void initState() {
    super.initState();
    getUsers();
  }

  getUsers() async {
    await user.init();
    setState(() {
      isLogin = user.isLogin;
      fullname = user.fullname;
      brance_code = user.brance_code;
      brance_name = user.brance_name;
    });

    // ดึงข้อมูลสินค้าหลังจากผู้ใช้ล็อกอินแล้ว
    await fetchProductData();
  }

  Future<void> fetchProductData() async {
    // ทำการเรียก API เพื่อนำข้อมูลสินค้ามาใหม่หลังจากเลือกสาขา
    String url = 'https://your-api-url.com/get-products'; // เปลี่ยน URL ตามจริง
    Map<String, dynamic> data = {'branch_code': brance_code};

    try {
      final response = await http.post(Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(data));

      if (response.statusCode == 200) {
        setState(() {
          products =
              List<Map<String, dynamic>>.from(json.decode(response.body));
        });
      } else {
        print('Failed to load products');
      }
    } catch (e) {
      print('Error fetching product data: $e');
    }
  }

  void _selectBranch(BuildContext context) {
    print('Select Branch');
    print(user.branch_codes_area);
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 5,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 200),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: user.branch_codes_area.length,
                  itemBuilder: (context, index) {
                    // เข้าถึง branch_code และ branch_name ใน Map
                    var branch = user.branch_codes_area[index];
                    String branchCode = branch['branch_code'] ?? '';
                    String branchName = branch['branch_name'] ?? '';

                    // ตรวจสอบว่าถูกเลือกหรือไม่
                    bool isSelected = brance_code == branchCode;

                    return ListTile(
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                      title: Text(
                        'sdfsdfsdfsdf',
                        // '$branchName ($branchCode)', // แสดง branch_name และ branch_code
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Prompt',
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.black : Colors.grey[600],
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle, color: Colors.orangeAccent)
                          : null,
                      onTap: () async {
                        setState(() {
                          // อัปเดตค่า brance_code และ brance_name ที่เลือก
                          brance_code = branchCode;
                          brance_name = branchName;
                        });

                        // ดึงข้อมูลสินค้ามาใหม่หลังจากเลือกสาขา
                        await fetchProductData();
                        Navigator.pop(context); // ปิด BottomSheet
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFA726), Color(0xFFFF8C00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      width: double.infinity,
      height: 200,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 80),
                Text(
                  'Hi! $fullname',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Kanit'),
                ),
                SizedBox(height: 3),
                GestureDetector(
                  onTap: () =>
                      _selectBranch(context), // กดแล้วเปิด Popup เลือกสาขา
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$brance_name ($brance_code)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontFamily: 'Kanit'),
                        ),
                      ),
                      Icon(Icons.arrow_drop_down,
                          color: Colors.white, size: 30),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
