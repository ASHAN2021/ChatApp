import 'package:flutter/material.dart';
import '../Services/database_service.dart';
import '../Services/notification_service.dart';
import 'home_tab.dart';
import 'chat_tab.dart';
import 'scan_tab.dart';
import 'profile_tab.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  void _navigateToScanTab() {
    setState(() {
      _currentIndex = 2; // Scan tab index
    });
    _pageController.animateToPage(
      2,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  List<Widget> get _tabs => [
    HomeTab(),
    ChatTab(onNavigateToScan: _navigateToScanTab),
    ScanTab(),
    ProfileTab(),
  ];

  final List<String> _tabTitles = ['Home', 'Chats', 'Scan', 'Profile'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _tabTitles[_currentIndex],
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Color(0xff075E54),
        elevation: 0,
        centerTitle: true,
        actions: [
          // Temporary database fix button
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () async {
              try {
                print('🔄 Manual database reset triggered...');
                await DatabaseService.forceCompleteReset();
                NotificationService.showSuccess(
                  context,
                  'Database reset! Please restart the app.',
                );
              } catch (e) {
                NotificationService.showError(context, 'Reset failed: $e');
              }
            },
            tooltip: 'Fix Database Issues',
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        children: _tabs,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
            _pageController.animateToPage(
              index,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Color(0xff075E54),
          unselectedItemColor: Colors.grey,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          elevation: 0,
          backgroundColor: Colors.transparent,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              activeIcon: Icon(Icons.home, color: Color(0xff075E54)),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble, color: Color(0xff075E54)),
              label: 'Chats',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner),
              activeIcon: Icon(Icons.qr_code_scanner, color: Color(0xff075E54)),
              label: 'Scan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person, color: Color(0xff075E54)),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
