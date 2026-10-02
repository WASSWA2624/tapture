import 'package:flutter/material.dart';
import 'package:tapture/core/copy/copy.dart';
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
        title: Text(Copy.of(context).galleryTheme),
        actions: <Widget>[
          IconButton(
            tooltip: Copy.of(context).search,
            onPressed: _ignorePress,
            icon: const Icon(AppIcons.search),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(Space.x4),
        children: <Widget>[
          TextField(
            decoration: InputDecoration(
              labelText: Copy.of(context).gallerySampleName,
            ),
          ),
          const SizedBox(height: Space.x4),
          Wrap(
            spacing: Space.x2,
            runSpacing: Space.x2,
            children: <Widget>[
              FilledButton(
                onPressed: _ignorePress,
                child: Text(Copy.of(context).save),
              ),
              OutlinedButton(
                onPressed: _ignorePress,
                child: Text(Copy.of(context).cancel),
              ),
              TextButton(
                onPressed: _ignorePress,
                child: Text(Copy.of(context).reviewSkip),
              ),
            ],
          ),
          const SizedBox(height: Space.x4),
          Wrap(
            spacing: Space.x2,
            runSpacing: Space.x2,
            children: <Widget>[
              Chip(label: Text(Copy.of(context).gallerySampleChip)),
              InputChip(
                label: Text(Copy.of(context).gallerySampleFilter),
                onPressed: _ignorePress,
              ),
            ],
          ),
          const SizedBox(height: Space.x4),
          Card(
            child: ListTile(
              title: Text(Copy.of(context).gallerySampleListTile),
              subtitle: Text(Copy.of(context).gallerySampleSecondaryLine),
            ),
          ),
        ],
      ),
    );
  }
}

void _ignorePress() {}
