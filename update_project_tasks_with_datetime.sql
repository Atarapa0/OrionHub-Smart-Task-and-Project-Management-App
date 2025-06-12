-- Proje görevleri tablosuna tarih ve saat alanları ekle (sadece yoksa)
DO $$ 
BEGIN
    -- due_date sütunu ekle
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='project_tasks' AND column_name='due_date') THEN
        ALTER TABLE project_tasks ADD COLUMN due_date DATE;
    END IF;
    
    -- due_time sütunu ekle
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='project_tasks' AND column_name='due_time') THEN
        ALTER TABLE project_tasks ADD COLUMN due_time TIME;
    END IF;
    
    -- due_datetime sütunu ekle
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='project_tasks' AND column_name='due_datetime') THEN
        ALTER TABLE project_tasks ADD COLUMN due_datetime TIMESTAMP;
    END IF;
    
    -- completed_at sütunu ekle
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='project_tasks' AND column_name='completed_at') THEN
        ALTER TABLE project_tasks ADD COLUMN completed_at TIMESTAMP WITH TIME ZONE;
    END IF;
    
    -- category sütunu ekle
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='project_tasks' AND column_name='category') THEN
        ALTER TABLE project_tasks ADD COLUMN category VARCHAR(100);
    END IF;
END $$;

-- due_datetime'ı otomatik hesaplayan trigger (project_tasks için)
CREATE OR REPLACE FUNCTION update_project_task_due_datetime()
RETURNS TRIGGER AS $$
BEGIN
    -- Eğer due_date ve due_time varsa, bunları birleştir
    IF NEW.due_date IS NOT NULL AND NEW.due_time IS NOT NULL THEN
        NEW.due_datetime = NEW.due_date + NEW.due_time;
    ELSIF NEW.due_date IS NOT NULL THEN
        -- Sadece tarih varsa, saat 23:59 olarak ayarla
        NEW.due_datetime = NEW.due_date + TIME '23:59:00';
    ELSE
        NEW.due_datetime = NULL;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger'ı project_tasks tablosuna ekle (varsa önce sil)
DROP TRIGGER IF EXISTS trigger_update_project_task_due_datetime ON project_tasks;
CREATE TRIGGER trigger_update_project_task_due_datetime
    BEFORE INSERT OR UPDATE ON project_tasks
    FOR EACH ROW
    EXECUTE FUNCTION update_project_task_due_datetime();

-- completed_at'ı otomatik ayarlayan trigger (project_tasks için)
CREATE OR REPLACE FUNCTION update_project_task_completed_at()
RETURNS TRIGGER AS $$
BEGIN
    -- Eğer status 'done' olarak değiştirilirse
    IF NEW.status = 'done' AND (OLD.status IS NULL OR OLD.status != 'done') THEN
        NEW.completed_at = NOW();
    -- Eğer status 'done'dan başka bir şeye değiştirilirse
    ELSIF NEW.status != 'done' AND OLD.status = 'done' THEN
        NEW.completed_at = NULL;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger'ı project_tasks tablosuna ekle (varsa önce sil)
DROP TRIGGER IF EXISTS trigger_update_project_task_completed_at ON project_tasks;
CREATE TRIGGER trigger_update_project_task_completed_at
    BEFORE UPDATE ON project_tasks
    FOR EACH ROW
    EXECUTE FUNCTION update_project_task_completed_at();

-- İndeksler ekle (varsa hata vermesin)
CREATE INDEX IF NOT EXISTS idx_project_tasks_due_datetime ON project_tasks(due_datetime);

-- Mevcut görevlere örnek tarih/saat ekle (isteğe bağlı)
UPDATE project_tasks 
SET due_date = CURRENT_DATE + INTERVAL '7 days',
    due_time = '17:00:00'
WHERE due_date IS NULL;

-- Kontrol et
SELECT 
    id, 
    title, 
    status, 
    priority,
    due_date,
    due_time,
    due_datetime,
    created_at,
    CASE 
        WHEN due_datetime IS NULL THEN 'Tarih belirlenmemiş'
        WHEN due_datetime < NOW() THEN 'Süresi geçmiş (' || 
            EXTRACT(DAY FROM NOW() - due_datetime) || ' gün ' ||
            EXTRACT(HOUR FROM NOW() - due_datetime) || ' saat geçmiş)'
        ELSE 'Kalan süre: ' || 
            EXTRACT(DAY FROM due_datetime - NOW()) || ' gün ' ||
            EXTRACT(HOUR FROM due_datetime - NOW()) || ' saat'
    END as time_status
FROM project_tasks 
ORDER BY due_datetime ASC NULLS LAST; 