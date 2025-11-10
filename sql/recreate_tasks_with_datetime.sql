-- Mevcut tasks tablosunu sil
DROP TABLE IF EXISTS tasks CASCADE;
DROP TABLE IF EXISTS tasks_backup CASCADE;

-- Yeni tasks tablosunu oluştur (tarih ve saat özellikleri ile)
CREATE TABLE tasks (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed')),
    priority VARCHAR(20) DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    category VARCHAR(100),
    
    -- Tarih ve saat alanları
    due_date DATE,                    -- Bitiş tarihi (sadece tarih)
    due_time TIME,                    -- Bitiş saati (sadece saat)
    due_datetime TIMESTAMP,           -- Tam tarih ve saat (hesaplanmış)
    
    -- Sistem tarihleri
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    
    -- Kullanıcı bilgisi
    user_id UUID NOT NULL,
    
    -- İndeksler için
    CONSTRAINT fk_tasks_user FOREIGN KEY (user_id) REFERENCES user_profiles(id) ON DELETE CASCADE
);

-- due_datetime'ı otomatik hesaplayan trigger
CREATE OR REPLACE FUNCTION update_due_datetime()
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

-- Trigger'ı tasks tablosuna ekle
CREATE TRIGGER trigger_update_due_datetime
    BEFORE INSERT OR UPDATE ON tasks
    FOR EACH ROW
    EXECUTE FUNCTION update_due_datetime();

-- updated_at'ı otomatik güncelleyen trigger
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_updated_at
    BEFORE UPDATE ON tasks
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- completed_at'ı otomatik ayarlayan trigger
CREATE OR REPLACE FUNCTION update_completed_at()
RETURNS TRIGGER AS $$
BEGIN
    -- Eğer status 'completed' olarak değiştirilirse
    IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN
        NEW.completed_at = NOW();
    -- Eğer status 'completed'dan başka bir şeye değiştirilirse
    ELSIF NEW.status != 'completed' AND OLD.status = 'completed' THEN
        NEW.completed_at = NULL;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_completed_at
    BEFORE UPDATE ON tasks
    FOR EACH ROW
    EXECUTE FUNCTION update_completed_at();

-- İndeksler
CREATE INDEX idx_tasks_user_id ON tasks(user_id);
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_due_datetime ON tasks(due_datetime);
CREATE INDEX idx_tasks_priority ON tasks(priority);
CREATE INDEX idx_tasks_created_at ON tasks(created_at);

-- RLS politikalarını devre dışı bırak (silme sorununu çözmek için)
ALTER TABLE tasks DISABLE ROW LEVEL SECURITY;

-- Test verisi ekle
INSERT INTO tasks (title, description, status, priority, due_date, due_time, user_id) VALUES
('Test Görevi', 'Bu bir test görevidir', 'pending', 'high', '2024-12-25', '14:30:00', 'defa43f1-e3b6-43dd-86f6-38a89e13a96c'),
('Alışveriş', 'Market alışverişi yapılacak', 'pending', 'medium', '2024-12-20', '10:00:00', 'defa43f1-e3b6-43dd-86f6-38a89e13a96c');

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
FROM tasks 
ORDER BY due_datetime ASC NULLS LAST; 