library;

import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toastification/toastification.dart';

final supabase = Supabase.instance.client;

const genericErrorMessage = 'Something happened. Please try again.';

extension ContextExtension on BuildContext {
  void showToast(String message,
      {ToastificationType type = ToastificationType.success}) {
    toastification.show(
      margin: const EdgeInsets.fromLTRB(16, 48, 16, 8),
      type: type,
      style: ToastificationStyle.fillColored,
      autoCloseDuration: const Duration(seconds: 3),
      description: Text(message),
      showProgressBar: false,
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

}