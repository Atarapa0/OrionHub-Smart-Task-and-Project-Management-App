// supabase_config.example.dart
// Bu dosyayı kopyalayıp supabase_config.dart olarak yeniden adlandırın
// ve kendi Supabase bilgilerinizle doldurun

import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> initSupabase() async {
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL_HERE',
    anonKey: 'YOUR_SUPABASE_ANON_KEY_HERE',
  );
}

/*
KURULUM TALİMATI:

1. Bu dosyayı kopyalayın ve supabase_config.dart olarak yeniden adlandırın:
   cp lib/core/config/supabase_config.example.dart lib/core/config/supabase_config.dart

2. Supabase projenize gidin (https://supabase.com)

3. Settings > API kısmından aşağıdaki bilgileri alın:
   - Project URL
   - Anon/Public Key

4. supabase_config.dart dosyasındaki placeholder değerleri gerçek değerlerle değiştirin:
   - 'YOUR_SUPABASE_URL_HERE' → Gerçek Project URL
   - 'YOUR_SUPABASE_ANON_KEY_HERE' → Gerçek Anon Key

5. Dosya .gitignore'da olduğu için git'e commit edilmeyecek

NOT: Bu anahtarlar public anahtarlardır ve mobil uygulamada kullanılması güvenlidir.
Gerçek güvenlik Row Level Security (RLS) politikalarıyla sağlanır.
*/
