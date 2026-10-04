import 'package:flutter/material.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/security/untrusted_text.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_card.dart';
import 'package:tapture/core/widgets/app_icons.dart';

/// A transcript pane: settled paragraphs, then the words still being
/// recognised.
///
/// Settled text can be selected; [tentative] text is muted, italic and not
/// announced, because it may still change. Every line is shown through
/// [UntrustedText] (FE-SEC-05).
///
/// While [live], the pane follows the newest line whenever the reader is at
/// the end, jumping without animation so reduced motion holds. Once the
/// reader scrolls up it stays where they are and offers a jump back to the
/// newest words. Appending text rebuilds only the last row, so a long
/// transcript stays smooth.
///
/// The pane fills a bounded parent; under an unbounded one it is
/// [Sizes.transcriptPane] tall.
class AppTranscriptView extends StatefulWidget {
  /// Creates a transcript pane over [paragraphs].
  const AppTranscriptView({
    required this.paragraphs,
    this.tentative,
    this.live = false,
    this.emptyMessage,
    super.key,
  });

  /// Settled paragraphs, oldest first.
  final List<String> paragraphs;

  /// Words still being recognised, after the last paragraph. Null or empty
  /// shows none.
  final String? tentative;

  /// Whether text is still arriving, so the pane follows the newest line.
  final bool live;

  /// Shown before any text. Defaults to the live transcript prompt.
  final String? emptyMessage;

  @override
  State<AppTranscriptView> createState() => _AppTranscriptViewState();
}

class _AppTranscriptViewState extends State<AppTranscriptView> {
  final ScrollController _scroll = ScrollController();

  /// Built rows by index, reused while their text is unchanged so a parent
  /// rebuild does not rebuild them.
  final List<Widget> _rows = <Widget>[];
  final List<String> _texts = <String>[];

  bool _following = true;
  bool _followScheduled = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    if (widget.live) {
      _scheduleFollow();
    }
  }

  @override
  void didUpdateWidget(AppTranscriptView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.paragraphs.length < _texts.length) {
      _rows.length = widget.paragraphs.length;
      _texts.length = widget.paragraphs.length;
    }
    if (widget.live && _following) {
      _scheduleFollow();
    }
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    final bool atEnd = _scroll.position.extentAfter <= Space.x8;
    if (atEnd != _following) {
      setState(() => _following = atEnd);
    }
  }

  /// Jumps to the end after layout. Rows are laid out lazily, so the end can
  /// grow once the new rows are measured; the jump repeats until it holds.
  void _scheduleFollow([int attempts = _followAttempts]) {
    if (_followScheduled) {
      return;
    }
    _followScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      _followScheduled = false;
      if (!mounted || !_scroll.hasClients || !_following) {
        return;
      }
      final ScrollPosition position = _scroll.position;
      if (position.pixels < position.maxScrollExtent) {
        position.jumpTo(position.maxScrollExtent);
        if (attempts > 1) {
          _scheduleFollow(attempts - 1);
        }
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _jumpToLatest() {
    setState(() => _following = true);
    _scheduleFollow();
  }

  Widget _row(int index) {
    final String text = widget.paragraphs[index];
    if (index < _texts.length && _texts[index] == text) {
      return _rows[index];
    }
    final Widget row = _StableRow(
      key: ValueKey<String>('transcript-row-$index'),
      text: text,
    );
    if (index < _texts.length) {
      _texts[index] = text;
      _rows[index] = row;
    } else if (index == _texts.length) {
      _texts.add(text);
      _rows.add(row);
    }
    return row;
  }

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);
    final String tentative = widget.tentative ?? '';
    final int stable = widget.paragraphs.length;
    final int count = stable + (tentative.isEmpty ? 0 : 1);
    final Widget body = count == 0
        ? Padding(
            padding: const EdgeInsets.all(Space.x3),
            child: Text(
              widget.emptyMessage ?? localCopy.liveTranscriptEmpty,
              key: const ValueKey<String>('transcript-empty'),
              style: AppText.body.copyWith(
                color: context.colors.onSurfaceMuted,
              ),
            ),
          )
        : SelectionArea(
            child: ListView.builder(
              key: const ValueKey<String>('transcript-list'),
              controller: _scroll,
              padding: const EdgeInsets.all(Space.x3),
              itemCount: count,
              itemBuilder: (BuildContext context, int index) {
                if (index < stable) {
                  return _row(index);
                }
                return _TentativeRow(text: tentative);
              },
            ),
          );
    final bool offerJump = widget.live && !_following && count > 0;
    final Widget pane = AppCard(
      padding: EdgeInsets.zero,
      child: Stack(
        children: <Widget>[
          Positioned.fill(child: body),
          if (offerJump)
            PositionedDirectional(
              start: Space.x2,
              end: Space.x2,
              bottom: Space.x2,
              child: Center(
                child: AppButton(
                  key: const ValueKey<String>('transcript-jump-to-latest'),
                  label: localCopy.liveTranscriptJumpToLatest,
                  icon: AppIcons.moveDown,
                  onPressed: _jumpToLatest,
                ),
              ),
            ),
        ],
      ),
    );
    return Semantics(
      container: true,
      label: localCopy.transcriptViewLabel,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          if (constraints.hasBoundedHeight) {
            return pane;
          }
          return SizedBox(height: Sizes.transcriptPane, child: pane);
        },
      ),
    );
  }

  static const int _followAttempts = 3;
}

/// A settled paragraph. It reads the theme itself, so a cached row still
/// follows a change of theme.
class _StableRow extends StatelessWidget {
  const _StableRow({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.x3),
      child: Text(
        UntrustedText(text).forDisplay(),
        style: AppText.body.copyWith(color: context.colors.onSurface),
      ),
    );
  }
}

/// Words still being recognised: muted, italic, not selectable and not
/// announced, because they may change.
class _TentativeRow extends StatelessWidget {
  const _TentativeRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SelectionContainer.disabled(
        child: Text(
          UntrustedText(text).forDisplay(),
          key: const ValueKey<String>('transcript-tentative'),
          style: AppText.body.copyWith(
            color: context.colors.onSurfaceMuted,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}
