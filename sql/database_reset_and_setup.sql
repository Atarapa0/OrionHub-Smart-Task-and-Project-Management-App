-- OrionHub Veritabanı Sıfırlama ve Kurulum Scripti
-- Bu dosyayı Supabase SQL Editor'da çalıştırın
-- SIRA: 1. Önce bu dosyayı çalıştırın

-- =====================================================
-- 1. MEVCUT TABLOLARI VE POLİTİKALARI TEMİZLE
-- =====================================================

-- Tüm RLS politikalarını temizle
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public') LOOP
        EXECUTE 'DROP POLICY IF EXISTS "Users can view own profile" ON public.' || quote_ident(r.tablename);
        EXECUTE 'DROP POLICY IF EXISTS "Users can update own profile" ON public.' || quote_ident(r.tablename);
        EXECUTE 'DROP POLICY IF EXISTS "Anyone can register" ON public.' || quote_ident(r.tablename);
        EXECUTE 'DROP POLICY IF EXISTS "Users can view project members of their projects" ON public.' || quote_ident(r.tablename);
        EXECUTE 'DROP POLICY IF EXISTS "Project owners and admins can insert members" ON public.' || quote_ident(r.tablename);
        EXECUTE 'DROP POLICY IF EXISTS "Project owners and admins can update members" ON public.' || quote_ident(r.tablename);
        EXECUTE 'DROP POLICY IF EXISTS "Project owners and admins can delete members" ON public.' || quote_ident(r.tablename);
        EXECUTE 'DROP POLICY IF EXISTS "Project members can view tasks" ON public.' || quote_ident(r.tablename);
        EXECUTE 'DROP POLICY IF EXISTS "Project members can insert tasks" ON public.' || quote_ident(r.tablename);
        EXECUTE 'DROP POLICY IF EXISTS "Task owners and project admins can update tasks" ON public.' || quote_ident(r.tablename);
        EXECUTE 'DROP POLICY IF EXISTS "Task owners and project admins can delete tasks" ON public.' || quote_ident(r.tablename);
        EXECUTE 'DROP POLICY IF EXISTS "Project owners can view invitations" ON public.' || quote_ident(r.tablename);
        EXECUTE 'DROP POLICY IF EXISTS "Project owners can send invitations" ON public.' || quote_ident(r.tablename);
        EXECUTE 'DROP POLICY IF EXISTS "Project owners can update invitations" ON public.' || quote_ident(r.tablename);
        EXECUTE 'DROP POLICY IF EXISTS "Enable read access for project members" ON public.' || quote_ident(r.tablename);
        EXECUTE 'DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.' || quote_ident(r.tablename);
        EXECUTE 'DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.' || quote_ident(r.tablename);
        EXECUTE 'DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.' || quote_ident(r.tablename);
        EXECUTE 'DROP POLICY IF EXISTS "Enable read access for project tasks" ON public.' || quote_ident(r.tablename);
        EXECUTE 'DROP POLICY IF EXISTS "Enable insert for project tasks" ON public.' || quote_ident(r.tablename);
        EXECUTE 'DROP POLICY IF EXISTS "Enable update for project tasks" ON public.' || quote_ident(r.tablename);
        EXECUTE 'DROP POLICY IF EXISTS "Enable delete for project tasks" ON public.' || quote_ident(r.tablename);
        EXECUTE 'DROP POLICY IF EXISTS "Enable read access for project invitations" ON public.' || quote_ident(r.tablename);
        EXECUTE 'DROP POLICY IF EXISTS "Enable insert for project invitations" ON public.' || quote_ident(r.tablename);
        EXECUTE 'DROP POLICY IF EXISTS "Enable update for project invitations" ON public.' || quote_ident(r.tablename);
        EXECUTE 'DROP POLICY IF EXISTS "Enable delete for project invitations" ON public.' || quote_ident(r.tablename);
    END LOOP;
END $$;

-- Tüm trigger'ları temizle
DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON public.user_profiles;
DROP TRIGGER IF EXISTS update_task_completion_trigger ON public.project_tasks;
DROP TRIGGER IF EXISTS trigger_task_assignment_notification ON public.project_tasks;
DROP TRIGGER IF EXISTS trigger_project_invitation_notification ON public.project_invitations;

-- Tüm fonksiyonları temizle
DROP FUNCTION IF EXISTS public.update_updated_at_column();
DROP FUNCTION IF EXISTS public.set_config(TEXT, TEXT);
DROP FUNCTION IF EXISTS public.add_project_owner();
DROP FUNCTION IF EXISTS public.accept_project_invitation(TEXT);
DROP FUNCTION IF EXISTS public.update_task_completion();
DROP FUNCTION IF EXISTS public.create_task_reminder_notifications();
DROP FUNCTION IF EXISTS public.create_task_assignment_notification();
DROP FUNCTION IF EXISTS public.create_project_invitation_notification();
DROP FUNCTION IF EXISTS public.cleanup_old_notifications();

-- Tüm view'ları temizle
DROP VIEW IF EXISTS public.user_notifications;

-- Tüm tabloları temizle (CASCADE ile bağımlılıkları da sil)
DROP TABLE IF EXISTS public.notifications CASCADE;
DROP TABLE IF EXISTS public.notification_settings CASCADE;
DROP TABLE IF EXISTS public.project_invitations CASCADE;
DROP TABLE IF EXISTS public.project_tasks CASCADE;
DROP TABLE IF EXISTS public.project_members CASCADE;
DROP TABLE IF EXISTS public.tasks CASCADE;
DROP TABLE IF EXISTS public.user_profiles CASCADE;
DROP TABLE IF EXISTS public.projects CASCADE;

-- Tüm index'leri temizle
DROP INDEX IF EXISTS idx_user_profiles_email;
DROP INDEX IF EXISTS idx_user_profiles_created_at;
DROP INDEX IF EXISTS idx_project_members_project_id;
DROP INDEX IF EXISTS idx_project_members_user_email;
DROP INDEX IF EXISTS idx_project_members_status;
DROP INDEX IF EXISTS idx_project_tasks_project_id;
DROP INDEX IF EXISTS idx_project_tasks_assigned_to;
DROP INDEX IF EXISTS idx_project_tasks_status;
DROP INDEX IF EXISTS idx_project_invitations_token;
DROP INDEX IF EXISTS idx_project_invitations_email;
DROP INDEX IF EXISTS idx_project_invitations_status;
DROP INDEX IF EXISTS idx_notifications_user_email;
DROP INDEX IF EXISTS idx_notifications_type;
DROP INDEX IF EXISTS idx_notifications_created_at;
DROP INDEX IF EXISTS idx_notifications_is_read;

RAISE NOTICE 'Tüm mevcut tablolar, politikalar ve fonksiyonlar temizlendi.';

-- =====================================================
-- 2. TEMEL TABLOLARI OLUŞTUR
-- =====================================================

-- 1. Kullanıcı profilleri tablosu
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    ad VARCHAR(100) NOT NULL,
    soyad VARCHAR(100) NOT NULL,
    telefon VARCHAR(20),
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Projeler tablosu
CREATE TABLE IF NOT EXISTS public.projects (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    owner_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Kişisel görevler tablosu
CREATE TABLE IF NOT EXISTS public.tasks (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    due_datetime TIMESTAMP WITH TIME ZONE,
    priority VARCHAR(10) DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    category VARCHAR(50),
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Proje üyeleri tablosu
CREATE TABLE IF NOT EXISTS public.project_members (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    project_id UUID NOT NULL,
    user_email VARCHAR(255) NOT NULL,
    user_name VARCHAR(255) NOT NULL,
    role VARCHAR(50) DEFAULT 'member' CHECK (role IN ('owner', 'admin', 'member')),
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    invited_by VARCHAR(255),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'pending', 'removed')),
    UNIQUE(project_id, user_email)
);

-- 5. Proje görevleri tablosu
CREATE TABLE IF NOT EXISTS public.project_tasks (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    project_id UUID NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    assigned_to VARCHAR(255),
    assigned_by VARCHAR(255),
    status VARCHAR(20) DEFAULT 'todo' CHECK (status IN ('todo', 'in_progress', 'done')),
    priority VARCHAR(10) DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high')),
    due_datetime TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE
);

-- 6. Proje davetleri tablosu
CREATE TABLE IF NOT EXISTS public.project_invitations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    project_id UUID NOT NULL,
    invited_email VARCHAR(255) NOT NULL,
    invited_by VARCHAR(255) NOT NULL,
    invitation_token VARCHAR(255) UNIQUE NOT NULL,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'expired')),
    role VARCHAR(20) DEFAULT 'member' CHECK (role IN ('member', 'admin')),
    message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '7 days'),
    responded_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(project_id, invited_email)
);

-- 7. Bildirimler tablosu
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_email VARCHAR(255) NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50) NOT NULL CHECK (type IN ('task_reminder', 'task_assigned', 'project_invitation', 'project_added', 'general')),
    related_id UUID,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    action_data JSONB
);

-- 8. Bildirim ayarları tablosu
CREATE TABLE IF NOT EXISTS public.notification_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_email VARCHAR(255) UNIQUE NOT NULL,
    task_reminders BOOLEAN DEFAULT TRUE,
    task_assignments BOOLEAN DEFAULT TRUE,
    project_invitations BOOLEAN DEFAULT TRUE,
    project_updates BOOLEAN DEFAULT TRUE,
    reminder_hours INTEGER DEFAULT 24,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

RAISE NOTICE 'Temel tablolar oluşturuldu.';

-- =====================================================
-- 3. FOREIGN KEY İLİŞKİLERİ
-- =====================================================

-- Tasks -> User Profiles
ALTER TABLE public.tasks 
ADD CONSTRAINT fk_tasks_user_id 
FOREIGN KEY (user_id) REFERENCES public.user_profiles(id) ON DELETE CASCADE;

-- Project Members -> Projects
ALTER TABLE public.project_members 
ADD CONSTRAINT fk_project_members_project_id 
FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

-- Project Tasks -> Projects
ALTER TABLE public.project_tasks 
ADD CONSTRAINT fk_project_tasks_project_id 
FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

-- Project Invitations -> Projects
ALTER TABLE public.project_invitations 
ADD CONSTRAINT fk_project_invitations_project_id 
FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

RAISE NOTICE 'Foreign key ilişkileri kuruldu.';

-- =====================================================
-- 4. İNDEKSLER (PERFORMANS İÇİN)
-- =====================================================

-- User Profiles indexes
CREATE INDEX IF NOT EXISTS idx_user_profiles_email ON public.user_profiles(email);
CREATE INDEX IF NOT EXISTS idx_user_profiles_created_at ON public.user_profiles(created_at);

-- Projects indexes
CREATE INDEX IF NOT EXISTS idx_projects_owner_email ON public.projects(owner_email);
CREATE INDEX IF NOT EXISTS idx_projects_created_at ON public.projects(created_at);

-- Tasks indexes
CREATE INDEX IF NOT EXISTS idx_tasks_user_id ON public.tasks(user_id);
CREATE INDEX IF NOT EXISTS idx_tasks_status ON public.tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_priority ON public.tasks(priority);
CREATE INDEX IF NOT EXISTS idx_tasks_due_datetime ON public.tasks(due_datetime);

-- Project Members indexes
CREATE INDEX IF NOT EXISTS idx_project_members_project_id ON public.project_members(project_id);
CREATE INDEX IF NOT EXISTS idx_project_members_user_email ON public.project_members(user_email);
CREATE INDEX IF NOT EXISTS idx_project_members_status ON public.project_members(status);

-- Project Tasks indexes
CREATE INDEX IF NOT EXISTS idx_project_tasks_project_id ON public.project_tasks(project_id);
CREATE INDEX IF NOT EXISTS idx_project_tasks_assigned_to ON public.project_tasks(assigned_to);
CREATE INDEX IF NOT EXISTS idx_project_tasks_status ON public.project_tasks(status);
CREATE INDEX IF NOT EXISTS idx_project_tasks_due_datetime ON public.project_tasks(due_datetime);

-- Project Invitations indexes
CREATE INDEX IF NOT EXISTS idx_project_invitations_token ON public.project_invitations(invitation_token);
CREATE INDEX IF NOT EXISTS idx_project_invitations_email ON public.project_invitations(invited_email);
CREATE INDEX IF NOT EXISTS idx_project_invitations_status ON public.project_invitations(status);

-- Notifications indexes
CREATE INDEX IF NOT EXISTS idx_notifications_user_email ON public.notifications(user_email);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON public.notifications(type);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON public.notifications(created_at);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON public.notifications(is_read);

RAISE NOTICE 'İndeksler oluşturuldu.';

-- =====================================================
-- 5. ROW LEVEL SECURITY (RLS) POLİTİKALARI
-- =====================================================

-- Tüm tablolarda RLS'yi etkinleştir
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.project_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.project_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.project_invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_settings ENABLE ROW LEVEL SECURITY;

-- User Profiles politikaları
CREATE POLICY "Users can view own profile" ON public.user_profiles
    FOR SELECT USING (auth.uid()::text = id::text);

CREATE POLICY "Users can update own profile" ON public.user_profiles
    FOR UPDATE USING (auth.uid()::text = id::text);

CREATE POLICY "Anyone can register" ON public.user_profiles
    FOR INSERT WITH CHECK (true);

-- Projects politikaları
CREATE POLICY "Users can view projects they own or are members of" ON public.projects
    FOR SELECT USING (
        owner_id = auth.uid()::uuid
        OR 
        EXISTS (
            SELECT 1 FROM public.project_members 
            WHERE project_id = projects.id 
            AND user_email = (SELECT email FROM public.user_profiles WHERE id = auth.uid()::uuid)
        )
    );

CREATE POLICY "Users can create projects" ON public.projects
    FOR INSERT WITH CHECK (
        owner_id = auth.uid()::uuid
    );

CREATE POLICY "Project owners can update projects" ON public.projects
    FOR UPDATE USING (
        owner_id = auth.uid()::uuid
    );

CREATE POLICY "Project owners can delete projects" ON public.projects
    FOR DELETE USING (
        owner_id = auth.uid()::uuid
    );

-- Tasks politikaları
CREATE POLICY "Users can view own tasks" ON public.tasks
    FOR SELECT USING (user_id = auth.uid()::uuid);

CREATE POLICY "Users can create own tasks" ON public.tasks
    FOR INSERT WITH CHECK (user_id = auth.uid()::uuid);

CREATE POLICY "Users can update own tasks" ON public.tasks
    FOR UPDATE USING (user_id = auth.uid()::uuid);

CREATE POLICY "Users can delete own tasks" ON public.tasks
    FOR DELETE USING (user_id = auth.uid()::uuid);

-- Project Members politikaları
CREATE POLICY "Project members can view project members" ON public.project_members
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.project_members pm
            WHERE pm.project_id = project_members.project_id
            AND pm.user_email = (SELECT email FROM public.user_profiles WHERE id = auth.uid()::uuid)
        )
    );

CREATE POLICY "Project owners and admins can manage members" ON public.project_members
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.project_members pm
            WHERE pm.project_id = project_members.project_id
            AND pm.user_email = (SELECT email FROM public.user_profiles WHERE id = auth.uid()::uuid)
            AND pm.role IN ('owner', 'admin')
        )
    );

-- Project Tasks politikaları
CREATE POLICY "Project members can view tasks" ON public.project_tasks
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.project_members pm
            WHERE pm.project_id = project_tasks.project_id
            AND pm.user_email = (SELECT email FROM public.user_profiles WHERE id = auth.uid()::uuid)
        )
    );

CREATE POLICY "Project members can create tasks" ON public.project_tasks
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.project_members pm
            WHERE pm.project_id = project_tasks.project_id
            AND pm.user_email = (SELECT email FROM public.user_profiles WHERE id = auth.uid()::uuid)
        )
    );

CREATE POLICY "Task assignees and project admins can update tasks" ON public.project_tasks
    FOR UPDATE USING (
        assigned_to = (SELECT email FROM public.user_profiles WHERE id = auth.uid()::uuid)
        OR
        EXISTS (
            SELECT 1 FROM public.project_members pm
            WHERE pm.project_id = project_tasks.project_id
            AND pm.user_email = (SELECT email FROM public.user_profiles WHERE id = auth.uid()::uuid)
            AND pm.role IN ('owner', 'admin')
        )
    );

-- Project Invitations politikaları
CREATE POLICY "Project owners can manage invitations" ON public.project_invitations
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.project_members pm
            WHERE pm.project_id = project_invitations.project_id
            AND pm.user_email = (SELECT email FROM public.user_profiles WHERE id = auth.uid()::uuid)
            AND pm.role = 'owner'
        )
    );

-- Notifications politikaları
CREATE POLICY "Users can view own notifications" ON public.notifications
    FOR SELECT USING (
        user_email = (SELECT email FROM public.user_profiles WHERE id = auth.uid()::uuid)
    );

CREATE POLICY "Users can update own notifications" ON public.notifications
    FOR UPDATE USING (
        user_email = (SELECT email FROM public.user_profiles WHERE id = auth.uid()::uuid)
    );

-- Notification Settings politikaları
CREATE POLICY "Users can manage own notification settings" ON public.notification_settings
    FOR ALL USING (
        user_email = (SELECT email FROM public.user_profiles WHERE id = auth.uid()::uuid)
    );

RAISE NOTICE 'RLS politikaları oluşturuldu.';

-- =====================================================
-- 6. TRIGGER'LAR VE FONKSİYONLAR
-- =====================================================

-- Updated_at otomatik güncelleme fonksiyonu
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Updated_at trigger'ları
CREATE TRIGGER update_user_profiles_updated_at 
    BEFORE UPDATE ON public.user_profiles 
    FOR EACH ROW 
    EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_projects_updated_at 
    BEFORE UPDATE ON public.projects 
    FOR EACH ROW 
    EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_tasks_updated_at 
    BEFORE UPDATE ON public.tasks 
    FOR EACH ROW 
    EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_project_tasks_updated_at 
    BEFORE UPDATE ON public.project_tasks 
    FOR EACH ROW 
    EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_notification_settings_updated_at 
    BEFORE UPDATE ON public.notification_settings 
    FOR EACH ROW 
    EXECUTE FUNCTION public.update_updated_at_column();

-- Görev tamamlama trigger'ı
CREATE OR REPLACE FUNCTION public.update_task_completion()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'done' AND OLD.status != 'done' THEN
        NEW.completed_at = NOW();
    ELSIF NEW.status != 'done' THEN
        NEW.completed_at = NULL;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_task_completion_trigger
    BEFORE UPDATE ON public.project_tasks
    FOR EACH ROW
    EXECUTE FUNCTION public.update_task_completion();

-- Bildirim fonksiyonları
CREATE OR REPLACE FUNCTION public.create_task_assignment_notification()
RETURNS TRIGGER AS $$
DECLARE
    project_title VARCHAR(255);
    assigned_by_name VARCHAR(255);
BEGIN
    IF (TG_OP = 'INSERT' AND NEW.assigned_to IS NOT NULL) OR 
       (TG_OP = 'UPDATE' AND OLD.assigned_to IS DISTINCT FROM NEW.assigned_to AND NEW.assigned_to IS NOT NULL) THEN
        
        SELECT title INTO project_title FROM projects WHERE id = NEW.project_id;
        
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

CREATE TRIGGER trigger_task_assignment_notification
    AFTER INSERT OR UPDATE ON public.project_tasks
    FOR EACH ROW
    EXECUTE FUNCTION public.create_task_assignment_notification();

-- Proje davet bildirimi
CREATE OR REPLACE FUNCTION public.create_project_invitation_notification()
RETURNS TRIGGER AS $$
DECLARE
    project_title VARCHAR(255);
    invited_by_name VARCHAR(255);
BEGIN
    IF TG_OP = 'INSERT' THEN
        SELECT title INTO project_title FROM projects WHERE id = NEW.project_id;
        
        SELECT COALESCE(ad || ' ' || soyad, NEW.invited_by) INTO invited_by_name 
        FROM user_profiles WHERE email = NEW.invited_by;
        
        INSERT INTO notifications (user_email, title, message, type, related_id, action_data)
        VALUES (
            NEW.invited_email,
            'Proje Davetiniz: ' || project_title,
            invited_by_name || ' sizi "' || project_title || '" projesine davet etti.',
            'project_invitation',
            NEW.id,
            jsonb_build_object(
                'project_id', NEW.project_id,
                'project_title', project_title,
                'invited_by', NEW.invited_by,
                'invited_by_name', invited_by_name,
                'role', NEW.role
            )
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_project_invitation_notification
    AFTER INSERT ON public.project_invitations
    FOR EACH ROW
    EXECUTE FUNCTION public.create_project_invitation_notification();

-- Eski bildirimleri temizleme fonksiyonu
CREATE OR REPLACE FUNCTION public.cleanup_old_notifications()
RETURNS void AS $$
BEGIN
    -- 30 günden eski okunmuş bildirimleri sil
    DELETE FROM notifications 
    WHERE is_read = true 
    AND created_at < NOW() - INTERVAL '30 days';
    
    -- 90 günden eski tüm bildirimleri sil
    DELETE FROM notifications 
    WHERE created_at < NOW() - INTERVAL '90 days';
    
    -- Süresi geçen davetleri expired olarak işaretle
    UPDATE project_invitations 
    SET status = 'expired' 
    WHERE status = 'pending' 
    AND expires_at < NOW();
END;
$$ LANGUAGE plpgsql;

-- Bildirimler view'ı
CREATE OR REPLACE VIEW public.user_notifications AS
SELECT 
    n.*,
    CASE 
        WHEN n.type = 'task_assigned' THEN 'Görev Atandı'
        WHEN n.type = 'project_invitation' THEN 'Proje Daveti'
        WHEN n.type = 'task_reminder' THEN 'Görev Hatırlatması'
        ELSE 'Genel'
    END as type_display
FROM notifications n
ORDER BY n.created_at DESC;

RAISE NOTICE 'Trigger\'lar ve fonksiyonlar oluşturuldu.';

-- =====================================================
-- 7. TEST VERİLERİ (İSTEĞE BAĞLI)
-- =====================================================

-- Test kullanıcısı oluştur (şifre: test123)
INSERT INTO public.user_profiles (email, password_hash, ad, soyad, is_verified)
VALUES (
    'test@orionhub.com',
    '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', -- test123
    'Test',
    'Kullanıcı',
    true
) ON CONFLICT (email) DO NOTHING;

-- Test projesi oluştur
INSERT INTO public.projects (title, description, owner_id)
VALUES (
    'OrionHub Geliştirme',
    'OrionHub uygulamasının geliştirilmesi ve test edilmesi',
    (SELECT id FROM public.user_profiles WHERE email = 'test@orionhub.com')
) ON CONFLICT DO NOTHING;

RAISE NOTICE 'Test verileri eklendi (isteğe bağlı).';

-- =====================================================
-- 8. KURULUM TAMAMLANDI
-- =====================================================

RAISE NOTICE '========================================';
RAISE NOTICE 'OrionHub Veritabanı Kurulumu Tamamlandı!';
RAISE NOTICE '========================================';
RAISE NOTICE 'Oluşturulan tablolar:';
RAISE NOTICE '- user_profiles (kullanıcı profilleri)';
RAISE NOTICE '- projects (projeler)';
RAISE NOTICE '- tasks (kişisel görevler)';
RAISE NOTICE '- project_members (proje üyeleri)';
RAISE NOTICE '- project_tasks (proje görevleri)';
RAISE NOTICE '- project_invitations (proje davetleri)';
RAISE NOTICE '- notifications (bildirimler)';
RAISE NOTICE '- notification_settings (bildirim ayarları)';
RAISE NOTICE '';
RAISE NOTICE 'RLS politikaları ve güvenlik ayarları aktif.';
RAISE NOTICE 'Trigger\'lar ve fonksiyonlar çalışır durumda.';
RAISE NOTICE 'Test kullanıcısı: test@orionhub.com';
RAISE NOTICE 'Test şifresi: test123';
RAISE NOTICE '';
RAISE NOTICE 'Uygulama artık kullanıma hazır!'; 