import 'package:flutter/material.dart';
import 'package:tapture/core/widgets/app_icons.dart';

import 'dimensions.dart';

/// Gallery of stock Material widgets styled only by [ThemeData]
/// (FE-CONS-03, FE-THEME-07).
class ThemePreview extends StatelessWidget {
  /// Creates the sample screen.
  const ThemePreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme'),
        actions: const <Widget>[
          IconButton(
            tooltip: 'Search',
            onPressed: _ignorePress,
            icon: Icon(AppIcons.search),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(Space.x4),
        children: const <Widget>[
          TextField(decoration: InputDecoration(labelText: 'Name')),
          SizedBox(height: Space.x4),
          Wrap(
            spacing: Space.x2,
            runSpacing: Space.x2,
            children: <Widget>[
              FilledButton(onPressed: _ignorePress, child: Text('Save')),
              OutlinedButton(onPressed: _ignorePress, child: Text('Cancel')),
              TextButton(onPressed: _ignorePress, child: Text('Skip')),
            ],
          ),
          SizedBox(height: Space.x4),
          Wrap(
            spacing: Space.x2,
            runSpacing: Space.x2,
            children: <Widget>[
              Chip(label: Text('Chip')),
              InputChip(label: Text('Filter'), onPressed: _ignorePress),
            ],
          ),
          SizedBox(height: Space.x4),
          Card(
            child: ListTile(
              title: Text('List tile'),
              subtitle: Text('Secondary line'),
            ),
          ),
        ],
      ),
    );
  }
}

void _ignorePress() {}
