import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String value;

  const StatCard({
    Key? key,
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
  }) ;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isLightMode = brightness == Brightness.light;
    
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(width: double.infinity, padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: isLightMode ? Colors.white : color.withValues(alpha:0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha:0.5),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: isLightMode ? Colors.black87 : Colors.white70,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isLightMode ? Colors.black : Colors.white,
                ),
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 


