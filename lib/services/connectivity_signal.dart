import 'dart:async';

class ConnectivitySignal {
  ConnectivitySignal._();

  static final ValueStream<bool> onlineStream = ValueStream<bool>();

  static bool _isOnline = true;
  static bool get isOnline => _isOnline;

  static void setOnline(bool value) {
    if (_isOnline == value) return;
    _isOnline = value;
    onlineStream.add(value);
  }
}

class ValueStream<T> {
  final _controller = StreamController<T>.broadcast();

  Stream<T> get stream => _controller.stream;

  void add(T value) {
    if (!_controller.isClosed) {
      _controller.add(value);
    }
  }
}
