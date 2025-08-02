import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/player.dart';
import '../providers/player_provider.dart';
import 'add_edit_player_screen.dart';
import 'player_detail_screen.dart';

class SortSettings {
  final String column;
  final bool ascending;

  SortSettings({required this.column, required this.ascending});

  SortSettings copyWith({String? column, bool? ascending}) {
    return SortSettings(
      column: column ?? this.column,
      ascending: ascending ?? this.ascending,
    );
  }
}

final sortProvider = StateProvider<SortSettings>((ref) {
  return SortSettings(column: 'name', ascending: true);
});

class PlayerListScreen extends ConsumerWidget {
  const PlayerListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playersAsyncValue = ref.watch(playersProvider);
    final sortSettings = ref.watch(sortProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Players'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: playersAsyncValue.when(
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
                onPressed: () =>
                    ref.read(playersProvider.notifier).loadPlayers(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (players) {
          if (players.isEmpty) {
            return const Center(
              child: Text(
                'No players added yet.\nTap the + button to add a player.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final sortedPlayers = List<Player>.from(players)
            ..sort((a, b) {
              switch (sortSettings.column) {
                case 'name':
                  final compare = a.name.compareTo(b.name);
                  return sortSettings.ascending ? compare : -compare;
                case 'rating':
                  final compare = a.rating.compareTo(b.rating);
                  return sortSettings.ascending ? compare : -compare;
                case 'lastActive':
                  final compare =
                      a.lastActivityDate.compareTo(b.lastActivityDate);
                  return sortSettings.ascending ? compare : -compare;
                default:
                  return 0;
              }
            });
          return Column(children: [
            _buildSortControls(context, ref),
            Expanded(
                child: ListView.builder(
                  itemCount: sortedPlayers.length + 1,
                  itemBuilder: (context, index) {
                    if (index < sortedPlayers.length) {
                      final player = sortedPlayers[index];
                      return _buildPlayerCard(context, ref, player);
                    } else {
                      return const SizedBox(height: 72); // Spacer at the end
                    }
                  },
                ),
              ),
            ]
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddEditPlayerScreen(),
            ),
          );
        },
        tooltip: 'Add Player',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSortControls(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(60),
            spreadRadius: 2,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Dropdown for sort column
          DropdownButton<String>(
            value: ref.watch(sortProvider).column,
            elevation: 16,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
            ),
            icon: const Icon(Icons.arrow_drop_down),
            items: [
              DropdownMenuItem(value: 'name', child: Text('Name')),
              DropdownMenuItem(value: 'rating', child: Text('Rating')),
              DropdownMenuItem(value: 'lastActive', child: Text('Last Active')),
            ],
            onChanged: (String? newValue) {
              if (newValue != null) {
                ref
                    .read(sortProvider.notifier)
                    .update((state) => state.copyWith(column: newValue));
              }
            },
          ),

          // Sort order toggle
          Row(
            children: [
              IconButton(
                onPressed: () {
                  ref.read(sortProvider.notifier).update(
                      (state) => state.copyWith(ascending: !state.ascending));
                },
                icon: Icon(
                  ref.watch(sortProvider).ascending ? Icons.arrow_upward_outlined : Icons.arrow_downward_outlined,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(BuildContext context, WidgetRef ref, Player player) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        title: Text(
          player.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Side: ${player.side}'),
            Text('Rating: ${player.rating.toStringAsFixed(0)}'),
            Text('RD: ${player.ratingDeviation.toStringAsFixed(1)}'),
            Text('Last Active: ${_formatDate(player.lastActivityDate)}'),
            Text('Last Rating Change: ${player.ratingChange.toStringAsFixed(0)}'),
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
                    builder: (context) => AddEditPlayerScreen(player: player),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showDeleteDialog(context, ref, player.id, player.name),
            ),
          ],
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PlayerDetailScreen(playerId: player.id),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showDeleteDialog(
      BuildContext context, WidgetRef ref, String playerId, String playerName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Player'),
          content: Text('Are you sure you want to delete $playerName?'),
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
                ref.read(playersProvider.notifier).deletePlayer(playerId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
