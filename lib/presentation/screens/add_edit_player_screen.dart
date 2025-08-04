import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/player.dart';
import '../providers/player_provider.dart';

class AddEditPlayerScreen extends ConsumerStatefulWidget {
  final Player? player;

  const AddEditPlayerScreen({super.key, this.player});

  @override
  ConsumerState<AddEditPlayerScreen> createState() => _AddEditPlayerScreenState();
}

class _AddEditPlayerScreenState extends ConsumerState<AddEditPlayerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ratingController = TextEditingController();
  final _rdController = TextEditingController();
  String? _sideController;

  bool get isEditing => widget.player != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _nameController.text = widget.player!.name;
      _ratingController.text = widget.player!.rating.toString();
      _rdController.text = widget.player!.ratingDeviation.toString();
      _sideController = widget.player!.side;
    } else {
      _ratingController.text = '1500';
      _rdController.text = '350';
      _sideController = 'Both';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ratingController.dispose();
    _rdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Player' : 'Add Player'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Player Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a player name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ratingController,
                decoration: const InputDecoration(
                  labelText: 'Rating',
                  border: OutlineInputBorder(),
                  helperText: 'Initial rating (default: 1500)',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a rating';
                  }
                  final rating = double.tryParse(value);
                  if (rating == null || rating < 0) {
                    return 'Please enter a valid rating';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _rdController,
                decoration: const InputDecoration(
                  labelText: 'Rating Deviation (RD)',
                  border: OutlineInputBorder(),
                  helperText: 'Rating uncertainty (default: 350)',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a rating deviation';
                  }
                  final rd = double.tryParse(value);
                  if (rd == null || rd < 0) {
                    return 'Please enter a valid rating deviation';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _sideController,
                decoration: const InputDecoration(
                  labelText: 'Preferred Side',
                  border: OutlineInputBorder(),
                ),
                items: ['Both', 'Left', 'Right']
                    .map((side) => DropdownMenuItem(
                          value: side,
                          child: Text(side),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _sideController = value!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a preferred side';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _savePlayer,
                  child: Text(isEditing ? 'Update Player' : 'Add Player'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _savePlayer() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final rating = double.parse(_ratingController.text);
      final rd = double.parse(_rdController.text);
      final side = _sideController ?? 'Both';

      if (isEditing) {
        final updatedPlayer = widget.player!.copyWith(
          name: name,
          rating: rating,
          ratingDeviation: rd,
          side: side,
        );
        await ref.read(playersProvider.notifier).editPlayer(updatedPlayer);
      } else {
        await ref.read(playersProvider.notifier).addPlayer(name, side);
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }
}

