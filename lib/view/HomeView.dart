import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/widgets.dart';
import 'package:iconly/iconly.dart';
import 'package:myapp/model/user.dart';
import 'package:myapp/view/CameraScreen.dart';
import 'package:myapp/view/IndexScreen.dart';
import 'package:myapp/view/ProductDetailPage.dart';
import 'package:myapp/view/ProfileMenu.dart';
import 'package:myapp/view/QRScannerPage.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  var user = User();
  int _selectedIndex = 1;
  List<Map<String, dynamic>> emptyData = [];
  List<Widget> _widgetOptions = [];

  bool isLogin = false;

  @override
  void initState() {
    super.initState();

    _widgetOptions = [
      const CameraScreen(),
      IndexScreen(),
      const ProfileMenu(),
      ProductDetailPage(
        productData: [],
        premiumData: [],
        selectedType: '',
      ),
      QRScannerPage(),
    ];

    getUsers();
  }

  Future<void> getUsers() async {
    await user.init();
    setState(() {
      isLogin = user.isLogin;
    });
    if (isLogin) {
      _widgetOptions = [
        CameraScreen(),
        IndexScreen(),
        ProfileMenu(),
        ProductDetailPage(
          productData: [],
          premiumData: [],
          selectedType: '',
        ),
        QRScannerPage(),
      ];
    } else {
      _widgetOptions = [
        CameraScreen(),
        ProfileMenu(),
      ];
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _widgetOptions.elementAt(_selectedIndex), // แสดง widget ตามที่เลือก
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          // border: Border(
          //   top: BorderSide(
          //     color: Colors.grey.shade300, // สีของเส้นขอบด้านบน
          //     width: 1.0, // ความหนาของเส้นขอบ
          //   ),
          // ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1), // สีของเงา
              blurRadius: 10, // ความนุ่มของเงา
              offset: Offset(0, -5), // ตำแหน่งเงา (ย้ายขึ้นด้านบน)
            ),
          ],
        ),
        child: CurvedNavigationBar(
          color: Colors.white, // พื้นหลังโปร่งใสเล็กน้อย
          backgroundColor: Colors.transparent, // พื้นหลังโดยรวมที่นุ่มนวลขึ้น
          buttonBackgroundColor:
              Colors.orangeAccent, // ปุ่มวงกลมโปร่งใสเล็กน้อย
          height: 70, // ความสูงพอดี
          index: _selectedIndex,
          animationDuration: Duration(milliseconds: 400),
          animationCurve: Curves.easeInOutCubic, // การเคลื่อนไหวที่นุ่มนวล
          // items: <Widget>[
          //   Icon(Icons.home, size: 30, color: _selectedIndex == 0 ? Colors.white : Colors.grey.shade600),
          //   Icon(Icons.qr_code_scanner, size: 30, color: _selectedIndex == 1 ? Colors.white : Colors.grey.shade600),
          //   Icon(Icons.person, size: 30, color: _selectedIndex == 2 ? Colors.white : Colors.grey.shade600),
          // ],
          items: <Widget>[
            Icon(IconlyBold.scan,
                size: 30,
                color: _selectedIndex == 0
                    ? Colors.white
                    : Colors.grey.shade600), // scan สำหรับสแกน QR

            Icon(IconlyLight.home,
                size: 30,
                color:
                    _selectedIndex == 1 ? Colors.white : Colors.grey.shade600),
            Icon(IconlyLight.profile,
                size: 30,
                color:
                    _selectedIndex == 2 ? Colors.white : Colors.grey.shade600),
          ],
          onTap: (index) {
            _onItemTapped(index); // อัพเดตเมื่อเลือก
          },
          letIndexChange: (index) => true, // ควบคุมการเปลี่ยนแปลง
        ),
      ),
    );
  }

  void pushAfterLogin(BuildContext context) async {
    // Implement pushAfterLogin logic if needed
  }
}

// VIVO SHOP พระราม 9

