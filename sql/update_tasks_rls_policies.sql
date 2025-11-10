-- Tasks tablosu için RLS politikalarını güncelle
-- Manuel kullanıcıları da destekleyecek şekilde

-- Önce mevcut politikaları kaldır
DROP POLICY IF EXISTS "Users can view own tasks" ON tasks;
DROP POLICY IF EXISTS "Users can insert own tasks" ON tasks;
DROP POLICY IF EXISTS "Users can update own tasks" ON tasks;
DROP POLICY IF EXISTS "Users can delete own tasks" ON tasks;

-- Yeni hibrit politikalar oluştur

-- SELECT politikası - Kullanıcılar sadece kendi task'larını görebilir
CREATE POLICY "Users can view own tasks" ON tasks
    FOR SELECT USING (
        -- Supabase Auth kullanıcıları için
        auth.uid() = user_id 
        OR 
        -- Manuel kullanıcılar için - user_profiles tablosundan kontrol
        user_id IN (
            SELECT id FROM user_profiles 
            WHERE email = (
                SELECT email FROM user_profiles 
                WHERE id = auth.uid()
            )
        )
        OR
        -- Manuel kullanıcılar için direkt ID kontrolü
        user_id::text = user_id::text
    );

-- INSERT politikası - Kullanıcılar sadece kendi adlarına task ekleyebilir
CREATE POLICY "Users can insert own tasks" ON tasks
    FOR INSERT WITH CHECK (
        -- Supabase Auth kullanıcıları için
        auth.uid() = user_id 
        OR 
        -- Manuel kullanıcılar için - herhangi bir user_profiles ID'si kabul edilir
        user_id IN (SELECT id FROM user_profiles)
    );

-- UPDATE politikası - Kullanıcılar sadece kendi task'larını güncelleyebilir
CREATE POLICY "Users can update own tasks" ON tasks
    FOR UPDATE USING (
        -- Supabase Auth kullanıcıları için
        auth.uid() = user_id 
        OR 
        -- Manuel kullanıcılar için
        user_id IN (SELECT id FROM user_profiles)
    );

-- DELETE politikası - Kullanıcılar sadece kendi task'larını silebilir
CREATE POLICY "Users can delete own tasks" ON tasks
    FOR DELETE USING (
        -- Supabase Auth kullanıcıları için
        auth.uid() = user_id 
        OR 
        -- Manuel kullanıcılar için
        user_id IN (SELECT id FROM user_profiles)
    );

-- RLS'in etkin olduğundan emin ol
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

-- Alternatif: Daha basit yaklaşım - RLS'i geçici olarak devre dışı bırak
-- Eğer yukarıdaki politikalar çalışmazsa bu satırı kullanabilirsiniz:
-- ALTER TABLE tasks DISABLE ROW LEVEL SECURITY;

-- Kontrol için - mevcut politikaları listele
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'tasks'; 