import 'package:flutter/material.dart';
import 'package:localsend_rs/i18n/strings.g.dart';
import 'package:localsend_rs/pages/home_page.dart';
import 'package:localsend_rs/pages/setting_page.dart';

class FramePage extends StatefulWidget {
  const FramePage({super.key});

  @override
  State<FramePage> createState() => _FramePageState();
}

class _FramePageState extends State<FramePage> {
  int index = 0;

  List<Widget> pages = [
    HomePage(),
    const SettingPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: index,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (index) {
          setState(() {
            this.index = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: t.home.title,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: t.setting.title,
          ),
        ],
      ),
    );
  }
}
