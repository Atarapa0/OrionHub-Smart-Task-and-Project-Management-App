-- Tasks tablosu için RLS'i devre dışı bırak
-- Manuel kullanıcı sistemi için basit çözüm

-- RLS'i devre dışı bırak
ALTER TABLE tasks DISABLE ROW LEVEL SECURITY;

-- Kontrol için - RLS durumunu kontrol et
SELECT schemaname, tablename, rowsecurity, forcerowsecurity 
FROM pg_tables 
WHERE tablename = 'tasks';

-- Mevcut politikaları listele (varsa)
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'tasks'; 