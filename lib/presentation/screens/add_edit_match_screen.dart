import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/match.dart';
import '../../data/models/player.dart';
import '../providers/match_provider.dart';
import '../providers/player_provider.dart';

class AddEditMatchScreen extends ConsumerStatefulWidget {
  final Match? match;

  const AddEditMatchScreen({super.key, this.match});

  @override
  ConsumerState<AddEditMatchScreen> createState() => _AddEditMatchScreenState();
}

class _AddEditMatchScreenState extends ConsumerState<AddEditMatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _team1ScoreController = TextEditingController();
  final _team2ScoreController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String? _team1Player1Id;
  String? _team1Player2Id;
  String? _team2Player1Id;
  String? _team2Player2Id;
  int _winnerTeam = 0;

  bool get isEditing => widget.match != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final match = widget.match!;
      _selectedDate = match.date;
      _team1Player1Id = match.team1Player1Id;
      _team1Player2Id = match.team1Player2Id;
      _team2Player1Id = match.team2Player1Id;
      _team2Player2Id = match.team2Player2Id;
      _team1ScoreController.text = match.team1Score.toString();
      _team2ScoreController.text = match.team2Score.toString();
      _winnerTeam = match.winnerTeam;
    }
  }

  @override
  void dispose() {
    _team1ScoreController.dispose();
    _team2ScoreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playersAsyncValue = ref.watch(playersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Match' : 'Add Match'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: playersAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error loading players: $error')),
        data: (players) {
          if (players.length < 4) {
            return const Center(
              child: Text(
                'You need at least 4 players to create a match.\nPlease add more players first.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date Selection
                    Card(
                      child: ListTile(
                        title: const Text('Match Date'),
                        subtitle: Text(_formatDate(_selectedDate)),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: _selectDate,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Team 1
                    const Text(
                      'Team 1',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _buildPlayerDropdown('Team 1 Player 1', _team1Player1Id, players, (value) {
                      setState(() {
                        _team1Player1Id = value;
                      });
                    }),
                    const SizedBox(height: 8),
                    _buildPlayerDropdown('Team 1 Player 2', _team1Player2Id, players, (value) {
                      setState(() {
                        _team1Player2Id = value;
                      });
                    }),
                    const SizedBox(height: 16),

                    // Team 2
                    const Text(
                      'Team 2',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _buildPlayerDropdown('Team 2 Player 1', _team2Player1Id, players, (value) {
                      setState(() {
                        _team2Player1Id = value;
                      });
                    }),
                    const SizedBox(height: 8),
                    _buildPlayerDropdown('Team 2 Player 2', _team2Player2Id, players, (value) {
                      setState(() {
                        _team2Player2Id = value;
                      });
                    }),
                    const SizedBox(height: 16),

                    // Scores
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _team1ScoreController,
                            decoration: const InputDecoration(
                              labelText: 'Team 1 Score',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Enter score';
                              }
                              final score = int.tryParse(value);
                              if (score == null || score < 0) {
                                return 'Invalid score';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _team2ScoreController,
                            decoration: const InputDecoration(
                              labelText: 'Team 2 Score',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Enter score';
                              }
                              final score = int.tryParse(value);
                              if (score == null || score < 0) {
                                return 'Invalid score';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Result
                    Card(
                      child: ListTile(
                        title: Text('Result'),
                        subtitle: Text(
                          getWinnerText(
                            isEditing
                                ? widget.match!
                                : Match(
                                    id: '',
                                    date: _selectedDate,
                                    team1Player1Id: _team1Player1Id ?? '',
                                    team1Player2Id: _team1Player2Id ?? '',
                                    team2Player1Id: _team2Player1Id ?? '',
                                    team2Player2Id: _team2Player2Id ?? '',
                                    team1Score: int.tryParse(_team1ScoreController.text) ?? 0,
                                    team2Score: int.tryParse(_team2ScoreController.text) ?? 0,
                                    winnerTeam: _winnerTeam,
                                    isRatingProcessed: false,
                                  ),
                            players,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveMatch,
                        child: Text(isEditing ? 'Update Match' : 'Add Match'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlayerDropdown(
    String label,
    String? selectedPlayerId,
    List<Player> players,
    Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      value: selectedPlayerId,
      items: players.map((player) {
        return DropdownMenuItem<String>(
          value: player.id,
          child: Text(player.name),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) {
        if (value == null) {
          return 'Please select a player';
        }
        return null;
      },
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _saveMatch() async {
    if (_formKey.currentState!.validate()) {
      // Validate that all players are different
      final playerIds = [_team1Player1Id, _team1Player2Id, _team2Player1Id, _team2Player2Id];
      if (playerIds.toSet().length != 4) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All players must be different')),
        );
        return;
      }

      final team1Score = int.parse(_team1ScoreController.text);
      final team2Score = int.parse(_team2ScoreController.text);

      int winnerTeam;
      if (team1Score > team2Score) {
        winnerTeam = 1;
      } else if (team2Score > team1Score) {
        winnerTeam = 2;
      } else {
        winnerTeam = 0; // Draw
      }

      final match = Match(
        id: isEditing ? widget.match!.id : '',
        date: _selectedDate,
        team1Player1Id: _team1Player1Id!,
        team1Player2Id: _team1Player2Id!,
        team2Player1Id: _team2Player1Id!,
        team2Player2Id: _team2Player2Id!,
        team1Score: team1Score,
        team2Score: team2Score,
        winnerTeam: winnerTeam,
        isRatingProcessed: isEditing ? widget.match!.isRatingProcessed : false,
      );

      if (isEditing) {
        await ref.read(matchesProvider.notifier).editMatch(match);
      } else {
        await ref.read(matchesProvider.notifier).addMatch(match);
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  String getWinnerText(Match match, List<Player> players) {
    if (match.team1Score > match.team2Score) {
      final p1 = players.firstWhere((p) => p.id == match.team1Player1Id, orElse: () => Player(id: '', name: '??', lastActivityDate: DateTime.now()));
      final p2 = players.firstWhere((p) => p.id == match.team1Player2Id, orElse: () => Player(id: '', name: '??', lastActivityDate: DateTime.now()));
      return 'Winner: ${p1.name} & ${p2.name}';
    } else if (match.team2Score > match.team1Score) {
      final p1 = players.firstWhere((p) => p.id == match.team2Player1Id, orElse: () => Player(id: '', name: '??', lastActivityDate: DateTime.now()));
      final p2 = players.firstWhere((p) => p.id == match.team2Player2Id, orElse: () => Player(id: '', name: '??', lastActivityDate: DateTime.now()));
      return 'Winner: ${p1.name} & ${p2.name}';
    } else {
      return 'Draw';
    }
  }
}

