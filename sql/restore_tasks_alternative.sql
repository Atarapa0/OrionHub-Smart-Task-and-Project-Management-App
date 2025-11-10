-- Alternatif yöntem: Tüm sütunları belirterek veri aktarımı
INSERT INTO tasks (id, title, description, is_completed, created_at, updated_at, user_id, priority, due_date, category, completed_at)
SELECT 
    id, 
    title, 
    description, 
    is_completed, 
    created_at, 
    updated_at, 
    user_id, 
    priority, 
    due_date, 
    category,
    COALESCE(completed_at, NULL) as completed_at
FROM tasks_backup;

-- Backup tablosunu sil
DROP TABLE tasks_backup;

-- Kontrol et
SELECT COUNT(*) as task_count FROM tasks;
SELECT id, title, is_completed, completed_at FROM tasks LIMIT 5; 