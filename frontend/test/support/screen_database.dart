/// Isolated real SQLite connections for screen verification on each platform.
library;

export 'screen_database_stub.dart'
    if (dart.library.js_interop) 'screen_database_web.dart'
    show createScreenDatabase;
