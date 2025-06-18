import 'package:flutter/material.dart';
import 'dart:math' as math;

class WinCelebration extends StatelessWidget {
  final String winnerName;
  final int winnerScore;
  final AnimationController controller;

  const WinCelebration({
    super.key,
    required this.winnerName,
    required this.winnerScore,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.7 * controller.value),
            child: Center(
              child: Transform.scale(
                scale: Curves.elasticOut.transform(controller.value),
                child: Container(
                  margin: const EdgeInsets.all(32),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Animated trophy
                      AnimatedBuilder(
                        animation: controller,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: math.sin(controller.value * 4 * math.pi) * 0.1,
                            child: Icon(
                              Icons.emoji_events,
                              size: 80,
                              color: Colors.amber,
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Winner text
                      Text(
                        '🎉 تهانينا! 🎉',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Text(
                        winnerName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Text(
                        'فاز بنتيجة $winnerScore نقطة!',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Confetti animation
                      SizedBox(
                        height: 40,
                        child: AnimatedBuilder(
                          animation: controller,
                          builder: (context, child) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(5, (index) {
                                final delay = index * 0.2;
                                final animValue = math.max(0.0, 
                                    math.min(1.0, (controller.value - delay) / 0.6));
                                
                                return Transform.translate(
                                  offset: Offset(
                                    math.sin(animValue * 2 * math.pi) * 20,
                                    -animValue * 30,
                                  ),
                                  child: Transform.rotate(
                                    angle: animValue * 4 * math.pi,
                                    child: Text(
                                      ['🎊', '🎉', '✨', '🌟', '💫'][index],
                                      style: const TextStyle(fontSize: 24),
                                    ),
                                  ),
                                );
                              }),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}