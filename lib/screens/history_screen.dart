import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../models/game_model.dart';
import '../services/storage_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<GameModel> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    try {
      final history = StorageService.instance.getGameHistory();
      setState(() {
        _history = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error loading history: $e');
    }
  }

  Future<void> _clearHistory() async {
    final confirmed = await _showConfirmationDialog(
      title: 'مسح السجل',
      content: 'هل أنت متأكد من مسح جميع المباريات السابقة؟',
    );
    
    if (confirmed) {
      try {
        await StorageService.instance.clearGameHistory();
        setState(() {
          _history.clear();
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم مسح السجل بنجاح'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        _showErrorSnackBar('Error clearing history: $e');
      }
    }
  }

  Future<bool> _showConfirmationDialog({
    required String title,
    required String content,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocalizations.of(context)!.confirm),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showGameDetails(GameModel game) {
    showDialog(
      context: context,
      builder: (context) => _GameDetailsDialog(game: game),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.history),
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearHistory,
              tooltip: 'مسح السجل',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history_outlined,
                        size: 80,
                        color: colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.noHistory,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final game = _history[index];
                    return _GameHistoryCard(
                      game: game,
                      onTap: () => _showGameDetails(game),
                    );
                  },
                ),
    );
  }
}

class _GameHistoryCard extends StatelessWidget {
  final GameModel game;
  final VoidCallback onTap;

  const _GameHistoryCard({
    required this.game,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isTeamAWinner = game.winner == 'A';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Teams and scores
              Row(
                children: [
                  // Team A
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (isTeamAWinner) ...[
                              Icon(
                                Icons.emoji_events,
                                size: 16,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 4),
                            ],
                            Flexible(
                              child: Text(
                                game.teamAName,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: isTeamAWinner 
                                      ? FontWeight.bold 
                                      : FontWeight.normal,
                                  color: isTeamAWinner 
                                      ? colorScheme.primary 
                                      : null,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          game.teamATotal.toString(),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // VS indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'VS',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  
                  // Team B
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Flexible(
                              child: Text(
                                game.teamBName,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: !isTeamAWinner 
                                      ? FontWeight.bold 
                                      : FontWeight.normal,
                                  color: !isTeamAWinner 
                                      ? colorScheme.primary 
                                      : null,
                                ),
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end,
                              ),
                            ),
                            if (!isTeamAWinner) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.emoji_events,
                                size: 16,
                                color: Colors.amber,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          game.teamBTotal.toString(),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Game info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('yyyy-MM-dd HH:mm').format(
                      game.completedAt ?? game.createdAt,
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.sports_score,
                        size: 16,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${game.teamAScores.length + game.teamBScores.length} جولة',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameDetailsDialog extends StatelessWidget {
  final GameModel game;

  const _GameDetailsDialog({required this.game});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.matchResult),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Final scores
            _buildScoreSection(
              context,
              game.teamAName,
              game.teamATotal,
              game.teamAScores,
              Colors.blue,
              game.winner == 'A',
            ),
            
            const SizedBox(height: 16),
            
            _buildScoreSection(
              context,
              game.teamBName,
              game.teamBTotal,
              game.teamBScores,
              Colors.green,
              game.winner == 'B',
            ),
            
            const SizedBox(height: 16),
            
            // Game info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${AppLocalizations.of(context)!.date}: ${DateFormat('yyyy-MM-dd HH:mm').format(game.completedAt ?? game.createdAt)}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'عدد الجولات: ${game.teamAScores.length + game.teamBScores.length}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'الحد الفاصل: ${game.matchLimit}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context)!.close),
        ),
      ],
    );
  }

  Widget _buildScoreSection(
    BuildContext context,
    String teamName,
    int total,
    List<int> scores,
    Color color,
    bool isWinner,
  ) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: isWinner ? Border.all(color: color, width: 2) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isWinner) ...[
                Icon(Icons.emoji_events, size: 16, color: Colors.amber),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  teamName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              Text(
                total.toString(),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          if (scores.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: scores.map((score) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: score < 0 
                        ? Colors.red.withOpacity(0.2)
                        : color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    score.toString(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: score < 0 ? Colors.red : color,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}