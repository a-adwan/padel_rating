class Player {
  final String id;
  final String name;
  final double rating;
  final double ratingDeviation;
  final DateTime lastActivityDate;

  Player({
    required this.id,
    required this.name,
    this.rating = 1500.0, // Initial Glicko rating
    this.ratingDeviation = 350.0, // Initial Glicko RD
    required this.lastActivityDate,
  });

  // Convert Player to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'rating': rating,
      'ratingDeviation': ratingDeviation,
      'lastActivityDate': lastActivityDate.millisecondsSinceEpoch,
    };
  }

  // Create Player from Map (database result)
  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      id: map['id'],
      name: map['name'],
      rating: map['rating'],
      ratingDeviation: map['ratingDeviation'],
      lastActivityDate: DateTime.fromMillisecondsSinceEpoch(map['lastActivityDate']),
    );
  }

  // Create a copy of Player with updated values
  Player copyWith({
    String? id,
    String? name,
    double? rating,
    double? ratingDeviation,
    DateTime? lastActivityDate,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      rating: rating ?? this.rating,
      ratingDeviation: ratingDeviation ?? this.ratingDeviation,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
    );
  }

  @override
  String toString() {
    return 'Player{id: $id, name: $name, rating: $rating, ratingDeviation: $ratingDeviation, lastActivityDate: $lastActivityDate}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Player &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          rating == other.rating &&
          ratingDeviation == other.ratingDeviation &&
          lastActivityDate == other.lastActivityDate;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      rating.hashCode ^
      ratingDeviation.hashCode ^
      lastActivityDate.hashCode;
}

