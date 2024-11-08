import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

import 'ProductIncoming.dart';

// List of menu items with their respective icons, colors, and screens
final List<Map<String, dynamic>> menuItems = [
  {
    "label": "Product Incoming",
    "icon": Icons.inventory,
    "color": Colors.deepOrange,
    "screen": ProductIncoming()
  },
];

class MenuHome extends StatefulWidget {
  @override
  _MenuHomeState createState() => _MenuHomeState();
}

class _MenuHomeState extends State<MenuHome> {
  @override
  Widget build(BuildContext context) {
    return CarouselSlider(
      options: CarouselOptions(
        height: 200,
        viewportFraction: 1.0,
        enableInfiniteScroll: false,
      ),
      items: [
        buildMenuPage(context, menuItems.sublist(0, 5)), // First page (5 items)
        buildMenuPage(
            context, menuItems.sublist(5, 10)), // Second page (5 items)
      ],
    );
  }

  Widget buildMenuPage(BuildContext context, List<Map<String, dynamic>> items) {
    return GridView.count(
      crossAxisCount: 5,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(16),
      children: items.map((item) {
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => item['screen']),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item['icon'], color: item['color'], size: 40),
              SizedBox(height: 5),
              Text(
                item['label'],
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, fontFamily: 'Kanit'),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// Placeholder Screens for each menu item
class ProductIncomingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Product Incoming')),
      body: Center(child: Text('Product Incoming Screen')),
    );
  }
}

class MerchandiseScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Merchandise')),
      body: Center(child: Text('Merchandise Screen')),
    );
  }
}

// Repeat similar screen classes for each menu item
class ClothesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Clothes')),
      body: Center(child: Text('Clothes Screen')),
    );
  }
}

class MomBabyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Mom & Baby')),
      body: Center(child: Text('Mom & Baby Screen')),
    );
  }
}

class OverseasScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Overseas')),
      body: Center(child: Text('Overseas Screen')),
    );
  }
}

// Continue defining screens for Beauty, Fresh Fruits, Snack, Food, Health Care, etc.
