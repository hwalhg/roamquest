ALTER TABLE subscriptions
ADD COLUMN IF NOT EXISTS latest_transaction_id VARCHAR(255);

ALTER TABLE subscriptions
ADD COLUMN IF NOT EXISTS app_store_environment VARCHAR(32);

ALTER TABLE subscriptions
ADD COLUMN IF NOT EXISTS status_code INTEGER;

ALTER TABLE subscriptions
ADD COLUMN IF NOT EXISTS verification_source VARCHAR(64) DEFAULT 'legacy_local';

ALTER TABLE subscriptions
ADD COLUMN IF NOT EXISTS verified_at TIMESTAMP WITH TIME ZONE;

CREATE INDEX IF NOT EXISTS idx_subscriptions_original_transaction
ON subscriptions(original_transaction_id);

CREATE INDEX IF NOT EXISTS idx_subscriptions_latest_transaction
ON subscriptions(latest_transaction_id);
