import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../router.dart';

/// True for connectivity-shaped failures (offline, DNS, our own 5s
/// `.timeout()`) — the app is mostly unusable offline anyway, so callers
/// should just leave the optimistic value in place rather than toast/resync.
bool isNetworkError(Object error) =>
    error is TimeoutException || error is SocketException;

/// Shared failure path for write-through profile field writes (every write
/// is now optimistic and fire-and-forget, so there's no single call site
/// left to catch a failure and react to it the way the old commit button
/// did). On a real (non-network) failure: logs via [Talker], shows a
/// destructive toast fired off the root navigator — the screen that
/// triggered the write may already be gone by the time it fails — and calls
/// [resync] so the UI can re-fetch and self-correct. Debounced per instance
/// so a burst of failures on the same field collapses into one toast + one
/// resync instead of one per write.
class WriteFailureHandler {
  WriteFailureHandler(
    this._ref, {
    this.debounce = const Duration(milliseconds: 400),
  });

  final Ref _ref;
  final Duration debounce;
  final _talker = Talker();
  Timer? _pending;

  void handle(
    Object error,
    StackTrace stackTrace, {
    required String logMessage,
    required VoidCallback resync,
  }) {
    _talker.handle(error, stackTrace, logMessage);
    if (isNetworkError(error)) return;

    _pending?.cancel();
    _pending = Timer(debounce, () {
      resync();
      _toast();
    });
  }

  void dispose() => _pending?.cancel();

  void _toast() {
    final context = _ref
        .read(routerProvider)
        .routerDelegate
        .navigatorKey
        .currentContext;
    if (context == null || !context.mounted) return;
    showFToast(
      context: context,
      icon: const Icon(FLucideIcons.circleX),
      variant: .destructive,
      title: Text('error'.tr()),
      description: Text('errorGeneric'.tr()),
      alignment: .bottomCenter,
    );
  }
}
