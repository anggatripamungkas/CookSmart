import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/favorite_screen.dart';
import 'screens/meal_plan_screen.dart';
import 'screens/shopping_list_screen.dart';  // Import screen Daftar Belanja

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CookSmart',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  @override
  _MainNavigationScreenState createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(),
    FavoriteScreen(), // Favorit otomatis mengambil dari database
    MealPlanScreen(),  // Meal Plan kosong untuk awal
    ShoppingListScreen(), // Daftar Belanja, bisa kosong awalnya
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Mengubah latar belakang body menjadi hitam
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Pastikan warna latar belakang diterapkan
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.black, // Latar belakang BottomNavigationBar hitam
        selectedItemColor: Colors.blue, // Warna item yang terpilih
        unselectedItemColor: Colors.white, // Warna item yang tidak terpilih
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorite',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Meal Plan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'List Belanja',
          ),
        ],
      ),
    );
  }

}
