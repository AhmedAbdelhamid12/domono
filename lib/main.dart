import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Domino Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ar'),
      home: const Scaffold(
        backgroundColor: Color(0xFFF5F5F5),
        body: SafeArea(
          child: ScoreScreen(),
        ),
      ),
    );
  }
}

    class ScoreScreen extends StatefulWidget {
  const ScoreScreen({super.key});

  @override
  State<ScoreScreen> createState() => _ScoreScreenState();
}

class _ScoreScreenState extends State<ScoreScreen> {
  String teamAName = 'الفريق الأيمن';
  String teamBName = 'الفريق الأيسر';
  List<int> teamAScores = [];
  List<int> teamBScores = [];
  bool isAdd = true;
  bool selectedA = true;
  int matchLimit = 51;
  List<Map<String, dynamic>> matchHistory = [];
  TextEditingController teamANameController = TextEditingController();
  TextEditingController teamBNameController = TextEditingController();
  bool _showHistory = false;
  bool _showWinBanner = false;
  String _winningTeam = '';
  int _winScore = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    teamANameController.text = teamAName;
    teamBNameController.text = teamBName;
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      teamAName = prefs.getString('teamAName') ?? 'الفريق الأيمن';
      teamBName = prefs.getString('teamBName') ?? 'الفريق الأيسر';

      // حل مشكلة القيم الفارغة
      teamAScores = _safeDecode(prefs.getString('teamAScores'));
      teamBScores = _safeDecode(prefs.getString('teamBScores'));

      // حل مشكلة تاريخ المباريات الفارغ
      final historyJson = prefs.getString('matchHistory');
      if (historyJson != null && historyJson.isNotEmpty) {
        matchHistory = List<Map<String, dynamic>>.from(
          jsonDecode(historyJson),
        );
      } else {
        matchHistory = [];
      }

      _updateMatchLimit();
      teamANameController.text = teamAName;
      teamBNameController.text = teamBName;
    });
  }

  // دالة مساعدة للتحويل الآمن
  List<int> _safeDecode(String? json) {
    if (json == null || json.isEmpty) return [];
    try {
      return List<int>.from(jsonDecode(json));
    } catch (e) {
      return [];
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('teamAName', teamAName);
    await prefs.setString('teamBName', teamBName);
    await prefs.setString('teamAScores', jsonEncode(teamAScores));
    await prefs.setString('teamBScores', jsonEncode(teamBScores));
  }

  Future<void> _saveMatchResult() async {
    final prefs = await SharedPreferences.getInstance();
    final a = teamAScores.fold(0, (a, b) => a + b);
    final b = teamBScores.fold(0, (a, b) => a + b);

    matchHistory.insert(0, {
      'teamAName': teamAName,
      'teamBName': teamBName,
      'teamAScores': List<int>.from(teamAScores),
      'teamBScores': List<int>.from(teamBScores),
      'totalA': a,
      'totalB': b,
      'time': DateTime.now().toIso8601String(),
    });

    if (matchHistory.length > 5) {
      matchHistory = matchHistory.sublist(0, 5);
    }

    await prefs.setString('matchHistory', jsonEncode(matchHistory));
  }

  void _checkForWin() {
    final a = teamAScores.fold(0, (a, b) => a + b);
    final b = teamBScores.fold(0, (a, b) => a + b);

    // تحسين شرط الفوز
    final bool teamAWins = a >= matchLimit && (a - b) >= 2;
    final bool teamBWins = b >= matchLimit && (b - a) >= 2;
    final bool highScoreWin = a >= 71 || b >= 71;

    if (teamAWins || teamBWins || highScoreWin) {
      setState(() {
        if (a > b) {
          _winScore = a;
          _winningTeam = teamAName;
        } else {
          _winScore = b;
          _winningTeam = teamBName;
        }
        _showWinBanner = true;
      });

      _saveMatchResult();

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() => _showWinBanner = false);
        }
      });
    }
  }

  void _showEditTeamNamesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            AppLocalizations.of(context)!.editTeamNames,
            style: const TextStyle(fontWeight: FontWeight.bold)
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: teamANameController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.rightTeam,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: teamBNameController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.leftTeam,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel, style: const TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                teamAName = teamANameController.text;
                teamBName = teamBNameController.text;
              });
              _saveData();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(AppLocalizations.of(context)!.save, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _addScore(int value) {
    setState(() {
      if (!isAdd) value = -value;
      if (selectedA) {
        teamAScores.add(value);
      } else {
        teamBScores.add(value);
      }
      _updateMatchLimit();
      _saveData();
      _checkForWin();
    });
  }

  void _updateMatchLimit() {
    final a = teamAScores.fold(0, (a, b) => a + b);
    final b = teamBScores.fold(0, (a, b) => a + b);
    matchLimit = (a >= 50 && b >= 50) ? 71 : 51;
  }

  void _removeScore(bool isA, int index) {
    setState(() {
      if (isA) {
        teamAScores.removeAt(teamAScores.length - 1 - index); // إصلاح مؤشر الحذف
      } else {
        teamBScores.removeAt(teamBScores.length - 1 - index); // إصلاح مؤشر الحذف
      }
      _updateMatchLimit();
      _saveData();
    });
  }

  void _resetGame(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.resetGame, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(AppLocalizations.of(context)!.resetConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel, style: const TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                teamAScores.clear();
                teamBScores.clear();
                matchLimit = 51;
                _showWinBanner = false;
                _saveData();
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(AppLocalizations.of(context)!.confirm, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreColumn(String name, List<int> scores, bool isA, BuildContext context) {
    int total = scores.fold(0, (a, b) => a + b);
    bool nearWin = total == matchLimit - 1;
    bool win = total >= matchLimit;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedA = isA),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isA ? Colors.blue[50] : Colors.green[50],
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: selectedA == isA
                  ? (isA ? Colors.blueAccent : Colors.green)
                  : Colors.transparent,
              width: 2.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 3),
              )
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: selectedA == isA ? Colors.indigo[900] : Colors.grey[800],
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  '${AppLocalizations.of(context)!.total}: $total',
                  key: ValueKey<int>(total),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: win ? Colors.green[700] : nearWin ? Colors.orange[700] : Colors.indigo[900],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: scores.isEmpty
                    ? Center(
                  child: Text(
                    AppLocalizations.of(context)!.noScores,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
                    : ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(8),
                  itemCount: scores.length,
                  key: ValueKey<int>(scores.length),
                  itemBuilder: (context, index) {
                    return Dismissible(
                      key: Key('${scores[index]}-$index-${isA ? 'A' : 'B'}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red[400],
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) => _removeScore(isA, index), // استخدام المؤشر الصحيح
                      child: Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          title: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Text(
                              '${scores.reversed.toList()[index]}',
                              key: ValueKey<int>(scores[index]),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: scores.reversed.toList()[index] < 0
                                    ? Colors.red[700]
                                    : Colors.indigo[800],
                              ),
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.grey[600]),
                            onPressed: () => _removeScore(isA, index), // استخدام المؤشر الصحيح
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonSize = screenWidth / 8;

    return Stack(
      children: [
        Column(
          children: [
            AppBar(
              title: Text(AppLocalizations.of(context)!.appTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
              centerTitle: true,
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              elevation: 4,
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEditTeamNamesDialog(context),
                  tooltip: AppLocalizations.of(context)!.editTeamNames,
                ),
                IconButton(
                  icon: Icon(_showHistory ? Icons.sports : Icons.history),
                  onPressed: () => setState(() => _showHistory = !_showHistory),
                  tooltip: _showHistory
                      ? AppLocalizations.of(context)!.showCurrentGame
                      : AppLocalizations.of(context)!.showHistory,
                ),
              ],
            ),
            if (!_showHistory) ...[
              Expanded(
                child: Row(
                  children: [
                    _buildScoreColumn(teamAName, teamAScores, true, context),
                    _buildScoreColumn(teamBName, teamBScores, false, context),
                  ],
                ),
              ),
              Container(
                color: Colors.grey[100],
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isAdd ? Colors.blue[100] : Colors.red[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ToggleButtons(
                        isSelected: [isAdd, !isAdd],
                        onPressed: (i) => setState(() => isAdd = i == 0),
                        constraints: const BoxConstraints(
                          minHeight: 48,
                          minWidth: 64,
                        ),
                        color: Colors.black87,
                        selectedColor: Colors.white,
                        fillColor: isAdd ? Colors.blue : Colors.red,
                        borderRadius: BorderRadius.circular(12),
                        children: const [
                          Icon(Icons.add, size: 24),
                          Icon(Icons.remove, size: 24),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: List.generate(7, (i) {
                        final value = isAdd ? (i + 1) : -(i + 1);
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: buttonSize,
                          height: buttonSize,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: selectedA ? Colors.blue[200] : Colors.green[200],
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => _addScore(i + 1),
                            child: Text(
                              '$value',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _resetGame(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        minimumSize: const Size(120, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(AppLocalizations.of(context)!.resetGame, style: const TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${AppLocalizations.of(context)!.selectedTeam}: ${selectedA ? teamAName : teamBName}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: selectedA ? Colors.blue : Colors.green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${AppLocalizations.of(context)!.matchLimit}: $matchLimit ${AppLocalizations.of(context)!.points}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Expanded(
                child: matchHistory.isEmpty
                    ? Center(
                  child: Text(
                    AppLocalizations.of(context)!.noHistory,
                    style: TextStyle(color: Colors.grey[600], fontSize: 18),
                  ),
                )
                    : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        AppLocalizations.of(context)!.history,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: matchHistory.length,
                        itemBuilder: (context, index) {
                          final match = matchHistory[index];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      '${match['teamAName']}',
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.indigo[50],
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${match['totalA']} - ${match['totalB']}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Flexible(
                                    child: Text(
                                      '${match['teamBName']}',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(match['time'])),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ),
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('${AppLocalizations.of(context)!.matchResult} ${index + 1}', style: TextStyle(fontWeight: FontWeight.bold)),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        RichText(
                                          text: TextSpan(
                                            style: TextStyle(color: Colors.black, fontSize: 16),
                                            children: [
                                              TextSpan(
                                                text: '${match['teamAName']}: ',
                                                style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                                              ),
                                              TextSpan(text: '${match['totalA']}'),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        RichText(
                                          text: TextSpan(
                                            style: TextStyle(color: Colors.black, fontSize: 16),
                                            children: [
                                              TextSpan(
                                                text: '${match['teamBName']}: ',
                                                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                              ),
                                              TextSpan(text: '${match['totalB']}'),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '${AppLocalizations.of(context)!.date}: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(match['time']))}',
                                          style: TextStyle(color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(context),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.indigo,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                        child: Text(AppLocalizations.of(context)!.close, style: const TextStyle(color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),

        // أنيميشن الفوز
        if (_showWinBanner)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: _showWinBanner ? 1 : 0,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[700],
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.celebration,
                      size: 40,
                      color: Colors.yellow,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '$_winningTeam يفوز بـ $_winScore نقطة!',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}