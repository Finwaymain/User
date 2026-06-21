import 'package:flutter/material.dart';

class MedicalIconsWidget extends StatelessWidget {
  const MedicalIconsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        children: [
          // Top icons
          Positioned(
            left: 30,
            top: 0,
            child: _buildIconCircle(Icons.favorite, 35),
          ),
          Positioned(
            right: 20,
            top: 15,
            child: _buildIconCircle(Icons.medical_services, 25),
          ),

          // Middle icons
          Positioned(
            left: 10,
            top: 40,
            child: _buildIconCircle(Icons.local_pharmacy, 28),
          ),
          Positioned(
            left: 50,
            top: 45,
            child: _buildIconCircle(Icons.healing, 22),
          ),
          Positioned(
            right: 5,
            top: 50,
            child: _buildIconCircle(Icons.medication, 26),
          ),

          // Bottom icons
          Positioned(
            left: 25,
            top: 75,
            child: _buildIconCircle(Icons.science, 20),
          ),
          Positioned(
            right: 15,
            top: 80,
            child: _buildIconCircle(Icons.medical_information, 24),
          ),
          Positioned(
            left: 60,
            bottom: 5,
            child: _buildIconCircle(Icons.vaccines, 28),
          ),
        ],
      ),
    );
  }

  Widget _buildIconCircle(IconData icon, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          color: Colors.white.withValues(alpha: 0.5),
          size: size * 0.5,
        ),
      ),
    );
  }
}