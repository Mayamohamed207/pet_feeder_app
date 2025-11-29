import 'package:flutter/material.dart';
import '../widgets/pet_card.dart';
import '../models/pet.dart';
import '../routes.dart';
import '../app_theme.dart';
import '../services/firebase_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Pet> pets = [
    Pet(name: 'Toffy', image: 'assets/images/Toffy.jpg'),
    Pet(name: 'Tofa', image: 'assets/images/Tofa.jpg'),
    Pet(name: 'Totty', image: 'assets/images/Totty.jpg'),
    Pet(name: 'Tota', image: 'assets/images/Tota.jpg'),

  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pets, color: AppTheme.oceanBlue, size: 24),
            SizedBox(width: 8),
            Text(
              "Pet Paradise",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppTheme.oceanBlue,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppTheme.oceanBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.history, color: AppTheme.deepOcean, size: 22),
              onPressed: () => Navigator.pushNamed(context, Routes.history),
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: AppTheme.oceanBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.logout, color: AppTheme.deepOcean, size: 22),
              onPressed: () async {
                await FirebaseService.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header with paw icon - NO ANIMATIONS
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              color: AppTheme.oceanBlue.withOpacity(0.08),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.oceanBlue,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.oceanBlue.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(Icons.pets, size: 40, color: Colors.white),
                ),
                SizedBox(height: 16),
                Text(
                  "Choose Your Pet",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.deepOcean,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.touch_app, size: 18, color: AppTheme.oceanBlue),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        "Tap to feed your furry friend",
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.deepOcean.withOpacity(0.7),
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          SizedBox(height: 16),
          
          // Pet Grid - Fixed for mobile
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                physics: BouncingScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.82,
                ),
                itemCount: pets.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => Navigator.pushNamed(
                      context,
                      Routes.feed,
                      arguments: pets[index],
                    ),
                    child: PetCard(pet: pets[index]),
                  );
                },
              ),
            ),
          ),
          
          SizedBox(height: 12),
        ],
      ),
    );
  }
}