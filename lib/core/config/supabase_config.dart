// supabase_config.dart
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> initSupabase() async {
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL_HERE',
    anonKey: 'YOUR_SUPABASE_ANON_KEY_HERE',
  );
}

// KULLANIM TALİMATI:
// 1. Supabase projenizden URL ve Anon Key'i alın
// 2. Yukarıdaki 'YOUR_SUPABASE_URL_HERE' ve 'YOUR_SUPABASE_ANON_KEY_HERE' 
//    değerlerini gerçek değerlerle değiştirin
// 3. Bu dosya .gitignore'da olduğu için değişiklikleriniz commit edilmeyecek