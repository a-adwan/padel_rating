class Player {
  final String id;
  final String name;
  final String side;
  final double rating;
  final double ratingDeviation;
  final DateTime lastActivityDate;
  final double ratingChange;

  Player({
    required this.id,
    required this.name,
    required this.side,
    this.rating = 1500.0,
    this.ratingDeviation = 350.0,
    DateTime? lastActivityDate, // Make nullable
    this.ratingChange = 0.0,
  }) : lastActivityDate = lastActivityDate ?? DateTime.fromMicrosecondsSinceEpoch(0);

  // Convert Player to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'side': side,
      'rating': rating,
      'ratingDeviation': ratingDeviation,
      'lastActivityDate': lastActivityDate.millisecondsSinceEpoch,
      'ratingChange': ratingChange,
    };
  }

  // Create Player from Map (database result)
  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      id: map['id'],
      name: map['name'],
      side: map['side'],
      rating: map['rating'],
      ratingDeviation: map['ratingDeviation'],
      lastActivityDate: DateTime.fromMillisecondsSinceEpoch(map['lastActivityDate']),
      ratingChange: map['ratingChange']
    );
  }

  // Create a copy of Player with updated values
  Player copyWith({
    String? id,
    String? name,
    String? side,
    double? rating,
    double? ratingDeviation,
    DateTime? lastActivityDate,
    double? ratingChange,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      side: side ?? this.side,
      rating: rating ?? this.rating,
      ratingDeviation: ratingDeviation ?? this.ratingDeviation,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
      ratingChange: ratingChange ?? this.ratingChange,
    );
  }

  @override
  String toString() {
    return 'Player{id: $id, name: $name, rating: $rating, side:$side, ratingDeviation: $ratingDeviation, lastActivityDate: $lastActivityDate, ratingChange: $ratingChange}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Player &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          side == other.side &&
          name == other.name &&
          rating == other.rating &&
          ratingDeviation == other.ratingDeviation &&
          lastActivityDate == other.lastActivityDate &&
          ratingChange == other.ratingChange;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      side.hashCode ^
      rating.hashCode ^
      ratingDeviation.hashCode ^
      lastActivityDate.hashCode ^
      ratingChange.hashCode;
}

