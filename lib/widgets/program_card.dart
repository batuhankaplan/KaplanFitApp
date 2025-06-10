import 'package:flutter/material.dart';

class ProgramCard extends StatelessWidget {
  final String day;
  final List<String> activities;
  final List<String> meals;
  final String? additionalNote;

  const ProgramCard({
    Key? key,
    required this.day,
    required this.activities,
    required this.meals,
    this.additionalNote,
  }) ;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF19475E),
              Color(0xFF1A7A9E),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              day,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (activities.isNotEmpty) ...[
              ...activities.map((activity) => _buildProgramItem(activity, Icons.directions_run)),
              const SizedBox(height: 8),
            ],
            if (meals.isNotEmpty) ...[
              ...meals.map((meal) => _buildProgramItem(meal, Icons.restaurant)),
              const SizedBox(height: 8),
            ],
            if (additionalNote != null) ...[
              _buildProgramItem(additionalNote!, Icons.note),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgramItem(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.white70,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 
