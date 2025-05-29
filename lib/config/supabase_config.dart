import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String url = 'https://phroccglswebelbqalpy.supabase.co';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBocm9jY2dsc3dlYmVsYnFhbHB5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzE4NDQ1MzMsImV4cCI6MjA0NzQyMDUzM30.5WNyVkLDXAL4Jo0Mh2uBc1p8TOely3wT7VUE9itxn64';

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }
} 