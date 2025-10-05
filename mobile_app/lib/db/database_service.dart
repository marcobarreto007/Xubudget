// WHY: Conditional export to provide platform-appropriate DatabaseService.
// - On mobile/desktop (non-web): use SQLCipher-backed SQLite storage.
// - On web: use localStorage-backed simple store to allow running in Chrome.

export 'database_service_mobile.dart' if (dart.library.html) 'database_service_web.dart';