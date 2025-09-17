-- 创建用户表
CREATE TABLE IF NOT EXISTS users (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    wallet_address TEXT UNIQUE NOT NULL,
    email TEXT,
    username TEXT,
    avatar_url TEXT,
    total_staked DECIMAL(20, 8) DEFAULT 0,
    total_rewards_earned DECIMAL(20, 8) DEFAULT 0,
    stake_count INTEGER DEFAULT 0,
    last_stake_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建质押记录表
CREATE TABLE IF NOT EXISTS stake_records (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_wallet TEXT NOT NULL REFERENCES users(wallet_address) ON DELETE CASCADE,
    amount DECIMAL(20, 8) NOT NULL,
    transaction_hash TEXT UNIQUE NOT NULL,
    block_number BIGINT NOT NULL,
    stake_type TEXT NOT NULL CHECK (stake_type IN ('stake', 'unstake', 'partial_unstake')),
    gas_used BIGINT,
    gas_price DECIMAL(20, 8),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建奖励记录表
CREATE TABLE IF NOT EXISTS reward_records (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_wallet TEXT NOT NULL REFERENCES users(wallet_address) ON DELETE CASCADE,
    amount DECIMAL(20, 8) NOT NULL,
    transaction_hash TEXT UNIQUE NOT NULL,
    block_number BIGINT NOT NULL,
    reward_type TEXT NOT NULL CHECK (reward_type IN ('claim', 'auto_compound')),
    gas_used BIGINT,
    gas_price DECIMAL(20, 8),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建每日统计表
CREATE TABLE IF NOT EXISTS daily_stats (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    date DATE UNIQUE NOT NULL,
    total_staked DECIMAL(20, 8) NOT NULL DEFAULT 0,
    total_users INTEGER NOT NULL DEFAULT 0,
    total_rewards_distributed DECIMAL(20, 8) NOT NULL DEFAULT 0,
    average_stake_amount DECIMAL(20, 8) NOT NULL DEFAULT 0,
    new_users_count INTEGER DEFAULT 0,
    active_users_count INTEGER DEFAULT 0,
    total_transactions INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建通知表
CREATE TABLE IF NOT EXISTS notifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_wallet TEXT NOT NULL REFERENCES users(wallet_address) ON DELETE CASCADE,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('info', 'success', 'warning', 'error')),
    read BOOLEAN DEFAULT FALSE,
    action_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建合约事件日志表
CREATE TABLE IF NOT EXISTS contract_events (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    event_name TEXT NOT NULL,
    contract_address TEXT NOT NULL,
    transaction_hash TEXT NOT NULL,
    block_number BIGINT NOT NULL,
    log_index INTEGER NOT NULL,
    user_address TEXT,
    event_data JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(transaction_hash, log_index)
);

-- 创建系统配置表
CREATE TABLE IF NOT EXISTS system_config (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    key TEXT UNIQUE NOT NULL,
    value TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_users_wallet_address ON users(wallet_address);
CREATE INDEX IF NOT EXISTS idx_stake_records_user_wallet ON stake_records(user_wallet);
CREATE INDEX IF NOT EXISTS idx_stake_records_created_at ON stake_records(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_stake_records_transaction_hash ON stake_records(transaction_hash);
CREATE INDEX IF NOT EXISTS idx_reward_records_user_wallet ON reward_records(user_wallet);
CREATE INDEX IF NOT EXISTS idx_reward_records_created_at ON reward_records(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_reward_records_transaction_hash ON reward_records(transaction_hash);
CREATE INDEX IF NOT EXISTS idx_daily_stats_date ON daily_stats(date DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_user_wallet ON notifications(user_wallet);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON notifications(read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_contract_events_event_name ON contract_events(event_name);
CREATE INDEX IF NOT EXISTS idx_contract_events_user_address ON contract_events(user_address);
CREATE INDEX IF NOT EXISTS idx_contract_events_block_number ON contract_events(block_number DESC);

-- 创建触发器函数：自动更新 updated_at 字段
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 为需要的表创建触发器
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_daily_stats_updated_at BEFORE UPDATE ON daily_stats
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_notifications_updated_at BEFORE UPDATE ON notifications
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_system_config_updated_at BEFORE UPDATE ON system_config
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 插入初始系统配置
INSERT INTO system_config (key, value, description) VALUES
    ('contract_address', '', 'StakeContract deployed address'),
    ('token_address', '', 'MetaNodeToken deployed address'),
    ('network_id', '1', 'Blockchain network ID'),
    ('min_stake_amount', '0.01', 'Minimum stake amount in ETH'),
    ('max_stake_amount', '100', 'Maximum stake amount in ETH'),
    ('reward_rate', '10', 'Annual reward rate percentage'),
    ('emergency_withdraw_enabled', 'false', 'Emergency withdraw status'),
    ('contract_paused', 'false', 'Contract pause status')
ON CONFLICT (key) DO NOTHING;

-- 创建视图：用户统计
CREATE OR REPLACE VIEW user_stats AS
SELECT 
    u.wallet_address,
    u.username,
    u.total_staked,
    u.total_rewards_earned,
    u.stake_count,
    u.last_stake_date,
    COALESCE(sr.total_stake_amount, 0) as calculated_total_staked,
    COALESCE(rr.total_reward_amount, 0) as calculated_total_rewards,
    COALESCE(sr.stake_transaction_count, 0) as calculated_stake_count,
    u.created_at as user_since
FROM users u
LEFT JOIN (
    SELECT 
        user_wallet,
        SUM(CASE WHEN stake_type = 'stake' THEN amount ELSE -amount END) as total_stake_amount,
        COUNT(*) as stake_transaction_count
    FROM stake_records 
    GROUP BY user_wallet
) sr ON u.wallet_address = sr.user_wallet
LEFT JOIN (
    SELECT 
        user_wallet,
        SUM(amount) as total_reward_amount
    FROM reward_records 
    GROUP BY user_wallet
) rr ON u.wallet_address = rr.user_wallet;

-- 创建视图：每日活跃用户
CREATE OR REPLACE VIEW daily_active_users AS
SELECT 
    DATE(created_at) as date,
    COUNT(DISTINCT user_wallet) as active_users
FROM (
    SELECT user_wallet, created_at FROM stake_records
    UNION ALL
    SELECT user_wallet, created_at FROM reward_records
) combined_activity
GROUP BY DATE(created_at)
ORDER BY date DESC;

-- 启用行级安全 (RLS)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE stake_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE reward_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- 创建 RLS 策略（用户只能访问自己的数据）
CREATE POLICY "Users can view own data" ON users
    FOR SELECT USING (wallet_address = current_setting('app.current_user_wallet', true));

CREATE POLICY "Users can update own data" ON users
    FOR UPDATE USING (wallet_address = current_setting('app.current_user_wallet', true));

CREATE POLICY "Users can view own stake records" ON stake_records
    FOR SELECT USING (user_wallet = current_setting('app.current_user_wallet', true));

CREATE POLICY "Users can view own reward records" ON reward_records
    FOR SELECT USING (user_wallet = current_setting('app.current_user_wallet', true));

CREATE POLICY "Users can view own notifications" ON notifications
    FOR SELECT USING (user_wallet = current_setting('app.current_user_wallet', true));

CREATE POLICY "Users can update own notifications" ON notifications
    FOR UPDATE USING (user_wallet = current_setting('app.current_user_wallet', true));

-- 创建函数：设置当前用户钱包地址
CREATE OR REPLACE FUNCTION set_current_user_wallet(wallet_addr TEXT)
RETURNS void AS $$
BEGIN
    PERFORM set_config('app.current_user_wallet', wallet_addr, true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 创建函数：获取用户完整统计信息
CREATE OR REPLACE FUNCTION get_user_complete_stats(wallet_addr TEXT)
RETURNS TABLE (
    wallet_address TEXT,
    total_staked DECIMAL,
    total_rewards DECIMAL,
    stake_count INTEGER,
    last_activity TIMESTAMP WITH TIME ZONE,
    rank INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        us.wallet_address,
        us.calculated_total_staked,
        us.calculated_total_rewards,
        us.calculated_stake_count,
        GREATEST(
            COALESCE(MAX(sr.created_at), '1970-01-01'::timestamp with time zone),
            COALESCE(MAX(rr.created_at), '1970-01-01'::timestamp with time zone)
        ) as last_activity,
        RANK() OVER (ORDER BY us.calculated_total_staked DESC)::INTEGER as rank
    FROM user_stats us
    LEFT JOIN stake_records sr ON us.wallet_address = sr.user_wallet
    LEFT JOIN reward_records rr ON us.wallet_address = rr.user_wallet
    WHERE us.wallet_address = wallet_addr
    GROUP BY us.wallet_address, us.calculated_total_staked, us.calculated_total_rewards, us.calculated_stake_count;
END;
$$ LANGUAGE plpgsql;