-- Tasks tablosu için RLS'i tamamen devre dışı bırak
ALTER TABLE tasks DISABLE ROW LEVEL SECURITY;

-- Tüm RLS policy'lerini kaldır
DROP POLICY IF EXISTS "Users can view own tasks" ON tasks;
DROP POLICY IF EXISTS "Users can insert own tasks" ON tasks;
DROP POLICY IF EXISTS "Users can update own tasks" ON tasks;
DROP POLICY IF EXISTS "Users can delete own tasks" ON tasks;
DROP POLICY IF EXISTS "Enable read access for own tasks" ON tasks;
DROP POLICY IF EXISTS "Enable insert access for own tasks" ON tasks;
DROP POLICY IF EXISTS "Enable update access for own tasks" ON tasks;
DROP POLICY IF EXISTS "Enable delete access for own tasks" ON tasks;

-- Kontrol için - RLS durumunu göster
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'tasks';

-- Kalan policy'leri göster
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'tasks'; 