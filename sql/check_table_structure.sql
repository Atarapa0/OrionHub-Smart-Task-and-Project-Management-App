-- Mevcut tasks tablosunun yapısını kontrol et
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'tasks' 
ORDER BY ordinal_position;

-- Backup tablosunun yapısını kontrol et
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'tasks_backup' 
ORDER BY ordinal_position;

-- Backup'ta kaç kayıt var
SELECT COUNT(*) as backup_count FROM tasks_backup;

-- Backup'taki ilk birkaç kaydı göster
SELECT * FROM tasks_backup LIMIT 3; 