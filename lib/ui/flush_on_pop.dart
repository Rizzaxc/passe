import 'package:flutter/widgets.dart';

/// Wraps a pushed subroute's content so [onFlush] fires once, fire-and-forget,
/// whenever the screen is left — the header's back arrow, an iOS swipe-back,
/// or the Android system-back gesture alike (a bare back button's `onPress`
/// only covers the first of those). The pop itself is never blocked on
/// [onFlush]: it's called, not awaited — the underlying write handles its own
/// success/failure reporting.
class PFlushOnPop extends StatelessWidget {
  final VoidCallback onFlush;
  final Widget child;

  const PFlushOnPop({super.key, required this.onFlush, required this.child});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) onFlush();
      },
      child: child,
    );
  }
}
