/// Kinds of auth events emitted by ClerkBridge.
enum ClerkBridgeEventType { signedIn, initialSession, signedOut, error }

/// A single auth event from the Clerk side of the app.
class ClerkBridgeEvent {
  const ClerkBridgeEvent(this.type, {this.userId, this.message});

  final ClerkBridgeEventType type;
  final String? userId;
  final String? message;
}
