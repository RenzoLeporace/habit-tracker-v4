import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final double width; // 1. Agregamos la variable

  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.subtitle,
    this.width =
        155, // 2. Le damos un valor por defecto para no romper lo anterior
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width, // 3. Usamos la variable aquí
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bg2.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.text2,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.text2, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
