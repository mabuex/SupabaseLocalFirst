-- Drop the table if it exists (for re-running setup)
DROP TABLE IF EXISTS todos;

-- Create the todos table
CREATE TABLE todos (
    id UUID PRIMARY KEY,
    -- Optional: For Supabase RLS security
    -- user_id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL PRIMARY KEY, 
    title TEXT NOT NULL,
    is_completed BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    deleted_at TIMESTAMP WITH TIME ZONE DEFAULT NULL
);

-- Ensure updated_at is always updated on changes
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_set_updated_at
BEFORE UPDATE ON todos
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

-- Optional: For Supabase RLS security 
-- Enable Row-Level Security
-- ALTER TABLE todos ENABLE ROW LEVEL SECURITY;

-- CREATE POLICY "Authenticated users can access their todos"
--   ON todos FOR ALL USING (auth.uid() = user_id);