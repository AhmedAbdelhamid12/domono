import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ScoreColumn extends StatelessWidget {
  final String teamName;
  final List<int> scores;
  final bool isSelected;
  final bool isTeamA;
  final int total;
  final int matchLimit;
  final bool hasWon;
  final VoidCallback onTap;
  final Function(int) onRemoveScore;

  const ScoreColumn({
    super.key,
    required this.teamName,
    required this.scores,
    required this.isSelected,
    required this.isTeamA,
    required this.total,
    required this.matchLimit,
    required this.hasWon,
    required this.onTap,
    required this.onRemoveScore,
  });

  Color get _teamColor => isTeamA ? Colors.blue : Colors.green;
  bool get _isNearWin => total >= matchLimit - 5 && total < matchLimit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: hasWon 
                ? colorScheme.primaryContainer.withOpacity(0.3)
                : isSelected 
                    ? _teamColor.withOpacity(0.1)
                    : colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasWon
                  ? colorScheme.primary
                  : isSelected
                      ? _teamColor
                      : colorScheme.outline.withOpacity(0.3),
              width: hasWon ? 3 : isSelected ? 2 : 1,
            ),
            boxShadow: [
              if (isSelected || hasWon)
                BoxShadow(
                  color: (hasWon ? colorScheme.primary : _teamColor).withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Column(
            children: [
              // Team header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: hasWon 
                      ? colorScheme.primary.withOpacity(0.1)
                      : isSelected 
                          ? _teamColor.withOpacity(0.05)
                          : null,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (hasWon) ...[
                          Icon(
                            Icons.emoji_events,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Flexible(
                          child: Text(
                            teamName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: hasWon 
                                  ? colorScheme.primary
                                  : isSelected 
                                      ? _teamColor
                                      : colorScheme.onSurface,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        key: ValueKey(total),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: hasWon
                              ? colorScheme.primary
                              : _isNearWin
                                  ? Colors.orange
                                  : _teamColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${AppLocalizations.of(context)!.total}: $total',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Scores list
              Expanded(
                child: scores.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.sports_score_outlined,
                              size: 48,
                              color: colorScheme.outline,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppLocalizations.of(context)!.noScores,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.outline,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.all(8),
                        itemCount: scores.length,
                        itemBuilder: (context, index) {
                          final score = scores.reversed.toList()[index];
                          final isNegative = score < 0;
                          
                          return Dismissible(
                            key: Key('${isTeamA ? 'A' : 'B'}-$index-$score'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 16),
                              decoration: BoxDecoration(
                                color: colorScheme.error,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.delete_outline,
                                color: colorScheme.onError,
                              ),
                            ),
                            onDismissed: (_) => onRemoveScore(index),
                            child: Card(
                              margin: const EdgeInsets.symmetric(vertical: 2),
                              elevation: 1,
                              child: ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                title: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: Text(
                                    score.toString(),
                                    key: ValueKey(score),
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isNegative
                                          ? colorScheme.error
                                          : _teamColor,
                                    ),
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    size: 18,
                                    color: colorScheme.outline,
                                  ),
                                  onPressed: () => onRemoveScore(index),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}