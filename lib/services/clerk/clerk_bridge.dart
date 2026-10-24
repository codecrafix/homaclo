// Web builds get the no-op stub (the website has its own Clerk JS);
// Android/iOS builds get the real Clerk implementation.
export 'clerk_types.dart';
export 'clerk_bridge_stub.dart'
    if (dart.library.io) 'clerk_bridge_mobile.dart';
