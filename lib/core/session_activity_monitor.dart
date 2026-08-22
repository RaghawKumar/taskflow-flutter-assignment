import 'dart:async';
import 'package:flutter/material.dart';

class InactivityController {
  InactivityController({
    required this.duration,
    required this.onTimeout,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final Duration duration;
  final FutureOr<void> Function() onTimeout;
  final DateTime Function() _now;
  DateTime? _lastActivity;
  Timer? _timer;
  bool _timedOut = false;

  void start() {
    _timedOut = false;
    recordActivity();
  }

  void recordActivity() {
    if (_timedOut) return;
    _lastActivity = _now();
    _timer?.cancel();
    _timer = Timer(duration, _timeout);
  }

  void verifyElapsedTime() {
    final lastActivity = _lastActivity;
    if (_timedOut || lastActivity == null) return;
    if (_now().difference(lastActivity) >= duration) {
      _timeout();
    } else {
      _timer?.cancel();
      _timer = Timer(duration - _now().difference(lastActivity), _timeout);
    }
  }

  void _timeout() {
    if (_timedOut) return;
    _timedOut = true;
    _timer?.cancel();
    onTimeout();
  }

  void dispose() => _timer?.cancel();
}

class SessionActivityMonitor extends StatefulWidget {
  const SessionActivityMonitor({
    super.key,
    required this.onTimeout,
    required this.child,
    this.timeout = const Duration(minutes: 5),
  });

  final FutureOr<void> Function() onTimeout;
  final Widget child;
  final Duration timeout;

  @override
  State<SessionActivityMonitor> createState() => _SessionActivityMonitorState();
}

class _SessionActivityMonitorState extends State<SessionActivityMonitor>
    with WidgetsBindingObserver {
  late InactivityController _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _createController();
  }

  void _createController() {
    _controller = InactivityController(
      duration: widget.timeout,
      onTimeout: widget.onTimeout,
    )..start();
  }

  @override
  void didUpdateWidget(SessionActivityMonitor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.timeout != widget.timeout ||
        oldWidget.onTimeout != widget.onTimeout) {
      _controller.dispose();
      _createController();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _controller.verifyElapsedTime();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: (_) => _controller.recordActivity(),
    onPointerMove: (_) => _controller.recordActivity(),
    child: Focus(
      autofocus: true,
      onKeyEvent: (_, _) {
        _controller.recordActivity();
        return KeyEventResult.ignored;
      },
      child: widget.child,
    ),
  );
}
