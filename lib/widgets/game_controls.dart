import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class GameControls extends StatelessWidget {
  final VoidCallback onReset;
  final bool isGameFinished;

  const GameControls({
    super.key,
    required this.onReset,
    required this.isGameFinished,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: FilledButton.icon(
          onPressed: onReset,
          icon: Icon(
            isGameFinished ? Icons.refresh : Icons.restart_alt,
          ),
          label: Text(
            isGameFinished 
                ? 'مباراة جديدة'
                : AppLocalizations.of(context)!.resetGame,
          ),
          style: FilledButton.styleFrom(
            backgroundColor: isGameFinished 
                ? colorScheme.primary
                : colorScheme.error,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            minimumSize: const Size(double.infinity, 56),
          ),
        ),
      ),
    );
  }
}