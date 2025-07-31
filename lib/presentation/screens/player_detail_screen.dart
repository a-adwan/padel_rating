import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/player_provider.dart';
import '../providers/match_provider.dart';

class PlayerDetailScreen extends ConsumerWidget {
  final String playerId;

  const PlayerDetailScreen({super.key, required this.playerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Player Details'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: FutureBuilder(
        future: Future.wait([
          ref.read(playersProvider.notifier).getPlayer(playerId),
          ref.read(matchesProvider.notifier).getMatchesForPlayer(playerId),
        ]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final player = snapshot.data?[0];
          final matches = snapshot.data?[1] ?? [];

          if (player == null) {
            return const Center(
              child: Text('Player not found'),
            );
          }

          final validMatches = matches
              .where((match) => match != null && match.didPlayerWin != null && match.didPlayerWin(playerId) != null)
              .toList();
          final wins = validMatches.where((match) => match.didPlayerWin(playerId) == true).length;
          final losses = validMatches.length - wins;
          final winPercentage = validMatches.isEmpty ? 0.0 : (wins / validMatches.length) * 100;

          return Consumer(
            builder: (context, ref, child) {
              final playersAsyncValue = ref.watch(playersProvider);
              
              return playersAsyncValue.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Center(child: Text('Error: $error')),
                data: (allPlayers) => Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Player Stats Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                player.name,
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Rating', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                        Text(
                                          player.rating.toStringAsFixed(0),
                                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Rating Deviation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                        Text(
                                          player.ratingDeviation.toStringAsFixed(1),
                                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.orange),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text('Last Active: ${_formatDate(player.lastActivityDate)}'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Match Statistics Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Match Statistics',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Text(
                                          matches.length.toString(),
                                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                        ),
                                        const Text('Total Matches'),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Text(
                                          wins.toString(),
                                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                                        ),
                                        const Text('Wins'),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Text(
                                          losses.toString(),
                                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
                                        ),
                                        const Text('Losses'),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Text(
                                          '${winPercentage.toStringAsFixed(1)}%',
                                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
                                        ),
                                        const Text('Win Rate'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Recent Matches
                      const Text(
                        'Recent Matches',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: matches.isEmpty
                            ? const Center(
                                child: Text('No matches played yet'),
                              )
                            : ListView.builder(
                                itemCount: matches.length,
                                itemBuilder: (context, index) {
                                  final match = matches[index];
                                  final isWin = match.didPlayerWin(playerId);
                                  
                                  return Card(
                                    child: ListTile(
                                      title: Text(_formatMatchTitle(match, allPlayers, playerId)),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Date: ${_formatDate(match.date)}'),
                                          Text('Score: ${match.team1Score} - ${match.team2Score}'),
                                        ],
                                      ),
                                      trailing: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isWin ? Colors.green : Colors.red,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          isWin ? 'WIN' : 'LOSS',
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatMatchTitle(match, allPlayers, String currentPlayerId) {
    String getPlayerName(String id) {
      final player = allPlayers.cast<dynamic>().firstWhere(
        (p) => p.id == id,
        orElse: () => null,
      );
      if (player == null) return 'Unknown';
      return player.name;
    }

    final team1Player1 = getPlayerName(match.team1Player1Id);
    final team1Player2 = getPlayerName(match.team1Player2Id);
    final team2Player1 = getPlayerName(match.team2Player1Id);
    final team2Player2 = getPlayerName(match.team2Player2Id);

    final isOnTeam1 = match.getTeam1PlayerIds().contains(currentPlayerId);

    if (isOnTeam1) {
      final partner = match.team1Player1Id == currentPlayerId ? team1Player2 : team1Player1;
      return 'With $partner vs $team2Player1 & $team2Player2';
    } else {
      final partner = match.team2Player1Id == currentPlayerId ? team2Player2 : team2Player1;
      return 'With $partner vs $team1Player1 & $team1Player2';
    }
  }
}