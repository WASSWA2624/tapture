import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_viewport.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_search_field.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/state_refresh.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

import '../domain/transcript_summary.dart';
import 'transcript_providers.dart';
import 'transcript_tile.dart';

/// The transcript history (spec §30.4.6): every transcript of a project,
/// or of every project from More, newest first, with where each came from,
/// whether it is still recording or was interrupted, and whether it was
/// edited.
///
/// The search matches the title, the edit and the words heard. The list
/// holds one page at a time and asks for the next
/// `AppConstants.transcripts.historyPage` rows when its last row is built.
class TranscriptsScreen extends ConsumerStatefulWidget {
  /// The transcripts of [projectId], or of every project when null.
  const TranscriptsScreen({this.projectId, super.key});

  /// The project listed; null lists every project.
  final String? projectId;

  @override
  ConsumerState<TranscriptsScreen> createState() => _TranscriptsScreenState();
}

class _TranscriptsScreenState extends ConsumerState<TranscriptsScreen>
    with StateRefresh {
  String _query = '';
  int _limit = AppConstants.transcripts.historyPage;
  int _requested = 0;

  /// The rows last shown, kept while a longer page loads so the list does
  /// not flash empty.
  List<TranscriptSummary>? _shown;

  ({String? projectId, String query, int limit}) get _page =>
      (projectId: widget.projectId, query: _query, limit: _limit);

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);
    AsyncValue<List<TranscriptSummary>> rows = ref.watch(
      transcriptHistoryProvider(_page),
    );
    final List<TranscriptSummary>? loaded = rows.value;
    final List<TranscriptSummary>? shown = _shown;
    if (loaded != null) {
      _shown = loaded;
    } else if (rows.isLoading && shown != null) {
      rows = AsyncData<List<TranscriptSummary>>(shown);
    }
    final double gutter = AppPage.gutter(context);
    return AppPage(
      key: const ValueKey<String>('route-transcripts'),
      title: localCopy.transcriptsTitle,
      scrollable: false,
      inset: false,
      actions: <Widget>[
        AppIconButton(
          key: const ValueKey<String>('transcripts-new'),
          icon: AppIcons.add,
          semanticLabel: localCopy.transcriptsNew,
          tooltip: localCopy.transcriptsNew,
          onPressed: _transcribe,
        ),
      ],
      body: AppListViewport(
        header: Padding(
          padding: EdgeInsets.fromLTRB(gutter, Space.x2, gutter, Space.x2),
          child: AppSearchField(
            key: const ValueKey<String>('transcripts-search'),
            hint: localCopy.transcriptsSearchHint,
            text: _query,
            onChanged: _search,
          ),
        ),
        body: AsyncValueView<List<TranscriptSummary>>(
          value: rows,
          onRetry: () => ref.invalidate(transcriptHistoryProvider(_page)),
          isEmpty: (List<TranscriptSummary> found) => found.isEmpty,
          empty: () => AppEmptyState(
            icon: AppIcons.transcript,
            headline: _query.isEmpty
                ? localCopy.transcriptsEmptyHeadline
                : localCopy.transcriptsNoMatchHeadline,
            message: _query.isEmpty
                ? localCopy.transcriptsEmptyMessage
                : localCopy.searchNoMatchMessage,
            actionLabel: localCopy.transcriptsNew,
            onAction: _transcribe,
          ),
          data: (List<TranscriptSummary> found) => ListView.builder(
            key: const ValueKey<String>('transcripts-list'),
            itemCount: found.length,
            itemBuilder: (BuildContext context, int index) {
              if (index == found.length - 1) {
                _nextPageAfter(found.length);
              }
              final TranscriptSummary summary = found[index];
              return TranscriptTile(
                summary: summary,
                showOrigin: true,
                onTap: () => _open(summary.id),
              );
            },
          ),
        ),
      ),
    );
  }

  void _search(String query) {
    refresh(() {
      _query = query.trim();
      _limit = AppConstants.transcripts.historyPage;
      _requested = 0;
      _shown = null;
    });
  }

  /// Asks for the next page once the last row of a full page is built.
  void _nextPageAfter(int count) {
    if (count < _limit || _requested >= _limit) {
      return;
    }
    _requested = _limit;
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted) {
        refresh(() => _limit += AppConstants.transcripts.historyPage);
      }
    });
  }

  void _transcribe() {
    final String? projectId = widget.projectId;
    unawaited(
      context.push(
        projectId == null
            ? RoutePaths.transcribe
            : RoutePaths.projectTranscribe(projectId),
      ),
    );
  }

  void _open(String transcriptId) {
    final String? projectId = widget.projectId;
    unawaited(
      context.push(
        projectId == null
            ? RoutePaths.transcript(transcriptId)
            : RoutePaths.projectTranscript(projectId, transcriptId),
      ),
    );
  }
}
