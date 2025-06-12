-- Tablo yapılarını kontrol et (SQL ile)
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'tasks' 
ORDER BY ordinal_position;

SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'tasks_backup' 
ORDER BY ordinal_position;

-- Backup tablosunda kaç kayıt var kontrol et
SELECT COUNT(*) as backup_count FROM tasks_backup;

-- Sadece ortak sütunları kullanarak veri aktarımı
INSERT INTO tasks (id, title, description, is_completed, created_at, updated_at, user_id, priority, due_date, category)
SELECT id, title, description, is_completed, created_at, updated_at, user_id, priority, due_date, category
FROM tasks_backup;

-- Backup tablosunu sil
DROP TABLE tasks_backup;

-- Kontrol et
SELECT COUNT(*) as task_count FROM tasks;
SELECT id, title, is_completed FROM tasks LIMIT 5; 