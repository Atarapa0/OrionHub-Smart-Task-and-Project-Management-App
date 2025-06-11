-- Tasks tablosundaki foreign key constraint'i kaldır
-- Manuel kullanıcı sistemi için

-- Önce mevcut constraint'i bul ve kaldır
ALTER TABLE tasks DROP CONSTRAINT IF EXISTS tasks_user_id_fkey;
ALTER TABLE tasks DROP CONSTRAINT IF EXISTS tasks_user_id_fkey1;
ALTER TABLE tasks DROP CONSTRAINT IF EXISTS fk_tasks_user_id;

-- RLS'i de devre dışı bırak
ALTER TABLE tasks DISABLE ROW LEVEL SECURITY;

-- Kontrol için - constraint'leri listele
SELECT 
    tc.constraint_name, 
    tc.table_name, 
    kcu.column_name, 
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name 
FROM 
    information_schema.table_constraints AS tc 
    JOIN information_schema.key_column_usage AS kcu
      ON tc.constraint_name = kcu.constraint_name
    JOIN information_schema.constraint_column_usage AS ccu
      ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' 
    AND tc.table_name='tasks';

-- RLS durumunu kontrol et
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'tasks'; 