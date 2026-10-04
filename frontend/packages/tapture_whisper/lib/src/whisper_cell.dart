part of 'whisper_library.dart';

/// One reference to a reference-counted atomic abort cell.
///
/// A transcription given the cell stops once the cell holds a value of at
/// least its job id. Only [address] crosses isolates: another isolate borrows
/// the cell with `WhisperLibrary.borrowCell`, which takes its own reference,
/// so the cell lives until every reference is closed. A reference nobody
/// closes is released (never freed) when it is garbage collected.
final class WhisperCell implements Finalizable {
  WhisperCell._(this._library, this._cell) {
    _library._bindings.cellFinalizer.attach(
      this,
      _cell.cast<Void>(),
      detach: this,
      externalSize: _externalSize,
    );
  }

  /// The memory pressure one reference reports to the garbage collector.
  static const int _externalSize = 64 * 1024;

  final WhisperLibrary _library;
  final Pointer<Int32> _cell;
  bool _closed = false;

  /// The cell's native address, which another isolate may borrow.
  int get address => _cell.address;

  /// Whether [close] has run.
  bool get isClosed => _closed;

  /// Sets the cell to [value].
  void store(int value) => _library._bindings.cellStore(_open(), value);

  /// The cell's value.
  int load() => _library._bindings.cellLoad(_open());

  /// Releases this reference; later calls throw a [StateError]. Closing
  /// twice does nothing.
  void close() {
    if (_closed) {
      return;
    }
    _closed = true;
    _library._bindings.cellFinalizer.detach(this);
    _library._bindings.cellRelease(_cell);
  }

  Pointer<Int32> _open() {
    if (_closed) {
      throw StateError('the abort cell is closed');
    }
    return _cell;
  }
}
