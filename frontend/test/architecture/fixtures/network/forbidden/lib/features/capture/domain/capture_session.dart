import 'dart:io';

/// A domain type that holds a network client.
class CaptureSession {
  CaptureSession(this.client);

  final HttpClient client;
}
