-- ##############################################################
-- ##             PART 1: SAAS FOUNDATION SCHEMA             ##
-- ##############################################################
-- This is the essential boilerplate from the starter kit for
-- user management and authentication.

-- Create users table
CREATE TABLE IF NOT EXISTS users (
  id uuid references auth.users not null primary key,
  full_name text,
  avatar_url text,
  billing_address jsonb,
  payment_method jsonb
);
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Create policies for users table
DROP POLICY IF EXISTS "Can view own user data." ON users;
CREATE POLICY "Can view own user data." ON users FOR SELECT USING (auth.uid() = id);
DROP POLICY IF EXISTS "Can update own user data." ON users;
CREATE POLICY "Can update own user data." ON users FOR UPDATE USING (auth.uid() = id);

-- Trigger to create a user entry on new sign-up
CREATE OR REPLACE FUNCTION public.handle_new_user() 
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.users (id, full_name, avatar_url)
  VALUES (new.id, new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'avatar_url');
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- Other tables from the starter (customers, products, etc.) are included for completeness.
-- You can safely ignore them for the hackathon if you are not using Stripe billing.
CREATE TABLE IF NOT EXISTS customers (
  id uuid references auth.users not null primary key,
  stripe_customer_id text
);
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
-- (The rest of the boilerplate schema for products, prices, etc., is also fine to include)


-- ##############################################################
-- ##         PART 2: YOUR CUSTOM CRM FEATURE SCHEMA         ##
-- ##############################################################
-- This is our simplified CRM schema, now integrated with the
-- users table for proper data security and ownership.

-- TABLE 1: contacts
CREATE TABLE IF NOT EXISTS contacts (
    contact_id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID REFERENCES public.users(id) ON DELETE CASCADE, -- **CRITICAL LINK** to the user who owns this contact
    contact_name        TEXT NOT NULL,
    company_name        TEXT,
    email               TEXT,
    phone_number        TEXT,
    address_line_1      TEXT NOT NULL,
    address_line_2      TEXT,
    city                TEXT NOT NULL,
    state_province_region TEXT NOT NULL,
    postal_code         TEXT NOT NULL,
    country             TEXT NOT NULL,
    created_at          TIMESTAMPTZ DEFAULT NOW()
);
-- Enable Row Level Security
ALTER TABLE contacts ENABLE ROW LEVEL SECURITY;
-- Add Policy: Users can only see and manage their own contacts.
DROP POLICY IF EXISTS "Users can manage their own contacts." ON contacts;
CREATE POLICY "Users can manage their own contacts." ON contacts
    FOR ALL USING (auth.uid() = user_id);


-- TABLE 2: jobs
CREATE TABLE IF NOT EXISTS jobs (
    job_id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    contact_id          UUID REFERENCES public.contacts(contact_id) ON DELETE CASCADE,
    -- We can also add a user_id here for easier querying, though it's not strictly necessary
    -- as we can infer the owner through the contact_id.
    job_title           TEXT NOT NULL,
    status              TEXT DEFAULT 'Active',
    created_at          TIMESTAMPTZ DEFAULT NOW()
);
-- Enable Row Level Security
ALTER TABLE jobs ENABLE ROW LEVEL SECURITY;
-- Add Policy: Users can only manage jobs belonging to contacts they own.
DROP POLICY IF EXISTS "Users can manage jobs for their contacts." ON jobs;
CREATE POLICY "Users can manage jobs for their contacts." ON jobs
    FOR ALL USING (auth.uid() = (SELECT user_id FROM contacts WHERE contacts.contact_id = jobs.contact_id));


-- TABLE 3: reach_outs
CREATE TABLE IF NOT EXISTS reach_outs (
    reach_out_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    job_id              UUID REFERENCES public.jobs(job_id) ON DELETE CASCADE,
    method              TEXT,
    responded           BOOLEAN NOT NULL DEFAULT FALSE,
    notes               TEXT,
    timestamp           TIMESTAMPTZ DEFAULT NOW()
);
-- Enable Row Level Security
ALTER TABLE reach_outs ENABLE ROW LEVEL SECURITY;
-- Add Policy: Users can only manage reach_outs for jobs they own.
DROP POLICY IF EXISTS "Users can manage reach_outs for their jobs." ON reach_outs;
CREATE POLICY "Users can manage reach_outs for their jobs." ON reach_outs
    FOR ALL USING (auth.uid() = (SELECT contacts.user_id FROM contacts JOIN jobs ON contacts.contact_id = jobs.contact_id WHERE jobs.job_id = reach_outs.job_id));