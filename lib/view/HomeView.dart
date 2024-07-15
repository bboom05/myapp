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
      ProductDetailPage(data: {},promotion: {},),
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
        ProductDetailPage(data: {},promotion: {},),
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
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        elevation: 2,
        unselectedItemColor: Colors.black,
        selectedItemColor: Colors.orange,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'หน้าแรก',
            backgroundColor: Colors.blue,
          ), BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: 'สแกน',
            backgroundColor: Colors.blue,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'ฉัน',
            backgroundColor: Colors.blue,
          ),
        ],
      ),
    );
  }

  void pushAfterLogin(BuildContext context) async {
    // Implement pushAfterLogin logic if needed
  }
}
