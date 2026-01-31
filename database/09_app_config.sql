-- ============================================
-- PSGMX App Update Enforcement System
-- Database Schema for Remote App Control
-- ============================================

-- Create app_config table for version control
CREATE TABLE IF NOT EXISTS app_config (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Version Control
    min_required_version TEXT NOT NULL DEFAULT '1.0.0',  -- Users BELOW this are FORCED to update
    latest_version TEXT NOT NULL DEFAULT '1.0.0',        -- Latest available version
    
    -- Update Behavior
    force_update BOOLEAN NOT NULL DEFAULT false,         -- If true, min_required_version is enforced strictly
    update_message TEXT DEFAULT 'A new version of PSGMX is available with improvements and bug fixes.',
    
    -- Distribution
    github_release_url TEXT DEFAULT 'https://github.com/psgmx/psgmx-flutter/releases/latest',
    android_download_url TEXT,  -- Direct APK link if needed
    ios_download_url TEXT,      -- TestFlight or enterprise link if needed
    
    -- Emergency Controls
    emergency_block BOOLEAN NOT NULL DEFAULT false,      -- BLOCKS ALL app access when true
    emergency_message TEXT DEFAULT 'This app version has been temporarily disabled for security reasons. Please update to continue.',
    
    -- Metadata
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_by TEXT  -- Email of admin who last modified
);

-- Create trigger to auto-update updated_at
CREATE OR REPLACE FUNCTION update_app_config_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER app_config_updated_at
    BEFORE UPDATE ON app_config
    FOR EACH ROW
    EXECUTE FUNCTION update_app_config_timestamp();

-- Insert default configuration (ONLY ONE ROW should exist)
INSERT INTO app_config (
    min_required_version,
    latest_version,
    force_update,
    update_message,
    github_release_url,
    emergency_block
) VALUES (
    '1.0.0',
    '1.2.0',
    false,
    'A new version of PSGMX is available! Update now to get the latest features and improvements.',
    'https://github.com/psgmx/psgmx-flutter/releases/latest',
    false
) ON CONFLICT DO NOTHING;

-- Enable RLS (Row Level Security)
ALTER TABLE app_config ENABLE ROW LEVEL SECURITY;

-- Policy: Anyone can READ app_config (needed for version check)
CREATE POLICY "Allow public read access to app_config"
ON app_config
FOR SELECT
USING (true);

-- Policy: Only service role can UPDATE (backend admin only)
-- No authenticated users can modify this table directly
CREATE POLICY "Only service role can modify app_config"
ON app_config
FOR ALL
USING (auth.role() = 'service_role')
WITH CHECK (auth.role() = 'service_role');

-- ============================================
-- ADMIN USAGE EXAMPLES
-- ============================================

-- Example 1: Soft update available (user can skip)
-- UPDATE app_config SET
--     latest_version = '1.3.0',
--     min_required_version = '1.0.0',
--     force_update = false,
--     update_message = 'New features available! Update when convenient.';

-- Example 2: Force update (critical fix)
-- UPDATE app_config SET
--     latest_version = '1.3.0',
--     min_required_version = '1.3.0',
--     force_update = true,
--     update_message = 'This update contains critical security fixes. Please update now.';

-- Example 3: Emergency block (security incident)
-- UPDATE app_config SET
--     emergency_block = true,
--     emergency_message = 'App temporarily disabled for maintenance. Please update when available.';

-- Example 4: Release emergency block
-- UPDATE app_config SET
--     emergency_block = false;

-- ============================================
-- VERIFICATION QUERY
-- ============================================
-- SELECT * FROM app_config;
