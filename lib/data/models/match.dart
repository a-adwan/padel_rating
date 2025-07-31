class Match {
  final String id;
  final DateTime date;
  final String team1Player1Id;
  final String team1Player2Id;
  final String team2Player1Id;
  final String team2Player2Id;
  final int team1Score;
  final int team2Score;
  final int winnerTeam; // 1 for Team 1, 2 for Team 2
  final bool isRatingProcessed; // Track if this match has been processed for rating updates

  Match({
    required this.id,
    required this.date,
    required this.team1Player1Id,
    required this.team1Player2Id,
    required this.team2Player1Id,
    required this.team2Player2Id,
    required this.team1Score,
    required this.team2Score,
    required this.winnerTeam,
    this.isRatingProcessed = false,
  });

  // Convert Match to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.millisecondsSinceEpoch,
      'team1Player1Id': team1Player1Id,
      'team1Player2Id': team1Player2Id,
      'team2Player1Id': team2Player1Id,
      'team2Player2Id': team2Player2Id,
      'team1Score': team1Score,
      'team2Score': team2Score,
      'winnerTeam': winnerTeam,
      'isRatingProcessed': isRatingProcessed ? 1 : 0,
    };
  }

  // Create Match from Map (database result)
  factory Match.fromMap(Map<String, dynamic> map) {
    return Match(
      id: map['id'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      team1Player1Id: map['team1Player1Id'],
      team1Player2Id: map['team1Player2Id'],
      team2Player1Id: map['team2Player1Id'],
      team2Player2Id: map['team2Player2Id'],
      team1Score: map['team1Score'],
      team2Score: map['team2Score'],
      winnerTeam: map['winnerTeam'],
      isRatingProcessed: map['isRatingProcessed'] == 1,
    );
  }

  // Create a copy of Match with updated values
  Match copyWith({
    String? id,
    DateTime? date,
    String? team1Player1Id,
    String? team1Player2Id,
    String? team2Player1Id,
    String? team2Player2Id,
    int? team1Score,
    int? team2Score,
    int? winnerTeam,
    bool? isRatingProcessed,
  }) {
    return Match(
      id: id ?? this.id,
      date: date ?? this.date,
      team1Player1Id: team1Player1Id ?? this.team1Player1Id,
      team1Player2Id: team1Player2Id ?? this.team1Player2Id,
      team2Player1Id: team2Player1Id ?? this.team2Player1Id,
      team2Player2Id: team2Player2Id ?? this.team2Player2Id,
      team1Score: team1Score ?? this.team1Score,
      team2Score: team2Score ?? this.team2Score,
      winnerTeam: winnerTeam ?? this.winnerTeam,
      isRatingProcessed: isRatingProcessed ?? this.isRatingProcessed,
    );
  }

  // Helper method to get all player IDs in the match
  List<String> getAllPlayerIds() {
    return [team1Player1Id, team1Player2Id, team2Player1Id, team2Player2Id];
  }

  // Helper method to get team 1 player IDs
  List<String> getTeam1PlayerIds() {
    return [team1Player1Id, team1Player2Id];
  }

  // Helper method to get team 2 player IDs
  List<String> getTeam2PlayerIds() {
    return [team2Player1Id, team2Player2Id];
  }

  // Helper method to determine if a player won this match
  bool didPlayerWin(String playerId) {
    if (winnerTeam == 1) {
      return getTeam1PlayerIds().contains(playerId);
    } else {
      return getTeam2PlayerIds().contains(playerId);
    }
  }

  // Helper method to get opponent player IDs for a given player
  List<String> getOpponentIds(String playerId) {
    if (getTeam1PlayerIds().contains(playerId)) {
      return getTeam2PlayerIds();
    } else {
      return getTeam1PlayerIds();
    }
  }

  @override
  String toString() {
    return 'Match{id: $id, date: $date, team1: [$team1Player1Id, $team1Player2Id], team2: [$team2Player1Id, $team2Player2Id], score: $team1Score-$team2Score, winner: $winnerTeam, processed: $isRatingProcessed}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Match &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          date == other.date &&
          team1Player1Id == other.team1Player1Id &&
          team1Player2Id == other.team1Player2Id &&
          team2Player1Id == other.team2Player1Id &&
          team2Player2Id == other.team2Player2Id &&
          team1Score == other.team1Score &&
          team2Score == other.team2Score &&
          winnerTeam == other.winnerTeam &&
          isRatingProcessed == other.isRatingProcessed;

  @override
  int get hashCode =>
      id.hashCode ^
      date.hashCode ^
      team1Player1Id.hashCode ^
      team1Player2Id.hashCode ^
      team2Player1Id.hashCode ^
      team2Player2Id.hashCode ^
      team1Score.hashCode ^
      team2Score.hashCode ^
      winnerTeam.hashCode ^
      isRatingProcessed.hashCode;
}

