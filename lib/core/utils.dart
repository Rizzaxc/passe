library;


import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

const genericErrorMessage = 'Something happened. Please try again.';



extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

}