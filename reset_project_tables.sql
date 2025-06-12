-- Reset Project Management Tables
-- Bu dosyayı Supabase SQL Editor'da çalıştırın

-- 1. Önce mevcut tabloları güvenli şekilde sil
DO $$
BEGIN
    -- Trigger'ları sil
    BEGIN
        DROP TRIGGER IF EXISTS add_project_owner_trigger ON public.projects;
    EXCEPTION WHEN OTHERS THEN NULL;
    END;
    
    BEGIN
        DROP TRIGGER IF EXISTS update_task_completion_trigger ON public.project_tasks;
    EXCEPTION WHEN OTHERS THEN NULL;
    END;
    
    -- RLS politikalarını sil
    BEGIN
        DROP POLICY IF EXISTS "Enable read access for project members" ON public.project_members;
        DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.project_members;
        DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.project_members;
        DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.project_members;
    EXCEPTION WHEN OTHERS THEN NULL;
    END;
    
    BEGIN
        DROP POLICY IF EXISTS "Enable read access for project tasks" ON public.project_tasks;
        DROP POLICY IF EXISTS "Enable insert for project tasks" ON public.project_tasks;
        DROP POLICY IF EXISTS "Enable update for project tasks" ON public.project_tasks;
        DROP POLICY IF EXISTS "Enable delete for project tasks" ON public.project_tasks;
    EXCEPTION WHEN OTHERS THEN NULL;
    END;
    
    BEGIN
        DROP POLICY IF EXISTS "Enable read access for project invitations" ON public.project_invitations;
        DROP POLICY IF EXISTS "Enable insert for project invitations" ON public.project_invitations;
        DROP POLICY IF EXISTS "Enable update for project invitations" ON public.project_invitations;
        DROP POLICY IF EXISTS "Enable delete for project invitations" ON public.project_invitations;
    EXCEPTION WHEN OTHERS THEN NULL;
    END;
    
    BEGIN
        DROP POLICY IF EXISTS "Enable all for projects" ON public.projects;
    EXCEPTION WHEN OTHERS THEN NULL;
    END;
    
    -- Tabloları sil (foreign key sırasına göre)
    BEGIN
        DROP TABLE IF EXISTS public.project_invitations CASCADE;
    EXCEPTION WHEN OTHERS THEN NULL;
    END;
    
    BEGIN
        DROP TABLE IF EXISTS public.project_tasks CASCADE;
    EXCEPTION WHEN OTHERS THEN NULL;
    END;
    
    BEGIN
        DROP TABLE IF EXISTS public.project_members CASCADE;
    EXCEPTION WHEN OTHERS THEN NULL;
    END;
    
    BEGIN
        DROP TABLE IF EXISTS public.projects CASCADE;
    EXCEPTION WHEN OTHERS THEN NULL;
    END;
    
    RAISE NOTICE '🗑️  Eski tablolar temizlendi.';
END $$;

-- 2. Ana projects tablosunu oluştur
CREATE TABLE public.projects (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    created_by VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. İlişkili tabloları oluştur
CREATE TABLE public.project_members (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    user_email VARCHAR(255) NOT NULL,
    user_name VARCHAR(255) NOT NULL,
    role VARCHAR(50) DEFAULT 'member', -- 'owner', 'admin', 'member'
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    invited_by VARCHAR(255),
    status VARCHAR(20) DEFAULT 'active', -- 'active', 'pending', 'removed'
    UNIQUE(project_id, user_email)
);

CREATE TABLE public.project_tasks (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    assigned_to VARCHAR(255), -- user email
    assigned_by VARCHAR(255), -- user email
    status VARCHAR(20) DEFAULT 'todo', -- 'todo', 'in_progress', 'done'
    priority VARCHAR(10) DEFAULT 'medium', -- 'low', 'medium', 'high'
    due_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE
);

CREATE TABLE public.project_invitations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    invited_email VARCHAR(255) NOT NULL,
    invited_by VARCHAR(255) NOT NULL,
    invitation_token VARCHAR(255) UNIQUE NOT NULL,
    status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'accepted', 'declined', 'expired'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '7 days'),
    UNIQUE(project_id, invited_email)
);

-- 4. İndeksler
CREATE INDEX idx_projects_created_by ON public.projects(created_by);
CREATE INDEX idx_projects_created_at ON public.projects(created_at);

CREATE INDEX idx_project_members_project_id ON public.project_members(project_id);
CREATE INDEX idx_project_members_user_email ON public.project_members(user_email);
CREATE INDEX idx_project_members_status ON public.project_members(status);

CREATE INDEX idx_project_tasks_project_id ON public.project_tasks(project_id);
CREATE INDEX idx_project_tasks_assigned_to ON public.project_tasks(assigned_to);
CREATE INDEX idx_project_tasks_status ON public.project_tasks(status);

CREATE INDEX idx_project_invitations_project_id ON public.project_invitations(project_id);
CREATE INDEX idx_project_invitations_token ON public.project_invitations(invitation_token);
CREATE INDEX idx_project_invitations_email ON public.project_invitations(invited_email);
CREATE INDEX idx_project_invitations_status ON public.project_invitations(status);

-- 5. RLS Politikaları
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.project_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.project_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.project_invitations ENABLE ROW LEVEL SECURITY;

-- Projects RLS
CREATE POLICY "Enable all for projects" ON public.projects FOR ALL USING (true);

-- Project Members RLS
CREATE POLICY "Enable read access for project members" ON public.project_members FOR SELECT USING (true);
CREATE POLICY "Enable insert for authenticated users" ON public.project_members FOR INSERT WITH CHECK (true);
CREATE POLICY "Enable update for authenticated users" ON public.project_members FOR UPDATE USING (true);
CREATE POLICY "Enable delete for authenticated users" ON public.project_members FOR DELETE USING (true);

-- Project Tasks RLS
CREATE POLICY "Enable read access for project tasks" ON public.project_tasks FOR SELECT USING (true);
CREATE POLICY "Enable insert for project tasks" ON public.project_tasks FOR INSERT WITH CHECK (true);
CREATE POLICY "Enable update for project tasks" ON public.project_tasks FOR UPDATE USING (true);
CREATE POLICY "Enable delete for project tasks" ON public.project_tasks FOR DELETE USING (true);

-- Project Invitations RLS
CREATE POLICY "Enable read access for project invitations" ON public.project_invitations FOR SELECT USING (true);
CREATE POLICY "Enable insert for project invitations" ON public.project_invitations FOR INSERT WITH CHECK (true);
CREATE POLICY "Enable update for project invitations" ON public.project_invitations FOR UPDATE USING (true);
CREATE POLICY "Enable delete for project invitations" ON public.project_invitations FOR DELETE USING (true);

-- 6. Fonksiyonlar
-- Set config fonksiyonu
CREATE OR REPLACE FUNCTION public.set_config(setting_name TEXT, setting_value TEXT)
RETURNS TEXT AS $$
BEGIN
    PERFORM set_config(setting_name, setting_value, false);
    RETURN setting_value;
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Proje oluşturulduğunda otomatik olarak oluşturanı owner yapar
CREATE OR REPLACE FUNCTION public.add_project_owner()
RETURNS TRIGGER AS $$
BEGIN
    -- Proje oluşturanı otomatik olarak owner yap
    INSERT INTO public.project_members (project_id, user_email, user_name, role, status)
    SELECT 
        NEW.id,
        up.email,
        CONCAT(up.ad, ' ', up.soyad),
        'owner',
        'active'
    FROM public.user_profiles up
    WHERE up.email = current_setting('app.current_user_email', true);
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Görev durumu güncellendiğinde completed_at alanını güncelle
CREATE OR REPLACE FUNCTION public.update_task_completion()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'done' AND OLD.status != 'done' THEN
        NEW.completed_at = NOW();
    ELSIF NEW.status != 'done' AND OLD.status = 'done' THEN
        NEW.completed_at = NULL;
    END IF;
    
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 7. Trigger'lar
-- Proje oluşturulduğunda owner ekleme trigger'ı
CREATE TRIGGER add_project_owner_trigger
    AFTER INSERT ON public.projects
    FOR EACH ROW
    EXECUTE FUNCTION public.add_project_owner();

-- Görev güncellendiğinde completion trigger'ı
CREATE TRIGGER update_task_completion_trigger
    BEFORE UPDATE ON public.project_tasks
    FOR EACH ROW
    EXECUTE FUNCTION public.update_task_completion();

-- 8. Yorumlar
COMMENT ON TABLE public.projects IS 'Ana projeler tablosu';
COMMENT ON TABLE public.project_members IS 'Proje üyeleri tablosu - kullanıcıların projelerdeki rolleri';
COMMENT ON TABLE public.project_tasks IS 'Proje görevleri tablosu - proje içindeki görevler';
COMMENT ON TABLE public.project_invitations IS 'Proje davetleri tablosu - bekleyen davetler';

COMMENT ON COLUMN public.projects.created_by IS 'Projeyi oluşturan kullanıcının email adresi';
COMMENT ON COLUMN public.project_members.role IS 'Kullanıcının proje rolü: owner, admin, member';
COMMENT ON COLUMN public.project_members.status IS 'Üyelik durumu: active, pending, removed';
COMMENT ON COLUMN public.project_tasks.status IS 'Görev durumu: todo, in_progress, done';
COMMENT ON COLUMN public.project_tasks.priority IS 'Görev önceliği: low, medium, high';
COMMENT ON COLUMN public.project_invitations.status IS 'Davet durumu: pending, accepted, declined, expired';

-- BAŞARILI RESET MESAJI
DO $$
BEGIN
    RAISE NOTICE '✅ Tüm Project Management tabloları başarıyla oluşturuldu!';
    RAISE NOTICE '📋 Tablolar: projects, project_members, project_tasks, project_invitations';
    RAISE NOTICE '🔗 Foreign key ilişkileri kuruldu';
    RAISE NOTICE '🔒 RLS politikaları etkinleştirildi';
    RAISE NOTICE '⚡ İndeksler oluşturuldu';
    RAISE NOTICE '🔧 Trigger''lar hazır (otomatik owner ekleme dahil)';
    RAISE NOTICE '';
    RAISE NOTICE '➡️  Şimdi additional_sql_functions_fixed.sql dosyasını çalıştırabilirsiniz.';
    RAISE NOTICE '🚀 Ardından Flutter uygulamanızı test edebilirsiniz.';
END $$; 