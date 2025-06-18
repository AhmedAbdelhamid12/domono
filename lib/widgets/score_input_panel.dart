import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ScoreInputPanel extends StatefulWidget {
  final String selectedTeamName;
  final int matchLimit;
  final bool isGameFinished;
  final Function(int) onScoreAdd;

  const ScoreInputPanel({
    super.key,
    required this.selectedTeamName,
    required this.matchLimit,
    required this.isGameFinished,
    required this.onScoreAdd,
  });

  @override
  State<ScoreInputPanel> createState() => _ScoreInputPanelState();
}

class _ScoreInputPanelState extends State<ScoreInputPanel> {
  bool _isAddMode = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Selected team indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                Text(
                  AppLocalizations.of(context)!.selectedTeam,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.selectedTeamName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${AppLocalizations.of(context)!.matchLimit}: ${widget.matchLimit} ${AppLocalizations.of(context)!.points}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Add/Subtract toggle
          if (!widget.isGameFinished) ...[
            SegmentedButton<bool>(
              segments: [
                ButtonSegment<bool>(
                  value: true,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add,
                        size: 18,
                        color: _isAddMode ? Colors.white : colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'إضافة',
                        style: TextStyle(
                          color: _isAddMode ? Colors.white : colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                ButtonSegment<bool>(
                  value: false,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.remove,
                        size: 18,
                        color: !_isAddMode ? Colors.white : colorScheme.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'خصم',
                        style: TextStyle(
                          color: !_isAddMode ? Colors.white : colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              selected: {_isAddMode},
              onSelectionChanged: (Set<bool> selection) {
                setState(() {
                  _isAddMode = selection.first;
                });
              },
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: _isAddMode 
                    ? colorScheme.primary 
                    : colorScheme.error,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Score buttons
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: List.generate(7, (index) {
                final value = index + 1;
                final actualValue = _isAddMode ? value : -value;
                
                return SizedBox(
                  width: 60,
                  height: 60,
                  child: FilledButton(
                    onPressed: () => widget.onScoreAdd(actualValue),
                    style: FilledButton.styleFrom(
                      backgroundColor: _isAddMode 
                          ? colorScheme.primary.withOpacity(0.8)
                          : colorScheme.error.withOpacity(0.8),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      actualValue.toString(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ] else ...[
            // Game finished message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.emoji_events,
                    size: 32,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'انتهت المباراة!',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}