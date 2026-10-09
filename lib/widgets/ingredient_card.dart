import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';

class IngredientCard extends StatelessWidget {
  const IngredientCard({
    super.key,
    required this.name,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });
  final String name;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: name,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: AnimatedScale(
          scale: selected ? 1.04 : 1,
          duration: const Duration(milliseconds: 350),
          curve: Curves.elasticOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFEEF5F0) : AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: selected ? AppColors.sage : AppColors.border,
                width: selected ? 2 : 1,
              ),
              boxShadow: cardShadow,
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 34)),
                      const SizedBox(height: 6),
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: AnimatedScale(
                    scale: selected ? 1 : 0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutBack,
                    child: const CircleAvatar(
                      radius: 11,
                      backgroundColor: AppColors.sage,
                      child: Icon(Icons.check, size: 15, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
