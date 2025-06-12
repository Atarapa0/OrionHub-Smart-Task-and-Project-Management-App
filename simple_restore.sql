-- Basit geri yükleme - tüm sütunları dene
INSERT INTO tasks 
SELECT * FROM tasks_backup 
WHERE id NOT IN (SELECT id FROM tasks);

-- Backup tablosunu sil
DROP TABLE tasks_backup;

-- Kontrol et
SELECT COUNT(*) as task_count FROM tasks;
SELECT id, title, is_completed FROM tasks; 