import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/game_model.dart';
import '../services/storage_service.dart';
import '../widgets/score_column.dart';
import '../widgets/score_input_panel.dart';
import '../widgets/game_controls.dart';
import '../widgets/win_celebration.dart';
import 'history_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late GameModel _currentGame;
  bool _selectedTeamA = true;
  bool _showWinCelebration = false;
  late AnimationController _celebrationController;

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _loadGame();
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    super.dispose();
  }

  void _loadGame() {
    try {
      final savedGame = StorageService.instance.getCurrentGame();
      final teamNames = StorageService.instance.getTeamNames();
      
      if (savedGame != null && !savedGame.isCompleted) {
        _currentGame = savedGame;
      } else {
        _currentGame = GameModel(
          teamAName: teamNames['teamA']!,
          teamBName: teamNames['teamB']!,
          teamAScores: [],
          teamBScores: [],
          createdAt: DateTime.now(),
        );
      }
      
      setState(() {});
    } catch (e) {
      _showErrorSnackBar('Error loading game: $e');
      _createNewGame();
    }
  }

  void _createNewGame() {
    final teamNames = StorageService.instance.getTeamNames();
    _currentGame = GameModel(
      teamAName: teamNames['teamA']!,
      teamBName: teamNames['teamB']!,
      teamAScores: [],
      teamBScores: [],
      createdAt: DateTime.now(),
    );
    setState(() {});
  }

  Future<void> _saveGame() async {
    try {
      await StorageService.instance.saveCurrentGame(_currentGame);
    } catch (e) {
      _showErrorSnackBar('Error saving game: $e');
    }
  }

  void _addScore(int score) {
    if (_currentGame.hasWinner) return;

    setState(() {
      if (_selectedTeamA) {
        _currentGame = _currentGame.copyWith(
          teamAScores: [..._currentGame.teamAScores, score],
        );
      } else {
        _currentGame = _currentGame.copyWith(
          teamBScores: [..._currentGame.teamBScores, score],
        );
      }
    });

    _saveGame();
    _checkForWin();
    
    // Haptic feedback
    HapticFeedback.lightImpact();
  }

  void _removeScore(bool isTeamA, int index) {
    if (_currentGame.hasWinner) return;

    setState(() {
      if (isTeamA && _currentGame.teamAScores.isNotEmpty) {
        final scores = List<int>.from(_currentGame.teamAScores);
        scores.removeAt(scores.length - 1 - index);
        _currentGame = _currentGame.copyWith(teamAScores: scores);
      } else if (!isTeamA && _currentGame.teamBScores.isNotEmpty) {
        final scores = List<int>.from(_currentGame.teamBScores);
        scores.removeAt(scores.length - 1 - index);
        _currentGame = _currentGame.copyWith(teamBScores: scores);
      }
    });

    _saveGame();
    HapticFeedback.selectionClick();
  }

  void _checkForWin() {
    if (_currentGame.hasWinner && !_showWinCelebration) {
      setState(() {
        _showWinCelebration = true;
      });
      
      _celebrationController.forward();
      HapticFeedback.heavyImpact();
      
      // Auto-hide celebration after animation
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showWinCelebration = false;
          });
          _celebrationController.reset();
        }
      });
    }
  }

  Future<void> _resetGame() async {
    final confirmed = await _showConfirmationDialog(
      title: AppLocalizations.of(context)!.resetGame,
      content: AppLocalizations.of(context)!.resetConfirmation,
    );
    
    if (confirmed) {
      // Save current game to history if it has scores
      if (_currentGame.teamAScores.isNotEmpty || _currentGame.teamBScores.isNotEmpty) {
        try {
          await StorageService.instance.saveGameToHistory(_currentGame);
        } catch (e) {
          _showErrorSnackBar('Error saving game to history: $e');
        }
      }
      
      // Clear current game and create new one
      await StorageService.instance.clearCurrentGame();
      _createNewGame();
      
      setState(() {
        _showWinCelebration = false;
        _selectedTeamA = true;
      });
      
      _celebrationController.reset();
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> _editTeamNames() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _TeamNamesDialog(
        initialTeamA: _currentGame.teamAName,
        initialTeamB: _currentGame.teamBName,
      ),
    );
    
    if (result != null) {
      try {
        await StorageService.instance.saveTeamNames(
          result['teamA']!,
          result['teamB']!,
        );
        
        setState(() {
          _currentGame = _currentGame.copyWith(
            teamAName: result['teamA']!,
            teamBName: result['teamB']!,
          );
        });
        
        _saveGame();
      } catch (e) {
        _showErrorSnackBar('Error saving team names: $e');
      }
    }
  }

  void _navigateToHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const HistoryScreen(),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _editTeamNames,
            tooltip: AppLocalizations.of(context)!.editTeamNames,
          ),
          IconButton(
            icon: const Icon(Icons.history_outlined),
            onPressed: _navigateToHistory,
            tooltip: AppLocalizations.of(context)!.history,
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Score columns
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    ScoreColumn(
                      teamName: _currentGame.teamAName,
                      scores: _currentGame.teamAScores,
                      isSelected: _selectedTeamA,
                      isTeamA: true,
                      total: _currentGame.teamATotal,
                      matchLimit: _currentGame.matchLimit,
                      hasWon: _currentGame.hasWinner && _currentGame.winner == 'A',
                      onTap: () => setState(() => _selectedTeamA = true),
                      onRemoveScore: (index) => _removeScore(true, index),
                    ),
                    ScoreColumn(
                      teamName: _currentGame.teamBName,
                      scores: _currentGame.teamBScores,
                      isSelected: !_selectedTeamA,
                      isTeamA: false,
                      total: _currentGame.teamBTotal,
                      matchLimit: _currentGame.matchLimit,
                      hasWon: _currentGame.hasWinner && _currentGame.winner == 'B',
                      onTap: () => setState(() => _selectedTeamA = false),
                      onRemoveScore: (index) => _removeScore(false, index),
                    ),
                  ],
                ),
              ),
              
              // Score input panel
              ScoreInputPanel(
                selectedTeamName: _selectedTeamA 
                    ? _currentGame.teamAName 
                    : _currentGame.teamBName,
                matchLimit: _currentGame.matchLimit,
                isGameFinished: _currentGame.hasWinner,
                onScoreAdd: _addScore,
              ),
              
              // Game controls
              GameControls(
                onReset: _resetGame,
                isGameFinished: _currentGame.hasWinner,
              ),
            ],
          ),
          
          // Win celebration overlay
          if (_showWinCelebration)
            WinCelebration(
              winnerName: _currentGame.winnerName ?? '',
              winnerScore: _currentGame.winnerScore,
              controller: _celebrationController,
            ),
        ],
      ),
    );
  }
}

class _TeamNamesDialog extends StatefulWidget {
  final String initialTeamA;
  final String initialTeamB;

  const _TeamNamesDialog({
    required this.initialTeamA,
    required this.initialTeamB,
  });

  @override
  State<_TeamNamesDialog> createState() => _TeamNamesDialogState();
}

class _TeamNamesDialogState extends State<_TeamNamesDialog> {
  late TextEditingController _teamAController;
  late TextEditingController _teamBController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _teamAController = TextEditingController(text: widget.initialTeamA);
    _teamBController = TextEditingController(text: widget.initialTeamB);
  }

  @override
  void dispose() {
    _teamAController.dispose();
    _teamBController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.editTeamNames),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _teamAController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.rightTeam,
                prefixIcon: const Icon(Icons.group_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Team name cannot be empty';
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _teamBController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.leftTeam,
                prefixIcon: const Icon(Icons.group_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Team name cannot be empty';
                }
                return null;
              },
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _save(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(AppLocalizations.of(context)!.save),
        ),
      ],
    );
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop({
        'teamA': _teamAController.text.trim(),
        'teamB': _teamBController.text.trim(),
      });
    }
  }
}