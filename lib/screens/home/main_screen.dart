import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:test3/screens/email/compose_email_screen.dart';
import 'package:test3/screens/profile/profile_screen.dart';
import 'package:test3/screens/home/inbox_tab.dart';
import 'package:test3/screens/home/home_screen.dart';
import 'package:test3/screens/home/draft_tab.dart';
import 'package:test3/screens/home/trash_tab.dart';
import 'package:test3/screens/home/label_management_screen.dart';
import 'package:test3/screens/email/starred_tab.dart';
import 'package:test3/screens/home/sent_tab.dart';
import 'package:test3/screens/search/filter_dialog.dart';
import 'package:test3/screens/search/search_filter.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final TextEditingController _searchController = TextEditingController();
  SearchFilter _filter = SearchFilter();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _filter = _filter.copyWith(keyword: _searchController.text.trim());
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => FilterDialog(
        initialFilter: _filter,
        onApply: (newFilter) {
          setState(() {
            _filter = newFilter;
            _searchController.text = newFilter.keyword;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      drawer: Drawer(
        child: Container(
          color: Colors.deepPurple[50],
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.deepPurple, Colors.purpleAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                margin: EdgeInsets.zero,
                padding: EdgeInsets.zero,
                child: Container(
                  width: double.infinity,
                  height: 160,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundImage: const AssetImage('assets/images/avatar1.webp'),
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        (user.displayName != null && user.displayName!.isNotEmpty) ? user.displayName! : 'Dmail',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              offset: Offset(1, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _drawerItem(Icons.inbox, 'Hộp thư đến', () => Navigator.pop(context)),
              _drawerItem(Icons.send, 'Đã gửi', () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => SentTab(filter: _filter)));
              }),
              _drawerItem(Icons.star, 'Được gắn sao', () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const StarredTab()));
              }),
              _drawerItem(Icons.drafts, 'Bản nháp', () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const DraftTab()));
              }),
              _drawerItem(Icons.delete, 'Thùng rác', () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TrashTab()));
              }),
              _drawerItem(Icons.label, 'Quản lý nhãn', () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LabelManagementScreen()));
              }),
              _drawerItem(Icons.settings, 'Cài đặt', () {
                Navigator.pop(context);
              }),
              const Divider(),
              _drawerItem(Icons.logout, 'Đăng xuất', () async {
                try {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (route) => false,
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi khi đăng xuất: ${e.toString()}')),
                  );
                }
              }, color: Colors.red),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.deepPurple,
        title: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.deepPurple[100],
            borderRadius: BorderRadius.circular(28),
          ),
          child: TextField(
            controller: _searchController,
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm email',
              border: InputBorder.none,
              hintStyle: const TextStyle(color: Colors.white70, fontSize: 16),
              prefixIcon: const Icon(Icons.search, color: Colors.white),
              suffixIcon: _filter.keyword.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
            ),
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: _filter.isEmpty ? Colors.white : Colors.amber,
            ),
            onPressed: _showFilterDialog,
            tooltip: 'Bộ lọc nâng cao',
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
            child: const Padding(
              padding: EdgeInsets.only(right: 12),
              child: CircleAvatar(
                radius: 18,
                backgroundImage: AssetImage('assets/images/avatar1.webp'),
              ),
            ),
          ),
        ],
      ),
      body: InboxTab(filter: _filter),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ComposeEmailScreen()),
          );
        },
        icon: const Icon(Icons.edit, color: Colors.white),
        label: const Text('Soạn thư', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        elevation: 4,
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.deepPurple),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? Colors.deepPurple, 
          fontWeight: FontWeight.w500, //ddww
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      hoverColor: Colors.deepPurple.withOpacity(0.08),
    );
  }
}