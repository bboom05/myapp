import 'package:flutter/material.dart';
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
  int _selectedIndex = 0;
  List<Map<String, dynamic>> emptyData = [];
  List<Widget> _widgetOptions = [];

  bool isLogin = false;

  @override
  void initState() {
    super.initState();

    _widgetOptions = [
      IndexScreen(),
      const CameraScreen(),
      const ProfileMenu(),
      ProductDetailPage(
        productData: [],
        premiumData: [],
      ),
      QRScannerPage(),
    ];

    getUsers();
  }

  getUsers() async {
    await user.init();
    setState(() {
      isLogin = user.isLogin;
    });
    if (isLogin) {
      _widgetOptions = [
        IndexScreen(),
        CameraScreen(),
        ProfileMenu(),
        ProductDetailPage(
          productData: [],
          premiumData: [],
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
          Container(
            child: _widgetOptions.elementAt(_selectedIndex),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.grey.shade300, // สีของเส้นขอบด้านบน
              width: 0.7, // ความหนาของเส้นขอบ
            ),
          ),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          elevation: 0, // ปิดเงาของ BottomNavigationBar
          unselectedItemColor: Colors.black,
          selectedItemColor: Colors.orange,
          backgroundColor: Colors.white, // พื้นหลังสีขาว
          selectedFontSize: 10,
          unselectedFontSize: 10,
          onTap: _onItemTapped,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'หน้าแรก',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner),
              label: 'สแกน',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'ฉัน',
            ),
          ],
        ),
      ),
    );
  }

  void pushAfterLogin(BuildContext context) async {
    // Implement pushAfterLogin logic if needed
  }
}
