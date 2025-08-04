import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/match_provider.dart';
import '../providers/player_provider.dart';
import 'add_edit_match_screen.dart';
import 'package:intl/intl.dart';

class MatchListScreen extends ConsumerWidget {
  const MatchListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsyncValue = ref.watch(matchesProvider);
    final playersAsyncValue = ref.watch(playersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Matches'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: matchesAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(matchesProvider.notifier).loadMatches(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (matches) {
          if (matches.isEmpty) {
            return const Center(
              child: Text(
                'No matches recorded yet.\nTap the + button to add a match.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return playersAsyncValue.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(child: Text('Error loading players: $error')),
            data: (players) => ListView.builder(
              itemCount: matches.length,
              itemBuilder: (context, index) {
                final match = matches[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    title: Text(
                      _formatMatchTitle(match, players),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Date: ${_formatDate(match.date)}'),
                        Text('Score: ${match.team1Score} - ${match.team2Score}'),
                        Text('Winner: ${match.winnerTeam == 1 ? 'Team 1' : match.winnerTeam == 2 ? 'Team 2' : 'Draw'}'),
                        if (match.isRatingProcessed)
                          const Text(
                            'Rating Processed',
                            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => AddEditMatchScreen(match: match),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _showDeleteDialog(context, ref, match.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddEditMatchScreen(),
            ),
          );
        },
        tooltip: 'Add Match',
        child: const Icon(Icons.add),
      ),
    );
  }

  static String _formatMatchTitle(dynamic match, List<dynamic> players) {
    String getPlayerName(String name) {
      final player = players.cast<dynamic>().firstWhere(
        (p) => p.name == name,
        orElse: () => null,
      );
      return player?.name ?? 'Unknown';
    }

    final team1Player1 = getPlayerName(match.team1Player1Name);
    final team1Player2 = getPlayerName(match.team1Player2Name);
    final team2Player1 = getPlayerName(match.team2Player1Name);
    final team2Player2 = getPlayerName(match.team2Player2Name);

    return '$team1Player1 & $team1Player2 vs $team2Player1 & $team2Player2';
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }
  Future<void> _showDeleteDialog(BuildContext context, WidgetRef ref, String matchId) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Match'),
          content: const Text('Are you sure you want to delete this match?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                ref.read(matchesProvider.notifier).deleteMatch(matchId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}


