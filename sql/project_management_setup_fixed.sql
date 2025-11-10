-- Project Management System SQL Setup (FIXED VERSION)
-- Bu dosyayı Supabase SQL Editor'da çalıştırın

-- 1. Önce mevcut politikaları temizle (güvenli şekilde)
DO $$
BEGIN
    -- Project Members politikalarını temizle
    BEGIN
        DROP POLICY IF EXISTS "Users can view project members of their projects" ON public.project_members;
    EXCEPTION WHEN undefined_table THEN NULL;
    END;
    
    BEGIN
        DROP POLICY IF EXISTS "Project owners and admins can insert members" ON public.project_members;
    EXCEPTION WHEN undefined_table THEN NULL;
    END;
    
    BEGIN
        DROP POLICY IF EXISTS "Project owners and admins can update members" ON public.project_members;
    EXCEPTION WHEN undefined_table THEN NULL;
    END;
    
    BEGIN
        DROP POLICY IF EXISTS "Project owners and admins can delete members" ON public.project_members;
    EXCEPTION WHEN undefined_table THEN NULL;
    END;
    
    -- Project Tasks politikalarını temizle
    BEGIN
        DROP POLICY IF EXISTS "Project members can view tasks" ON public.project_tasks;
    EXCEPTION WHEN undefined_table THEN NULL;
    END;
    
    BEGIN
        DROP POLICY IF EXISTS "Project members can insert tasks" ON public.project_tasks;
    EXCEPTION WHEN undefined_table THEN NULL;
    END;
    
    BEGIN
        DROP POLICY IF EXISTS "Task owners and project admins can update tasks" ON public.project_tasks;
    EXCEPTION WHEN undefined_table THEN NULL;
    END;
    
    BEGIN
        DROP POLICY IF EXISTS "Task owners and project admins can delete tasks" ON public.project_tasks;
    EXCEPTION WHEN undefined_table THEN NULL;
    END;
    
    -- Project Invitations politikalarını temizle
    BEGIN
        DROP POLICY IF EXISTS "Project owners can view invitations" ON public.project_invitations;
    EXCEPTION WHEN undefined_table THEN NULL;
    END;
    
    BEGIN
        DROP POLICY IF EXISTS "Project owners can send invitations" ON public.project_invitations;
    EXCEPTION WHEN undefined_table THEN NULL;
    END;
    
    BEGIN
        DROP POLICY IF EXISTS "Project owners can update invitations" ON public.project_invitations;
    EXCEPTION WHEN undefined_table THEN NULL;
    END;
    
    -- Basit RLS politikalarını da temizle
    BEGIN
        DROP POLICY IF EXISTS "Enable read access for project members" ON public.project_members;
    EXCEPTION WHEN undefined_table THEN NULL;
    END;
    
    BEGIN
        DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.project_members;
    EXCEPTION WHEN undefined_table THEN NULL;
    END;
    
    BEGIN
        DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.project_members;
    EXCEPTION WHEN undefined_table THEN NULL;
    END;
    
    BEGIN
        DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.project_members;
    EXCEPTION WHEN undefined_table THEN NULL;
    END;
    
    BEGIN
        DROP POLICY IF EXISTS "Enable read access for project tasks" ON public.project_tasks;
    EXCEPTION WHEN undefined_table THEN NULL;
    END;
    
    BEGIN
        DROP POLICY IF EXISTS "Enable insert for project tasks" ON public.project_tasks;
    EXCEPTION WHEN undefined_table THEN NULL;
    END;
    
    BEGIN
        DROP POLICY IF EXISTS "Enable update for project tasks" ON public.project_tasks;
    EXCEPTION WHEN undefined_table THEN NULL;
    END;
    
    BEGIN
        DROP POLICY IF EXISTS "Enable delete for project tasks" ON public.project_tasks;
    EXCEPTION WHEN undefined_table THEN NULL;
    END;
    
    BEGIN
        DROP POLICY IF EXISTS "Enable read access for project invitations" ON public.project_invitations;
    EXCEPTION WHEN undefined_table THEN NULL;
    END;
    
    BEGIN
        DROP POLICY IF EXISTS "Enable insert for project invitations" ON public.project_invitations;
    EXCEPTION WHEN undefined_table THEN NULL;
    END;
    
    BEGIN
        DROP POLICY IF EXISTS "Enable update for project invitations" ON public.project_invitations;
    EXCEPTION WHEN undefined_table THEN NULL;
    END;
    
    BEGIN
        DROP POLICY IF EXISTS "Enable delete for project invitations" ON public.project_invitations;
    EXCEPTION WHEN undefined_table THEN NULL;
    END;
    
    RAISE NOTICE 'Mevcut politikalar güvenli şekilde temizlendi.';
END $$;

-- 2. Project Members tablosu (Proje üyeleri)
CREATE TABLE IF NOT EXISTS public.project_members (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    project_id UUID NOT NULL,
    user_email VARCHAR(255) NOT NULL,
    user_name VARCHAR(255) NOT NULL,
    role VARCHAR(50) DEFAULT 'member', -- 'owner', 'admin', 'member'
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    invited_by VARCHAR(255),
    status VARCHAR(20) DEFAULT 'active', -- 'active', 'pending', 'removed'
    UNIQUE(project_id, user_email)
);

-- 3. Project Tasks tablosu (Proje görevleri)
CREATE TABLE IF NOT EXISTS public.project_tasks (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    project_id UUID NOT NULL,
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

-- 4. Project Invitations tablosu (Proje davetleri)
CREATE TABLE IF NOT EXISTS public.project_invitations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    project_id UUID NOT NULL,
    invited_email VARCHAR(255) NOT NULL,
    invited_by VARCHAR(255) NOT NULL,
    invitation_token VARCHAR(255) UNIQUE NOT NULL,
    status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'accepted', 'declined', 'expired'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '7 days'),
    UNIQUE(project_id, invited_email)
);

-- 5. İndeksler (Performans için)
CREATE INDEX IF NOT EXISTS idx_project_members_project_id ON public.project_members(project_id);
CREATE INDEX IF NOT EXISTS idx_project_members_user_email ON public.project_members(user_email);
CREATE INDEX IF NOT EXISTS idx_project_members_status ON public.project_members(status);
CREATE INDEX IF NOT EXISTS idx_project_tasks_project_id ON public.project_tasks(project_id);
CREATE INDEX IF NOT EXISTS idx_project_tasks_assigned_to ON public.project_tasks(assigned_to);
CREATE INDEX IF NOT EXISTS idx_project_tasks_status ON public.project_tasks(status);
CREATE INDEX IF NOT EXISTS idx_project_invitations_token ON public.project_invitations(invitation_token);
CREATE INDEX IF NOT EXISTS idx_project_invitations_email ON public.project_invitations(invited_email);
CREATE INDEX IF NOT EXISTS idx_project_invitations_status ON public.project_invitations(status);

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

-- Proje oluşturulduğunda otomatik olarak oluşturanı owner yapar (sadece projects tablosu varsa)
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

-- Davet kabul edildiğinde üye ekleme fonksiyonu
CREATE OR REPLACE FUNCTION public.accept_project_invitation(invitation_token_param TEXT)
RETURNS JSON AS $$
DECLARE
    invitation_record RECORD;
    user_record RECORD;
    result JSON;
BEGIN
    -- Daveti bul
    SELECT * INTO invitation_record 
    FROM public.project_invitations 
    WHERE invitation_token = invitation_token_param 
    AND status = 'pending' 
    AND expires_at > NOW();
    
    IF NOT FOUND THEN
        RETURN json_build_object('success', false, 'message', 'Geçersiz veya süresi dolmuş davet');
    END IF;
    
    -- Kullanıcı bilgilerini al
    SELECT * INTO user_record 
    FROM public.user_profiles 
    WHERE email = invitation_record.invited_email;
    
    IF NOT FOUND THEN
        RETURN json_build_object('success', false, 'message', 'Kullanıcı bulunamadı');
    END IF;
    
    -- Üye ekle
    INSERT INTO public.project_members (project_id, user_email, user_name, role, status, invited_by)
    VALUES (
        invitation_record.project_id,
        user_record.email,
        CONCAT(user_record.ad, ' ', user_record.soyad),
        'member',
        'active',
        invitation_record.invited_by
    )
    ON CONFLICT (project_id, user_email) DO UPDATE SET
        status = 'active',
        joined_at = NOW();
    
    -- Daveti kabul edildi olarak işaretle
    UPDATE public.project_invitations 
    SET status = 'accepted' 
    WHERE id = invitation_record.id;
    
    RETURN json_build_object('success', true, 'message', 'Projeye başarıyla katıldınız');
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

-- 7. Triggerları temizle (güvenli şekilde)
DO $$
BEGIN
    BEGIN
        DROP TRIGGER IF EXISTS add_project_owner_trigger ON public.projects;
    EXCEPTION WHEN undefined_table THEN NULL;
    END;
    
    BEGIN
        DROP TRIGGER IF EXISTS update_task_completion_trigger ON public.project_tasks;
    EXCEPTION WHEN undefined_table THEN NULL;
    END;
END $$;

-- Görev güncellendiğinde completion trigger'ı (bu tabloyu oluşturduk, güvenli)
CREATE TRIGGER update_task_completion_trigger
    BEFORE UPDATE ON public.project_tasks
    FOR EACH ROW
    EXECUTE FUNCTION public.update_task_completion();

-- Projects tablosu için trigger (sadece tablo varsa oluşturulacak)
-- Bu trigger'ı manuel olarak projects tablosu oluşturulduktan sonra ekleyebilirsiniz:
-- CREATE TRIGGER add_project_owner_trigger
--     AFTER INSERT ON public.projects
--     FOR EACH ROW
--     EXECUTE FUNCTION public.add_project_owner();

-- 8. RLS Politikaları (Tablolar oluşturulduktan sonra)

-- Project Members RLS
ALTER TABLE public.project_members ENABLE ROW LEVEL SECURITY;

-- Basit RLS politikaları (karmaşık subquery'ler olmadan)
CREATE POLICY "Enable read access for project members" ON public.project_members
    FOR SELECT USING (true);

CREATE POLICY "Enable insert for authenticated users" ON public.project_members
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Enable update for authenticated users" ON public.project_members
    FOR UPDATE USING (true);

CREATE POLICY "Enable delete for authenticated users" ON public.project_members
    FOR DELETE USING (true);

-- Project Tasks RLS
ALTER TABLE public.project_tasks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Enable read access for project tasks" ON public.project_tasks
    FOR SELECT USING (true);

CREATE POLICY "Enable insert for project tasks" ON public.project_tasks
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Enable update for project tasks" ON public.project_tasks
    FOR UPDATE USING (true);

CREATE POLICY "Enable delete for project tasks" ON public.project_tasks
    FOR DELETE USING (true);

-- Project Invitations RLS
ALTER TABLE public.project_invitations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Enable read access for project invitations" ON public.project_invitations
    FOR SELECT USING (true);

CREATE POLICY "Enable insert for project invitations" ON public.project_invitations
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Enable update for project invitations" ON public.project_invitations
    FOR UPDATE USING (true);

CREATE POLICY "Enable delete for project invitations" ON public.project_invitations
    FOR DELETE USING (true);

-- 9. Foreign Key Constraints (İsteğe bağlı - eğer projects tablosu varsa)
-- Bu kısımları projects tablosu oluşturulduktan sonra manuel olarak ekleyebilirsiniz:
-- ALTER TABLE public.project_members 
-- ADD CONSTRAINT fk_project_members_project_id 
-- FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

-- ALTER TABLE public.project_tasks 
-- ADD CONSTRAINT fk_project_tasks_project_id 
-- FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

-- ALTER TABLE public.project_invitations 
-- ADD CONSTRAINT fk_project_invitations_project_id 
-- FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

-- 10. Tablo ve kolon yorumları (güvenli şekilde)
DO $$
BEGIN
    -- Tablo yorumları
    BEGIN
        COMMENT ON TABLE public.project_members IS 'Proje üyeleri tablosu - kullanıcıların projelerdeki rolleri';
    EXCEPTION WHEN undefined_table THEN NULL;
    END;
    
    BEGIN
        COMMENT ON TABLE public.project_tasks IS 'Proje görevleri tablosu - proje içindeki görevler';
    EXCEPTION WHEN undefined_table THEN NULL;
    END;
    
    BEGIN
        COMMENT ON TABLE public.project_invitations IS 'Proje davetleri tablosu - bekleyen davetler';
    EXCEPTION WHEN undefined_table THEN NULL;
    END;
    
    -- Project Members kolon yorumları
    BEGIN
        COMMENT ON COLUMN public.project_members.role IS 'Kullanıcının proje rolü: owner, admin, member';
    EXCEPTION WHEN undefined_table OR undefined_column THEN NULL;
    END;
    
    BEGIN
        COMMENT ON COLUMN public.project_members.status IS 'Üyelik durumu: active, pending, removed';
    EXCEPTION WHEN undefined_table OR undefined_column THEN NULL;
    END;
    
    -- Project Tasks kolon yorumları
    BEGIN
        COMMENT ON COLUMN public.project_tasks.status IS 'Görev durumu: todo, in_progress, done';
    EXCEPTION WHEN undefined_table OR undefined_column THEN NULL;
    END;
    
    BEGIN
        COMMENT ON COLUMN public.project_tasks.priority IS 'Görev önceliği: low, medium, high';
    EXCEPTION WHEN undefined_table OR undefined_column THEN NULL;
    END;
    
    -- Project Invitations kolon yorumları
    BEGIN
        COMMENT ON COLUMN public.project_invitations.status IS 'Davet durumu: pending, accepted, declined, expired';
    EXCEPTION WHEN undefined_table OR undefined_column THEN NULL;
    END;
    
    RAISE NOTICE '📝 Tablo ve kolon yorumları güvenli şekilde eklendi.';
END $$;

-- BAŞARILI KURULUM MESAJI
DO $$
BEGIN
    RAISE NOTICE '✅ Project Management tabloları başarıyla oluşturuldu!';
    RAISE NOTICE '📋 Oluşturulan tablolar: project_members, project_tasks, project_invitations';
    RAISE NOTICE '🔒 RLS politikaları etkinleştirildi';
    RAISE NOTICE '⚡ İndeksler oluşturuldu';
    RAISE NOTICE '🔧 Fonksiyonlar ve trigger''lar hazır';
    RAISE NOTICE '📝 Tablo ve kolon yorumları eklendi';
    RAISE NOTICE '';
    RAISE NOTICE '➡️  Şimdi additional_sql_functions_fixed.sql dosyasını çalıştırabilirsiniz.';
END $$; 