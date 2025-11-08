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

-- Add the rest of the boilerplate schema for products, prices, etc.
DO $$ BEGIN
    CREATE TYPE pricing_type AS ENUM ('one_time', 'recurring');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE pricing_plan_interval AS ENUM ('day', 'week', 'month', 'year');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

CREATE TABLE IF NOT EXISTS products (
  id text primary key,
  active boolean,
  name text,
  description text,
  image text,
  metadata jsonb
);
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public read-only access." ON products;
CREATE POLICY "Allow public read-only access." ON products FOR SELECT USING (true);

CREATE TABLE IF NOT EXISTS prices (
  id text primary key,
  product_id text references products, 
  active boolean,
  description text,
  unit_amount bigint,
  currency text check (char_length(currency) = 3),
  type pricing_type,
  interval pricing_plan_interval,
  interval_count integer,
  trial_period_days integer,
  metadata jsonb
);
ALTER TABLE prices ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public read-only access." ON prices;
CREATE POLICY "Allow public read-only access." ON prices FOR SELECT USING (true);

DO $$ BEGIN
    CREATE TYPE subscription_status AS ENUM ('trialing', 'active', 'canceled', 'incomplete', 'incomplete_expired', 'past_due', 'unpaid', 'paused');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

CREATE TABLE IF NOT EXISTS subscriptions (
  id text primary key,
  user_id uuid references auth.users not null,
  status subscription_status,
  metadata jsonb,
  price_id text references prices,
  quantity integer,
  cancel_at_period_end boolean,
  created timestamp with time zone default timezone('utc'::text, now()) not null,
  current_period_start timestamp with time zone default timezone('utc'::text, now()) not null,
  current_period_end timestamp with time zone default timezone('utc'::text, now()) not null,
  ended_at timestamp with time zone default timezone('utc'::text, now()),
  cancel_at timestamp with time zone default timezone('utc'::text, now()),
  canceled_at timestamp with time zone default timezone('utc'::text, now()),
  trial_start timestamp with time zone default timezone('utc'::text, now()),
  trial_end timestamp with time zone default timezone('utc'::text, now())
);
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Can only view own subs data." ON subscriptions;
CREATE POLICY "Can only view own subs data." ON subscriptions FOR SELECT USING (auth.uid() = user_id);


-- ##############################################################
-- ##         PART 2: YOUR CUSTOM CRM FEATURE SCHEMA         ##
-- ##############################################################
-- This is our simplified CRM schema, now integrated with the
-- users table for proper data security and ownership.

-- TABLE 1: contacts (aligned with Mei Way Mail Plus spreadsheet)
CREATE TABLE IF NOT EXISTS contacts (
    contact_id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID REFERENCES public.users(id) ON DELETE CASCADE, -- **CRITICAL LINK** to the user who owns this contact
    company_name        TEXT,
    unit_number         TEXT,  -- Mailbox/Unit identifier (e.g., F14-F15, F17, C8)
    contact_person      TEXT,  -- Primary contact name
    language_preference TEXT,  -- e.g., English, Mandarin, English/Mandarin
    email               TEXT,
    phone_number        TEXT,
    service_tier        INTEGER, -- 1, 2, etc.
    options             TEXT,  -- Special notes like "*High Volume"
    mailbox_number      TEXT,  -- Physical mailbox assignment (e.g., D1, D2, D3)
    status              TEXT DEFAULT 'PENDING', -- Active, PENDING, No
    created_at          TIMESTAMPTZ DEFAULT NOW()
);
-- Enable Row Level Security
ALTER TABLE contacts ENABLE ROW LEVEL SECURITY;
-- Add Policy: Users can only see and manage their own contacts.
DROP POLICY IF EXISTS "Users can manage their own contacts." ON contacts;
CREATE POLICY "Users can manage their own contacts." ON contacts
    FOR ALL USING (auth.uid() = user_id);


-- TABLE 2: mail_items (formerly jobs - tracks individual mail/packages)
CREATE TABLE IF NOT EXISTS mail_items (
    mail_item_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    contact_id          UUID REFERENCES public.contacts(contact_id) ON DELETE CASCADE,
    item_type           TEXT DEFAULT 'Package', -- Package, Letter, Certified Mail, etc.
    description         TEXT, -- Brief note about the item
    received_date       TIMESTAMPTZ DEFAULT NOW(),
    status              TEXT DEFAULT 'Received', -- Received, Notified, Picked Up, Returned
    pickup_date         TIMESTAMPTZ,
    created_at          TIMESTAMPTZ DEFAULT NOW()
);
-- Enable Row Level Security
ALTER TABLE mail_items ENABLE ROW LEVEL SECURITY;
-- Add Policy: Users can only manage mail items belonging to contacts they own.
DROP POLICY IF EXISTS "Users can manage mail items for their contacts." ON mail_items;
CREATE POLICY "Users can manage mail items for their contacts." ON mail_items
    FOR ALL USING (auth.uid() = (SELECT user_id FROM contacts WHERE contacts.contact_id = mail_items.contact_id));


-- TABLE 3: outreach_messages (formerly reach_outs - tracks all communications)
CREATE TABLE IF NOT EXISTS outreach_messages (
    message_id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mail_item_id        UUID REFERENCES public.mail_items(mail_item_id) ON DELETE CASCADE,
    contact_id          UUID REFERENCES public.contacts(contact_id) ON DELETE CASCADE,
    message_type        TEXT, -- Initial Notification, Reminder, Pickup Confirmed
    channel             TEXT, -- Email, SMS, WeChat, Phone
    message_content     TEXT, -- The actual message sent
    sent_at             TIMESTAMPTZ DEFAULT NOW(),
    responded           BOOLEAN NOT NULL DEFAULT FALSE,
    response_date       TIMESTAMPTZ,
    follow_up_needed    BOOLEAN DEFAULT TRUE,
    follow_up_date      TIMESTAMPTZ, -- Auto-set to 24-48h after sent_at
    notes               TEXT
);
-- Enable Row Level Security
ALTER TABLE outreach_messages ENABLE ROW LEVEL SECURITY;
-- Add Policy: Users can only manage outreach messages for their contacts.
DROP POLICY IF EXISTS "Users can manage outreach for their contacts." ON outreach_messages;
CREATE POLICY "Users can manage outreach for their contacts." ON outreach_messages
    FOR ALL USING (auth.uid() = (SELECT contacts.user_id FROM contacts WHERE contacts.contact_id = outreach_messages.contact_id));


-- TABLE 4: message_templates (predefined message templates for quick sending)
CREATE TABLE IF NOT EXISTS message_templates (
    template_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID REFERENCES public.users(id) ON DELETE CASCADE,
    template_name       TEXT NOT NULL, -- e.g., "Mail Received", "Pickup Reminder", "Pickup Confirmed"
    template_type       TEXT NOT NULL, -- Initial, Reminder, Confirmation, Custom
    subject_line        TEXT, -- For emails
    message_body        TEXT NOT NULL, -- Can include {{variables}} like {{contact_name}}, {{item_type}}
    default_channel     TEXT DEFAULT 'Email', -- Email, SMS, Both
    is_default          BOOLEAN DEFAULT FALSE, -- System default templates
    created_at          TIMESTAMPTZ DEFAULT NOW()
);
-- Enable Row Level Security
ALTER TABLE message_templates ENABLE ROW LEVEL SECURITY;
-- Add Policy: Users can manage their own templates and see default templates.
DROP POLICY IF EXISTS "Users can manage their templates." ON message_templates;
CREATE POLICY "Users can manage their templates." ON message_templates
    FOR ALL USING (auth.uid() = user_id OR is_default = TRUE);

-- Create publication for realtime subscriptions (including CRM tables)
DROP PUBLICATION IF EXISTS supabase_realtime;
CREATE PUBLICATION supabase_realtime FOR TABLE products, prices, contacts, mail_items, outreach_messages, message_templates;