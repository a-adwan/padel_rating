import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/player.dart';
import '../../data/repositories/player_repository.dart';
import '../../domain/use_cases/player_use_cases.dart';

final playerRepositoryProvider = Provider<PlayerRepository>((ref) {
  return PlayerRepository();
});

final playerUseCasesProvider = Provider<PlayerUseCases>((ref) {
  final repository = ref.watch(playerRepositoryProvider);
  return PlayerUseCases(repository);
});

final playersProvider = StateNotifierProvider<PlayersNotifier, AsyncValue<List<Player>>>((ref) {
  final useCases = ref.watch(playerUseCasesProvider);
  return PlayersNotifier(useCases);
});

class PlayersNotifier extends StateNotifier<AsyncValue<List<Player>>> {
  final PlayerUseCases _playerUseCases;

  PlayersNotifier(this._playerUseCases) : super(const AsyncValue.loading()) {
    loadPlayers();
  }

  Future<void> loadPlayers() async {
    try {
      state = const AsyncValue.loading();
      final players = await _playerUseCases.getPlayers();
      state = AsyncValue.data(players);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addPlayer(String name, double rating, double rd, String side) async {
    try {
      await _playerUseCases.addPlayer(name, rating, rd, side);
      await loadPlayers();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> editPlayer(Player player) async {
    try {
      await _playerUseCases.editPlayer(player);
      await loadPlayers();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deletePlayer(String id) async {
    try {
      await _playerUseCases.deletePlayer(id);
      await loadPlayers();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<Player?> getPlayer(String id) async {
    try {
      return await _playerUseCases.getPlayer(id);
    } catch (error) {
      return null;
    }
  }

  Future<Player?> getPlayerByName(String name) async {
    try {
      return await _playerUseCases.getPlayerByName(name);
    } catch (error) {
      return null;
    }
  }
}

