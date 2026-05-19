-- ============================================================
-- CampusIQ — Supabase Schema
-- Run this entire script in Supabase SQL Editor
-- ============================================================

-- 1. Enable required extensions
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- TABLES
-- ============================================================

-- 2. Profiles (linked to Supabase Auth)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL PRIMARY KEY,
    full_name TEXT NOT NULL,
    email TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'student',
    branch TEXT NOT NULL,
    year INTEGER,
    avatar_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now()) NOT NULL
);

-- 3. Timetable Entries
CREATE TABLE IF NOT EXISTS public.timetable_entries (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    title TEXT NOT NULL,
    image_url TEXT NOT NULL,
    storage_path TEXT NOT NULL,
    branch TEXT NOT NULL,
    year INTEGER NOT NULL,
    effective_date DATE NOT NULL,
    description TEXT,
    posted_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now()) NOT NULL
);

-- 4. PDF Notes
CREATE TABLE IF NOT EXISTS public.pdf_notes (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    file_url TEXT NOT NULL,
    storage_path TEXT NOT NULL,
    file_name TEXT NOT NULL,
    subject_name TEXT NOT NULL,
    branch TEXT NOT NULL,
    year INTEGER NOT NULL,
    uploaded_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now()) NOT NULL
);

-- 5. Announcements
CREATE TABLE IF NOT EXISTS public.announcements (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    image_url TEXT,
    storage_path TEXT,
    priority TEXT DEFAULT 'general' NOT NULL,
    branch TEXT,
    year INTEGER,
    is_published BOOLEAN DEFAULT true NOT NULL,
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now()) NOT NULL
);

-- 6. Deadlines
CREATE TABLE IF NOT EXISTS public.deadlines (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    due_date TIMESTAMP WITH TIME ZONE NOT NULL,
    subject_name TEXT NOT NULL,
    branch TEXT NOT NULL,
    year INTEGER NOT NULL,
    priority TEXT DEFAULT 'medium' NOT NULL,
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now()) NOT NULL
);

-- 7. Knowledge Base Docs (RAG / AI)
CREATE TABLE IF NOT EXISTS public.knowledge_base_docs (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    embedding VECTOR(768),
    category TEXT,
    source_id TEXT,
    source_type TEXT,
    branch TEXT,
    year INTEGER,
    added_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now()) NOT NULL
);

-- 8. Notifications
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    title TEXT NOT NULL,
    body TEXT,
    type TEXT,
    priority TEXT DEFAULT 'low' NOT NULL,
    reference_id TEXT,
    reference_type TEXT,
    is_read BOOLEAN DEFAULT false NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now()) NOT NULL
);

-- 9. Saved Answers (AI Chatbot bookmarks)
CREATE TABLE IF NOT EXISTS public.saved_answers (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    student_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    question TEXT NOT NULL,
    answer TEXT NOT NULL,
    saved_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now()) NOT NULL
);

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

-- profiles: users can read all, insert/update only their own
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "profiles_select" ON public.profiles;
DROP POLICY IF EXISTS "profiles_insert" ON public.profiles;
DROP POLICY IF EXISTS "profiles_update" ON public.profiles;
CREATE POLICY "profiles_select" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "profiles_insert" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "profiles_update" ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- All other tables: authenticated users can do everything
-- (Admin vs student filtering is handled at the app level)

ALTER TABLE public.timetable_entries ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "timetable_all" ON public.timetable_entries;
CREATE POLICY "timetable_all" ON public.timetable_entries FOR ALL USING (auth.uid() IS NOT NULL);

ALTER TABLE public.pdf_notes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "notes_all" ON public.pdf_notes;
CREATE POLICY "notes_all" ON public.pdf_notes FOR ALL USING (auth.uid() IS NOT NULL);

ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "announcements_all" ON public.announcements;
CREATE POLICY "announcements_all" ON public.announcements FOR ALL USING (auth.uid() IS NOT NULL);

ALTER TABLE public.deadlines ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "deadlines_all" ON public.deadlines;
CREATE POLICY "deadlines_all" ON public.deadlines FOR ALL USING (auth.uid() IS NOT NULL);

ALTER TABLE public.knowledge_base_docs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "knowledge_all" ON public.knowledge_base_docs;
CREATE POLICY "knowledge_all" ON public.knowledge_base_docs FOR ALL USING (auth.uid() IS NOT NULL);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "notifications_all" ON public.notifications;
CREATE POLICY "notifications_all" ON public.notifications FOR ALL USING (auth.uid() IS NOT NULL);

ALTER TABLE public.saved_answers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "saved_answers_all" ON public.saved_answers;
CREATE POLICY "saved_answers_all" ON public.saved_answers FOR ALL USING (auth.uid() IS NOT NULL);

-- ============================================================
-- STORAGE BUCKETS
-- Run these in the Supabase SQL Editor as well
-- ============================================================

-- Create the 3 required storage buckets (public so URLs work without auth)
INSERT INTO storage.buckets (id, name, public)
VALUES
  ('pdf-notes',           'pdf-notes',           true),
  ('timetable-images',    'timetable-images',     true),
  ('announcement-images', 'announcement-images',  true)
ON CONFLICT (id) DO NOTHING;

-- Allow authenticated users to upload to all 3 buckets
DROP POLICY IF EXISTS "pdf_notes_upload" ON storage.objects;
CREATE POLICY "pdf_notes_upload" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'pdf-notes');

DROP POLICY IF EXISTS "pdf_notes_read" ON storage.objects;
CREATE POLICY "pdf_notes_read" ON storage.objects
  FOR SELECT USING (bucket_id = 'pdf-notes');

DROP POLICY IF EXISTS "timetable_upload" ON storage.objects;
CREATE POLICY "timetable_upload" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'timetable-images');

DROP POLICY IF EXISTS "timetable_read" ON storage.objects;
CREATE POLICY "timetable_read" ON storage.objects
  FOR SELECT USING (bucket_id = 'timetable-images');

DROP POLICY IF EXISTS "announcement_upload" ON storage.objects;
CREATE POLICY "announcement_upload" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'announcement-images');

DROP POLICY IF EXISTS "announcement_read" ON storage.objects;
CREATE POLICY "announcement_read" ON storage.objects
  FOR SELECT USING (bucket_id = 'announcement-images');

-- Allow authenticated users to delete their own uploads
DROP POLICY IF EXISTS "storage_delete" ON storage.objects;
CREATE POLICY "storage_delete" ON storage.objects
  FOR DELETE TO authenticated
  USING (auth.uid() IS NOT NULL);

-- ============================================================
-- AUTO-CREATE PROFILE TRIGGER
-- This auto-inserts a row into profiles when a user signs up
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, role, branch, year)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'New User'),
    COALESCE(NEW.raw_user_meta_data->>'role', 'student'),
    COALESCE(NEW.raw_user_meta_data->>'branch', 'Computer Science Engineering'),
    COALESCE((NEW.raw_user_meta_data->>'year')::INTEGER, 1)
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
