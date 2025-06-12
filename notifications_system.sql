-- Bildirimler sistemi için veritabanı tabloları

-- Bildirimler tablosu
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_email VARCHAR(255) NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50) NOT NULL, -- 'task_reminder', 'task_assigned', 'project_invitation', 'project_added'
    related_id UUID, -- task_id veya project_id
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    action_data JSONB -- Ek bilgiler için
);

-- Proje davetleri tablosu (güncellenmiş)
DROP TABLE IF EXISTS project_invitations CASCADE;
CREATE TABLE project_invitations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    invited_email VARCHAR(255) NOT NULL,
    invited_by VARCHAR(255) NOT NULL,
    invitation_token VARCHAR(255) UNIQUE NOT NULL,
    status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'accepted', 'rejected', 'expired'
    role VARCHAR(20) DEFAULT 'member', -- 'member', 'admin'
    message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '7 days'),
    responded_at TIMESTAMP WITH TIME ZONE
);

-- Bildirim ayarları tablosu
CREATE TABLE IF NOT EXISTS notification_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_email VARCHAR(255) UNIQUE NOT NULL,
    task_reminders BOOLEAN DEFAULT TRUE,
    task_assignments BOOLEAN DEFAULT TRUE,
    project_invitations BOOLEAN DEFAULT TRUE,
    project_updates BOOLEAN DEFAULT TRUE,
    reminder_hours INTEGER DEFAULT 24, -- Kaç saat önceden hatırlatma
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- İndeksler
CREATE INDEX IF NOT EXISTS idx_notifications_user_email ON notifications(user_email);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_project_invitations_email ON project_invitations(invited_email);
CREATE INDEX IF NOT EXISTS idx_project_invitations_status ON project_invitations(status);
CREATE INDEX IF NOT EXISTS idx_project_invitations_token ON project_invitations(invitation_token);

-- Görev hatırlatma bildirimi oluşturma fonksiyonu
CREATE OR REPLACE FUNCTION create_task_reminder_notifications()
RETURNS void AS $$
DECLARE
    task_record RECORD;
    reminder_hours INTEGER;
    notification_title VARCHAR(255);
    notification_message TEXT;
BEGIN
    -- Yaklaşan görevler için bildirim oluştur
    FOR task_record IN 
        SELECT t.*, u.email as user_email, ns.reminder_hours
        FROM tasks t
        JOIN user_profiles u ON t.user_id = u.id
        LEFT JOIN notification_settings ns ON u.email = ns.user_email
        WHERE t.due_datetime IS NOT NULL 
        AND t.status != 'completed'
        AND t.due_datetime BETWEEN NOW() AND NOW() + INTERVAL '1 day' * COALESCE(ns.reminder_hours, 24) / 24
        AND NOT EXISTS (
            SELECT 1 FROM notifications n 
            WHERE n.related_id = t.id 
            AND n.type = 'task_reminder' 
            AND n.created_at > NOW() - INTERVAL '1 day'
        )
    LOOP
        notification_title := 'Görev Hatırlatması: ' || task_record.title;
        notification_message := 'Göreviniz "' || task_record.title || '" ' || 
                               to_char(task_record.due_datetime, 'DD.MM.YYYY HH24:MI') || 
                               ' tarihinde sona erecek.';
        
        INSERT INTO notifications (user_email, title, message, type, related_id, action_data)
        VALUES (
            task_record.user_email,
            notification_title,
            notification_message,
            'task_reminder',
            task_record.id,
            jsonb_build_object('due_datetime', task_record.due_datetime, 'priority', task_record.priority)
        );
    END LOOP;
    
    -- Proje görevleri için hatırlatma
    FOR task_record IN 
        SELECT pt.*, pm.user_email, ns.reminder_hours, p.title as project_title
        FROM project_tasks pt
        JOIN project_members pm ON pt.assigned_to = pm.user_email
        JOIN projects p ON pt.project_id = p.id
        LEFT JOIN notification_settings ns ON pm.user_email = ns.user_email
        WHERE pt.due_datetime IS NOT NULL 
        AND pt.status != 'done'
        AND pt.due_datetime BETWEEN NOW() AND NOW() + INTERVAL '1 day' * COALESCE(ns.reminder_hours, 24) / 24
        AND NOT EXISTS (
            SELECT 1 FROM notifications n 
            WHERE n.related_id = pt.id 
            AND n.type = 'task_reminder' 
            AND n.created_at > NOW() - INTERVAL '1 day'
        )
    LOOP
        notification_title := 'Proje Görevi Hatırlatması: ' || task_record.title;
        notification_message := 'Proje "' || task_record.project_title || '" içindeki göreviniz "' || 
                               task_record.title || '" ' || 
                               to_char(task_record.due_datetime, 'DD.MM.YYYY HH24:MI') || 
                               ' tarihinde sona erecek.';
        
        INSERT INTO notifications (user_email, title, message, type, related_id, action_data)
        VALUES (
            task_record.user_email,
            notification_title,
            notification_message,
            'task_reminder',
            task_record.id,
            jsonb_build_object(
                'due_datetime', task_record.due_datetime, 
                'priority', task_record.priority,
                'project_id', task_record.project_id,
                'project_title', task_record.project_title
            )
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Görev atama bildirimi oluşturma fonksiyonu
CREATE OR REPLACE FUNCTION create_task_assignment_notification()
RETURNS TRIGGER AS $$
DECLARE
    project_title VARCHAR(255);
    assigned_by_name VARCHAR(255);
BEGIN
    -- Sadece yeni atama veya atama değişikliği durumunda
    IF (TG_OP = 'INSERT' AND NEW.assigned_to IS NOT NULL) OR 
       (TG_OP = 'UPDATE' AND OLD.assigned_to IS DISTINCT FROM NEW.assigned_to AND NEW.assigned_to IS NOT NULL) THEN
        
        -- Proje başlığını al
        SELECT title INTO project_title FROM projects WHERE id = NEW.project_id;
        
        -- Atayan kişinin adını al
        SELECT COALESCE(ad || ' ' || soyad, NEW.assigned_by) INTO assigned_by_name 
        FROM user_profiles WHERE email = NEW.assigned_by;
        
        INSERT INTO notifications (user_email, title, message, type, related_id, action_data)
        VALUES (
            NEW.assigned_to,
            'Yeni Görev Atandı: ' || NEW.title,
            assigned_by_name || ' tarafından "' || project_title || '" projesinde size "' || 
            NEW.title || '" görevi atandı.',
            'task_assigned',
            NEW.id,
            jsonb_build_object(
                'project_id', NEW.project_id,
                'project_title', project_title,
                'assigned_by', NEW.assigned_by,
                'assigned_by_name', assigned_by_name
            )
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Proje davet bildirimi oluşturma fonksiyonu
CREATE OR REPLACE FUNCTION create_project_invitation_notification()
RETURNS TRIGGER AS $$
DECLARE
    project_title VARCHAR(255);
    invited_by_name VARCHAR(255);
BEGIN
    IF TG_OP = 'INSERT' THEN
        -- Proje başlığını al
        SELECT title INTO project_title FROM projects WHERE id = NEW.project_id;
        
        -- Davet eden kişinin adını al
        SELECT COALESCE(ad || ' ' || soyad, NEW.invited_by) INTO invited_by_name 
        FROM user_profiles WHERE email = NEW.invited_by;
        
        INSERT INTO notifications (user_email, title, message, type, related_id, action_data)
        VALUES (
            NEW.invited_email,
            'Proje Davetiniz: ' || project_title,
            invited_by_name || ' sizi "' || project_title || '" projesine davet etti. Daveti kabul etmek veya reddetmek için bildirimler sayfasını ziyaret edin.',
            'project_invitation',
            NEW.id,
            jsonb_build_object(
                'project_id', NEW.project_id,
                'project_title', project_title,
                'invited_by', NEW.invited_by,
                'invited_by_name', invited_by_name,
                'invitation_token', NEW.invitation_token,
                'role', NEW.role
            )
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggerları oluştur
DROP TRIGGER IF EXISTS trigger_task_assignment_notification ON project_tasks;
CREATE TRIGGER trigger_task_assignment_notification
    AFTER INSERT OR UPDATE ON project_tasks
    FOR EACH ROW
    EXECUTE FUNCTION create_task_assignment_notification();

DROP TRIGGER IF EXISTS trigger_project_invitation_notification ON project_invitations;
CREATE TRIGGER trigger_project_invitation_notification
    AFTER INSERT ON project_invitations
    FOR EACH ROW
    EXECUTE FUNCTION create_project_invitation_notification();

-- Eski bildirimleri temizleme fonksiyonu
CREATE OR REPLACE FUNCTION cleanup_old_notifications()
RETURNS void AS $$
BEGIN
    -- 30 günden eski okunmuş bildirimleri sil
    DELETE FROM notifications 
    WHERE is_read = TRUE 
    AND created_at < NOW() - INTERVAL '30 days';
    
    -- 90 günden eski tüm bildirimleri sil
    DELETE FROM notifications 
    WHERE created_at < NOW() - INTERVAL '90 days';
    
    -- Süresi dolmuş davetleri güncelle
    UPDATE project_invitations 
    SET status = 'expired' 
    WHERE status = 'pending' 
    AND expires_at < NOW();
END;
$$ LANGUAGE plpgsql;

-- Test verileri (isteğe bağlı)
-- INSERT INTO notification_settings (user_email) 
-- SELECT DISTINCT email FROM user_profiles 
-- WHERE email NOT IN (SELECT user_email FROM notification_settings);

-- Bildirimler görünümü
CREATE OR REPLACE VIEW user_notifications AS
SELECT 
    n.*,
    CASE 
        WHEN n.type = 'task_reminder' THEN 'Görev Hatırlatması'
        WHEN n.type = 'task_assigned' THEN 'Görev Atandı'
        WHEN n.type = 'project_invitation' THEN 'Proje Daveti'
        WHEN n.type = 'project_added' THEN 'Projeye Eklendi'
        ELSE 'Bildirim'
    END as type_display,
    CASE 
        WHEN n.created_at > NOW() - INTERVAL '1 hour' THEN 'Şimdi'
        WHEN n.created_at > NOW() - INTERVAL '1 day' THEN EXTRACT(HOUR FROM NOW() - n.created_at) || ' saat önce'
        WHEN n.created_at > NOW() - INTERVAL '7 days' THEN EXTRACT(DAY FROM NOW() - n.created_at) || ' gün önce'
        ELSE to_char(n.created_at, 'DD.MM.YYYY')
    END as time_ago
FROM notifications n
ORDER BY n.created_at DESC; 