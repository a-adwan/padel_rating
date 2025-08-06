import 'package:uuid/uuid.dart';

import '../../data/models/player.dart';
import '../../data/repositories/player_repository.dart';

class PlayerUseCases {
  final PlayerRepository _playerRepository;
  final Uuid _uuid = const Uuid();

  PlayerUseCases(this._playerRepository);

  Future<void> addPlayer(String name, double rating, double rd, String side) async {
    final player = Player(
      id: _uuid.v4(),
      name: name,
      rating: rating,
      ratingDeviation: rd,
      side: side,
      lastActivityDate: DateTime.fromMicrosecondsSinceEpoch(0),
    );
    await _playerRepository.addPlayer(player);
  }

  Future<void> editPlayer(Player player) async {
    await _playerRepository.updatePlayer(player);
  }

  Future<List<Player>> getPlayers() async {
    return await _playerRepository.getAllPlayers();
  }

  Future<Player?> getPlayer(String id) async {
    return await _playerRepository.getPlayer(id);
  }

  Future<Player?> getPlayerByName(String name) async {
    return await _playerRepository.getPlayerByName(name);
  }

  Future<Player?> getOrAddPlayerByName(String name) async {
    return await _playerRepository.getOrAddPlayerByName(name);
  }

  Future<void> deletePlayer(String id) async {
    await _playerRepository.deletePlayer(id);
  }

  Future<List<Player>> getPlayersWithInactivity(DateTime cutoffDate) async {
    return await _playerRepository.getPlayersWithInactivity(cutoffDate);
  }

  Future<void> updatePlayerRating(String playerId, double newRating, double newRatingDeviation) async {
    await _playerRepository.updatePlayerRating(playerId, newRating, newRatingDeviation);
  }

  Future<List<Player>> getPlayersByIds(List<String> playerIds) async {
    return await _playerRepository.getPlayersByIds(playerIds);
  }

  Future<bool> playerExists(String id) async {
    return await _playerRepository.playerExists(id);
  }

  Future<int> getPlayerCount() async {
    return await _playerRepository.getPlayerCount();
  }
}

