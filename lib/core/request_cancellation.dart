class CancellationToken {
  bool _cancelled = false;
  bool get isCancelled => _cancelled;
  void cancel() => _cancelled = true;
  void throwIfCancelled() {
    if (_cancelled) throw const RequestCancelledException();
  }
}

class RequestCancelledException implements Exception {
  const RequestCancelledException();
  @override
  String toString() => 'Request cancelled';
}
