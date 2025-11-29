import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/pet.dart';

class PetCard extends StatelessWidget {
  final Pet pet;
  const PetCard({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          width: 2,
          color: AppTheme.oceanBlue.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.oceanBlue.withOpacity(0.15),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 12),
          
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.oceanBlue,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.oceanBlue.withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    width: 3,
                    color: Colors.white,
                  ),
                ),
                child: Hero(
                  tag: pet.name,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(36),
                    child: Image.asset(
                      pet.image,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              // Paw print overlay
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.oceanBlue,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.oceanBlue.withOpacity(0.4),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.pets,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 10),
          
          // Pet Name
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              pet.name,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: AppTheme.deepOcean,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          SizedBox(height: 8),
          
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.oceanBlue,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.oceanBlue.withOpacity(0.3),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.restaurant, color: Colors.white, size: 14),
                  SizedBox(width: 5),
                  Text(
                    'FEED',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
                  SizedBox(width: 5),
                  Icon(Icons.arrow_forward_ios, size: 10, color: Colors.white),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 12),
        ],
      ),
    );
  }
}