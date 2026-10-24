import 'package:http/http.dart' as http;

typedef ClerkTokenProvider = Future<String?> Function();

/// HTTP client for Supabase that swaps in the Clerk session token on data
/// requests (rest, storage, functions) while a Clerk session is active.
/// Email-OTP auth calls (/auth/v1) are never touched.
class ClerkTokenHttpClient extends http.BaseClient {
  ClerkTokenHttpClient(this._tokenProvider, [http.Client? inner])
    : _inner = inner ?? http.Client();

  final ClerkTokenProvider _tokenProvider;
  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (!request.url.path.startsWith('/auth/v1')) {
      final token = await _tokenProvider();
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
    }
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
