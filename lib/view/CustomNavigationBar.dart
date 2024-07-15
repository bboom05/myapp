
import 'package:flutter/material.dart';
import 'package:myapp/view/CameraScreen.dart';
import 'package:myapp/view/ProfilePage.dart';


class CustomNavigationBar extends StatelessWidget {
  const CustomNavigationBar({super.key, required this.currentIndex});
  final int currentIndex;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        height: 80,
        padding: const EdgeInsets.all(4),
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.white,
            width: 1.0,
          ),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 3,
              blurRadius: 7,
              offset: const Offset(0, 3), // changes position of shadow
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
           Expanded(
              child: BottomTabBarItem(
                'Scan',
                image: 'assets/images/ic_home.png',
                onTap: () {
                  if (currentIndex == 0) {
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CameraScreen(
                      ),
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: BottomTabBarItem(
                'Profile',
                image: 'assets/images/ic_person.png',
                onTap: () {
                  if (currentIndex == 1) {
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfilePage(
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BottomTabBarItem extends StatelessWidget {
  const BottomTabBarItem(this.title, {super.key, required this.image, this.onTap});

  final String image;
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
       Image.asset(
            image,
            width: 30,
            height: 30,
            // color: Colors.blue,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.blue,
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

void pushReplacementNoAnimation(BuildContext context, {required Widget widget}) {
  Navigator.of(context).pushReplacement(PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => widget,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return child;
    },
  ));
}