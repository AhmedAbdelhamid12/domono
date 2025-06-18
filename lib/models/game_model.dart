import 'dart:convert';

class GameModel {
  final String teamAName;
  final String teamBName;
  final List<int> teamAScores;
  final List<int> teamBScores;
  final DateTime createdAt;
  final DateTime? completedAt;
  final bool isCompleted;
  final String? winnerId;

  GameModel({
    required this.teamAName,
    required this.teamBName,
    required this.teamAScores,
    required this.teamBScores,
    required this.createdAt,
    this.completedAt,
    this.isCompleted = false,
    this.winnerId,
  });

  int get teamATotal => teamAScores.fold(0, (sum, score) => sum + score);
  int get teamBTotal => teamBScores.fold(0, (sum, score) => sum + score);
  
  int get matchLimit {
    return (teamATotal >= 50 && teamBTotal >= 50) ? 71 : 51;
  }
  
  bool get hasWinner {
    final totalA = teamATotal;
    final totalB = teamBTotal;
    final limit = matchLimit;
    
    // Standard win conditions
    final teamAWins = totalA >= limit && (totalA - totalB) >= 2;
    final teamBWins = totalB >= limit && (totalB - totalA) >= 2;
    
    // High score win (71+ points)
    final highScoreWin = totalA >= 71 || totalB >= 71;
    
    return teamAWins || teamBWins || highScoreWin;
  }
  
  String? get winner {
    if (!hasWinner) return null;
    return teamATotal > teamBTotal ? 'A' : 'B';
  }
  
  String? get winnerName {
    final w = winner;
    if (w == null) return null;
    return w == 'A' ? teamAName : teamBName;
  }
  
  int get winnerScore {
    final w = winner;
    if (w == null) return 0;
    return w == 'A' ? teamATotal : teamBTotal;
  }

  GameModel copyWith({
    String? teamAName,
    String? teamBName,
    List<int>? teamAScores,
    List<int>? teamBScores,
    DateTime? createdAt,
    DateTime? completedAt,
    bool? isCompleted,
    String? winnerId,
  }) {
    return GameModel(
      teamAName: teamAName ?? this.teamAName,
      teamBName: teamBName ?? this.teamBName,
      teamAScores: teamAScores ?? List.from(this.teamAScores),
      teamBScores: teamBScores ?? List.from(this.teamBScores),
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      isCompleted: isCompleted ?? this.isCompleted,
      winnerId: winnerId ?? this.winnerId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'teamAName': teamAName,
      'teamBName': teamBName,
      'teamAScores': teamAScores,
      'teamBScores': teamBScores,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'isCompleted': isCompleted,
      'winnerId': winnerId,
    };
  }

  factory GameModel.fromJson(Map<String, dynamic> json) {
    return GameModel(
      teamAName: json['teamAName'] ?? 'Team A',
      teamBName: json['teamBName'] ?? 'Team B',
      teamAScores: List<int>.from(json['teamAScores'] ?? []),
      teamBScores: List<int>.from(json['teamBScores'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt']) 
          : null,
      isCompleted: json['isCompleted'] ?? false,
      winnerId: json['winnerId'],
    );
  }

  String toJsonString() => jsonEncode(toJson());
  
  factory GameModel.fromJsonString(String jsonString) {
    return GameModel.fromJson(jsonDecode(jsonString));
  }
}