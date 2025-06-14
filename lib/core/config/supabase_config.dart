// supabase_config.dart
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> initSupabase() async {
  await Supabase.initialize(
    url: 'https://mrqzmcuyizajvwkcefpt.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1ycXptY3V5aXphanZ3a2NlZnB0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg1MzE2NDEsImV4cCI6MjA2NDEwNzY0MX0.D6gchkwk9R6Renj4zR5vbZ0uv6vcPI5mi0lrgnxfZP0',
  );
}
