class Match {
  final String id;
  final DateTime date;
  final String team1Player1Name;
  final String team1Player2Name;
  final String team2Player1Name;
  final String team2Player2Name;
  final int team1Score;
  final int team2Score;
  final int winnerTeam; // 1 for Team 1, 2 for Team 2, 0 for draw
  final bool isRatingProcessed; // Track if this match has been processed for rating updates

  Match({
    required this.id,
    required this.date,
    required this.team1Player1Name,
    required this.team1Player2Name,
    required this.team2Player1Name,
    required this.team2Player2Name,
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
      'team1Player1Name': team1Player1Name,
      'team1Player2Name': team1Player2Name,
      'team2Player1Name': team2Player1Name,
      'team2Player2Name': team2Player2Name,
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
      team1Player1Name: map['team1Player1Name'],
      team1Player2Name: map['team1Player2Name'],
      team2Player1Name: map['team2Player1Name'],
      team2Player2Name: map['team2Player2Name'],
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
    String? team1Player1Name,
    String? team1Player2Name,
    String? team2Player1Name,
    String? team2Player2Name,
    int? team1Score,
    int? team2Score,
    int? winnerTeam,
    bool? isRatingProcessed,
  }) {
    return Match(
      id: id ?? this.id,
      date: date ?? this.date,
      team1Player1Name: team1Player1Name ?? this.team1Player1Name,
      team1Player2Name: team1Player2Name ?? this.team1Player2Name,
      team2Player1Name: team2Player1Name ?? this.team2Player1Name,
      team2Player2Name: team2Player2Name ?? this.team2Player2Name,
      team1Score: team1Score ?? this.team1Score,
      team2Score: team2Score ?? this.team2Score,
      winnerTeam: winnerTeam ?? this.winnerTeam,
      isRatingProcessed: isRatingProcessed ?? this.isRatingProcessed,
    );
  }

  // Helper method to get all player names in the match
  List<String> getAllPlayerNames() {
    return [team1Player1Name, team1Player2Name, team2Player1Name, team2Player2Name];
  }

  // Helper method to get team 1 player names
  List<String> getTeam1PlayerNames() {
    return [team1Player1Name, team1Player2Name];
  }

  // Helper method to get team 2 player names
  List<String> getTeam2PlayerNames() {
    return [team2Player1Name, team2Player2Name];
  }

  // Helper method to determine if a player won this match
  double didPlayerWin(String playerName) {
    if (winnerTeam == 1) {
      return getTeam1PlayerNames().contains(playerName) ? 1 : 0;
    } else if (winnerTeam == 2) {
      return getTeam2PlayerNames().contains(playerName) ? 1 : 0;
    } else {
      return 0.5; // Match is not won by any team
    }
  }

  // Helper method to get opponent player names for a given player
  List<String> getOpponentNames(String playerName) {
    if (getTeam1PlayerNames().contains(playerName)) {
      return getTeam2PlayerNames();
    } else {
      return getTeam1PlayerNames();
    }
  }

  @override
  String toString() {
    return 'Match{id: $id, date: $date, team1: [$team1Player1Name, $team1Player2Name], team2: [$team2Player1Name, $team2Player2Name], score: $team1Score-$team2Score, winner: $winnerTeam, processed: $isRatingProcessed}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Match &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          date == other.date &&
          team1Player1Name == other.team1Player1Name &&
          team1Player2Name == other.team1Player2Name &&
          team2Player1Name == other.team2Player1Name &&
          team2Player2Name == other.team2Player2Name &&
          team1Score == other.team1Score &&
          team2Score == other.team2Score &&
          winnerTeam == other.winnerTeam &&
          isRatingProcessed == other.isRatingProcessed;

  @override
  int get hashCode =>
      id.hashCode ^
      date.hashCode ^
      team1Player1Name.hashCode ^
      team1Player2Name.hashCode ^
      team2Player1Name.hashCode ^
      team2Player2Name.hashCode ^
      team1Score.hashCode ^
      team2Score.hashCode ^
      winnerTeam.hashCode ^
      isRatingProcessed.hashCode;
}

