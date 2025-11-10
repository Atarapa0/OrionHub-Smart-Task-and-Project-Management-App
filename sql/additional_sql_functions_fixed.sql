-- Additional SQL Functions for Project Management (FIXED VERSION)
-- Bu dosyayı Supabase SQL Editor'da çalıştırın

-- 1. Set Config fonksiyonu (kullanıcı context'i için)
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

-- 2. Kullanıcı email'ini kontrol eden fonksiyon
CREATE OR REPLACE FUNCTION public.get_current_user_email()
RETURNS TEXT AS $$
BEGIN
    RETURN current_setting('app.current_user_email', true);
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Proje üyesi olup olmadığını kontrol eden fonksiyon
CREATE OR REPLACE FUNCTION public.is_project_member(project_id_param UUID, user_email_param TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.project_members 
        WHERE project_id = project_id_param 
        AND user_email = user_email_param 
        AND status = 'active'
    );
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Kullanıcının proje rolünü getiren fonksiyon
CREATE OR REPLACE FUNCTION public.get_user_project_role(project_id_param UUID, user_email_param TEXT)
RETURNS TEXT AS $$
DECLARE
    user_role TEXT;
BEGIN
    SELECT role INTO user_role 
    FROM public.project_members 
    WHERE project_id = project_id_param 
    AND user_email = user_email_param 
    AND status = 'active';
    
    RETURN COALESCE(user_role, 'none');
EXCEPTION
    WHEN OTHERS THEN
        RETURN 'none';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Proje istatistiklerini getiren fonksiyon
CREATE OR REPLACE FUNCTION public.get_project_statistics(project_id_param UUID)
RETURNS JSON AS $$
DECLARE
    stats JSON;
    total_members INTEGER;
BEGIN
    -- Görev istatistikleri
    SELECT json_build_object(
        'total_tasks', COUNT(*),
        'completed_tasks', COUNT(*) FILTER (WHERE status = 'done'),
        'in_progress_tasks', COUNT(*) FILTER (WHERE status = 'in_progress'),
        'todo_tasks', COUNT(*) FILTER (WHERE status = 'todo'),
        'high_priority_tasks', COUNT(*) FILTER (WHERE priority = 'high'),
        'overdue_tasks', COUNT(*) FILTER (WHERE due_date < NOW() AND status != 'done')
    ) INTO stats
    FROM public.project_tasks
    WHERE project_id = project_id_param;
    
    -- Üye sayısını al
    SELECT COUNT(*) INTO total_members
    FROM public.project_members
    WHERE project_id = project_id_param AND status = 'active';
    
    -- Üye sayısını stats'a ekle
    SELECT json_build_object(
        'total_tasks', (stats->>'total_tasks')::INTEGER,
        'completed_tasks', (stats->>'completed_tasks')::INTEGER,
        'in_progress_tasks', (stats->>'in_progress_tasks')::INTEGER,
        'todo_tasks', (stats->>'todo_tasks')::INTEGER,
        'high_priority_tasks', (stats->>'high_priority_tasks')::INTEGER,
        'overdue_tasks', (stats->>'overdue_tasks')::INTEGER,
        'total_members', total_members,
        'completion_rate', 
            CASE 
                WHEN (stats->>'total_tasks')::INTEGER > 0 
                THEN ROUND(((stats->>'completed_tasks')::FLOAT / (stats->>'total_tasks')::FLOAT) * 100)
                ELSE 0 
            END
    ) INTO stats;
    
    RETURN stats;
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'total_tasks', 0,
            'completed_tasks', 0,
            'in_progress_tasks', 0,
            'todo_tasks', 0,
            'high_priority_tasks', 0,
            'overdue_tasks', 0,
            'total_members', 0,
            'completion_rate', 0
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Kullanıcının projelerini getiren fonksiyon
CREATE OR REPLACE FUNCTION public.get_user_projects(user_email_param TEXT)
RETURNS TABLE(
    project_id UUID,
    project_title TEXT,
    project_description TEXT,
    project_created_at TIMESTAMPTZ,
    user_role TEXT,
    joined_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.title,
        p.description,
        p.created_at,
        pm.role,
        pm.joined_at
    FROM public.projects p
    INNER JOIN public.project_members pm ON p.id = pm.project_id
    WHERE pm.user_email = user_email_param
    AND pm.status = 'active'
    ORDER BY pm.joined_at DESC;
EXCEPTION
    WHEN OTHERS THEN
        RETURN;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. Proje üyelerini getiren fonksiyon
CREATE OR REPLACE FUNCTION public.get_project_members_with_stats(project_id_param UUID)
RETURNS TABLE(
    member_id UUID,
    user_email TEXT,
    user_name TEXT,
    role TEXT,
    joined_at TIMESTAMPTZ,
    task_count BIGINT,
    completed_task_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pm.id,
        pm.user_email,
        pm.user_name,
        pm.role,
        pm.joined_at,
        COALESCE(task_stats.total_tasks, 0) as task_count,
        COALESCE(task_stats.completed_tasks, 0) as completed_task_count
    FROM public.project_members pm
    LEFT JOIN (
        SELECT 
            assigned_to,
            COUNT(*) as total_tasks,
            COUNT(*) FILTER (WHERE status = 'done') as completed_tasks
        FROM public.project_tasks
        WHERE project_id = project_id_param
        GROUP BY assigned_to
    ) task_stats ON pm.user_email = task_stats.assigned_to
    WHERE pm.project_id = project_id_param
    AND pm.status = 'active'
    ORDER BY pm.joined_at;
EXCEPTION
    WHEN OTHERS THEN
        RETURN;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. Görev bildirimlerini getiren fonksiyon
CREATE OR REPLACE FUNCTION public.get_user_task_notifications(user_email_param TEXT)
RETURNS TABLE(
    task_id UUID,
    project_title TEXT,
    task_title TEXT,
    due_date TIMESTAMPTZ,
    priority TEXT,
    days_until_due INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pt.id,
        p.title,
        pt.title,
        pt.due_date,
        pt.priority,
        EXTRACT(DAY FROM (pt.due_date - NOW()))::INTEGER
    FROM public.project_tasks pt
    INNER JOIN public.projects p ON pt.project_id = p.id
    WHERE pt.assigned_to = user_email_param
    AND pt.status != 'done'
    AND pt.due_date IS NOT NULL
    AND pt.due_date > NOW()
    AND pt.due_date <= NOW() + INTERVAL '7 days'
    ORDER BY pt.due_date;
EXCEPTION
    WHEN OTHERS THEN
        RETURN;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9. Proje aktivitelerini getiren fonksiyon
CREATE OR REPLACE FUNCTION public.get_project_activities(project_id_param UUID, limit_param INTEGER DEFAULT 20)
RETURNS TABLE(
    activity_type TEXT,
    description TEXT,
    user_email TEXT,
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    (
        SELECT 
            'task_created'::TEXT,
            'Yeni görev oluşturuldu: ' || pt.title,
            COALESCE(pt.assigned_by, 'system'),
            pt.created_at
        FROM public.project_tasks pt
        WHERE pt.project_id = project_id_param
        
        UNION ALL
        
        SELECT 
            'task_completed'::TEXT,
            'Görev tamamlandı: ' || pt.title,
            COALESCE(pt.assigned_to, 'system'),
            pt.completed_at
        FROM public.project_tasks pt
        WHERE pt.project_id = project_id_param
        AND pt.completed_at IS NOT NULL
        
        UNION ALL
        
        SELECT 
            'member_joined'::TEXT,
            pm.user_name || ' projeye katıldı',
            COALESCE(pm.invited_by, 'system'),
            pm.joined_at
        FROM public.project_members pm
        WHERE pm.project_id = project_id_param
        AND pm.status = 'active'
    )
    ORDER BY created_at DESC
    LIMIT limit_param;
EXCEPTION
    WHEN OTHERS THEN
        RETURN;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 10. Proje arama fonksiyonu
CREATE OR REPLACE FUNCTION public.search_projects(search_query TEXT, user_email_param TEXT)
RETURNS TABLE(
    project_id UUID,
    title TEXT,
    description TEXT,
    created_at TIMESTAMPTZ,
    user_role TEXT,
    member_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.title,
        p.description,
        p.created_at,
        pm.role,
        COALESCE(member_counts.member_count, 0)
    FROM public.projects p
    INNER JOIN public.project_members pm ON p.id = pm.project_id
    LEFT JOIN (
        SELECT 
            project_id,
            COUNT(*) as member_count
        FROM public.project_members
        WHERE status = 'active'
        GROUP BY project_id
    ) member_counts ON p.id = member_counts.project_id
    WHERE pm.user_email = user_email_param
    AND pm.status = 'active'
    AND (
        p.title ILIKE '%' || search_query || '%'
        OR p.description ILIKE '%' || search_query || '%'
    )
    ORDER BY p.created_at DESC;
EXCEPTION
    WHEN OTHERS THEN
        RETURN;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 11. Kullanıcı arama fonksiyonu (proje üyesi ekleme için)
CREATE OR REPLACE FUNCTION public.search_users_for_project(search_query TEXT, project_id_param UUID)
RETURNS TABLE(
    email TEXT,
    full_name TEXT,
    ad TEXT,
    soyad TEXT,
    is_already_member BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        up.email,
        CONCAT(up.ad, ' ', up.soyad) as full_name,
        up.ad,
        up.soyad,
        EXISTS(
            SELECT 1 FROM public.project_members pm 
            WHERE pm.project_id = project_id_param 
            AND pm.user_email = up.email 
            AND pm.status = 'active'
        ) as is_already_member
    FROM public.user_profiles up
    WHERE (
        up.email ILIKE '%' || search_query || '%'
        OR up.ad ILIKE '%' || search_query || '%'
        OR up.soyad ILIKE '%' || search_query || '%'
        OR CONCAT(up.ad, ' ', up.soyad) ILIKE '%' || search_query || '%'
    )
    AND LENGTH(search_query) >= 2
    ORDER BY 
        is_already_member ASC,
        up.ad, up.soyad
    LIMIT 10;
EXCEPTION
    WHEN OTHERS THEN
        RETURN;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 12. Proje silme fonksiyonu (cascade delete)
CREATE OR REPLACE FUNCTION public.delete_project_cascade(project_id_param UUID, user_email_param TEXT)
RETURNS JSON AS $$
DECLARE
    user_role TEXT;
BEGIN
    -- Kullanıcının proje sahibi olup olmadığını kontrol et
    SELECT role INTO user_role
    FROM public.project_members
    WHERE project_id = project_id_param
    AND user_email = user_email_param
    AND status = 'active';
    
    IF user_role != 'owner' THEN
        RETURN json_build_object('success', false, 'message', 'Sadece proje sahibi projeyi silebilir');
    END IF;
    
    -- Proje ile ilgili tüm verileri sil
    DELETE FROM public.project_invitations WHERE project_id = project_id_param;
    DELETE FROM public.project_tasks WHERE project_id = project_id_param;
    DELETE FROM public.project_members WHERE project_id = project_id_param;
    DELETE FROM public.projects WHERE id = project_id_param;
    
    RETURN json_build_object('success', true, 'message', 'Proje başarıyla silindi');
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object('success', false, 'message', 'Proje silinirken hata oluştu: ' || SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonksiyonlara yorum ekle
COMMENT ON FUNCTION public.set_config IS 'Kullanıcı context ayarları için - hata kontrolü ile';
COMMENT ON FUNCTION public.get_current_user_email IS 'Mevcut kullanıcının email adresini döndürür - hata kontrolü ile';
COMMENT ON FUNCTION public.is_project_member IS 'Kullanıcının proje üyesi olup olmadığını kontrol eder - hata kontrolü ile';
COMMENT ON FUNCTION public.get_user_project_role IS 'Kullanıcının proje rolünü döndürür - hata kontrolü ile';
COMMENT ON FUNCTION public.get_project_statistics IS 'Proje istatistiklerini JSON formatında döndürür - tamamlanma oranı ile';
COMMENT ON FUNCTION public.get_user_projects IS 'Kullanıcının projelerini döndürür - hata kontrolü ile';
COMMENT ON FUNCTION public.get_project_members_with_stats IS 'Proje üyelerini görev istatistikleriyle döndürür - hata kontrolü ile';
COMMENT ON FUNCTION public.get_user_task_notifications IS 'Kullanıcının yaklaşan görev bildirimlerini döndürür - hata kontrolü ile';
COMMENT ON FUNCTION public.get_project_activities IS 'Proje aktivitelerini döndürür - hata kontrolü ile';
COMMENT ON FUNCTION public.search_projects IS 'Proje arama fonksiyonu - hata kontrolü ile';
COMMENT ON FUNCTION public.search_users_for_project IS 'Proje için kullanıcı arama - üyelik durumu kontrolü ile';
COMMENT ON FUNCTION public.delete_project_cascade IS 'Proje ve ilgili tüm verileri güvenli şekilde siler'; 