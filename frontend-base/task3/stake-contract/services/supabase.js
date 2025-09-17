const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

class SupabaseService {
    constructor() {
        this.supabaseUrl = process.env.SUPABASE_URL;
        this.supabaseKey = process.env.SUPABASE_ANON_KEY;
        
        if (!this.supabaseUrl || !this.supabaseKey) {
            throw new Error('Supabase URL and Key must be provided');
        }
        
        this.supabase = createClient(this.supabaseUrl, this.supabaseKey);
    }

    // 用户相关操作
    async createUser(userData) {
        try {
            const { data, error } = await this.supabase
                .from('users')
                .insert([{
                    wallet_address: userData.walletAddress,
                    email: userData.email,
                    username: userData.username,
                    created_at: new Date().toISOString()
                }])
                .select();

            if (error) throw error;
            return { success: true, data: data[0] };
        } catch (error) {
            console.error('Error creating user:', error);
            return { success: false, error: error.message };
        }
    }

    async getUserByWallet(walletAddress) {
        try {
            const { data, error } = await this.supabase
                .from('users')
                .select('*')
                .eq('wallet_address', walletAddress.toLowerCase())
                .single();

            if (error && error.code !== 'PGRST116') throw error;
            return { success: true, data };
        } catch (error) {
            console.error('Error fetching user:', error);
            return { success: false, error: error.message };
        }
    }

    async updateUser(walletAddress, updateData) {
        try {
            const { data, error } = await this.supabase
                .from('users')
                .update({
                    ...updateData,
                    updated_at: new Date().toISOString()
                })
                .eq('wallet_address', walletAddress.toLowerCase())
                .select();

            if (error) throw error;
            return { success: true, data: data[0] };
        } catch (error) {
            console.error('Error updating user:', error);
            return { success: false, error: error.message };
        }
    }

    // 质押记录操作
    async createStakeRecord(stakeData) {
        try {
            const { data, error } = await this.supabase
                .from('stake_records')
                .insert([{
                    user_wallet: stakeData.userWallet.toLowerCase(),
                    amount: stakeData.amount,
                    transaction_hash: stakeData.transactionHash,
                    block_number: stakeData.blockNumber,
                    stake_type: stakeData.stakeType || 'stake',
                    created_at: new Date().toISOString()
                }])
                .select();

            if (error) throw error;
            return { success: true, data: data[0] };
        } catch (error) {
            console.error('Error creating stake record:', error);
            return { success: false, error: error.message };
        }
    }

    async getUserStakeRecords(walletAddress, limit = 50) {
        try {
            const { data, error } = await this.supabase
                .from('stake_records')
                .select('*')
                .eq('user_wallet', walletAddress.toLowerCase())
                .order('created_at', { ascending: false })
                .limit(limit);

            if (error) throw error;
            return { success: true, data };
        } catch (error) {
            console.error('Error fetching stake records:', error);
            return { success: false, error: error.message };
        }
    }

    // 奖励记录操作
    async createRewardRecord(rewardData) {
        try {
            const { data, error } = await this.supabase
                .from('reward_records')
                .insert([{
                    user_wallet: rewardData.userWallet.toLowerCase(),
                    amount: rewardData.amount,
                    transaction_hash: rewardData.transactionHash,
                    block_number: rewardData.blockNumber,
                    reward_type: rewardData.rewardType || 'claim',
                    created_at: new Date().toISOString()
                }])
                .select();

            if (error) throw error;
            return { success: true, data: data[0] };
        } catch (error) {
            console.error('Error creating reward record:', error);
            return { success: false, error: error.message };
        }
    }

    async getUserRewardRecords(walletAddress, limit = 50) {
        try {
            const { data, error } = await this.supabase
                .from('reward_records')
                .select('*')
                .eq('user_wallet', walletAddress.toLowerCase())
                .order('created_at', { ascending: false })
                .limit(limit);

            if (error) throw error;
            return { success: true, data };
        } catch (error) {
            console.error('Error fetching reward records:', error);
            return { success: false, error: error.message };
        }
    }

    // 统计数据操作
    async updateDailyStats(statsData) {
        try {
            const today = new Date().toISOString().split('T')[0];
            
            const { data, error } = await this.supabase
                .from('daily_stats')
                .upsert([{
                    date: today,
                    total_staked: statsData.totalStaked,
                    total_users: statsData.totalUsers,
                    total_rewards_distributed: statsData.totalRewardsDistributed,
                    average_stake_amount: statsData.averageStakeAmount,
                    updated_at: new Date().toISOString()
                }])
                .select();

            if (error) throw error;
            return { success: true, data: data[0] };
        } catch (error) {
            console.error('Error updating daily stats:', error);
            return { success: false, error: error.message };
        }
    }

    async getDailyStats(days = 30) {
        try {
            const { data, error } = await this.supabase
                .from('daily_stats')
                .select('*')
                .order('date', { ascending: false })
                .limit(days);

            if (error) throw error;
            return { success: true, data };
        } catch (error) {
            console.error('Error fetching daily stats:', error);
            return { success: false, error: error.message };
        }
    }

    // 通知操作
    async createNotification(notificationData) {
        try {
            const { data, error } = await this.supabase
                .from('notifications')
                .insert([{
                    user_wallet: notificationData.userWallet.toLowerCase(),
                    title: notificationData.title,
                    message: notificationData.message,
                    type: notificationData.type,
                    read: false,
                    created_at: new Date().toISOString()
                }])
                .select();

            if (error) throw error;
            return { success: true, data: data[0] };
        } catch (error) {
            console.error('Error creating notification:', error);
            return { success: false, error: error.message };
        }
    }

    async getUserNotifications(walletAddress, unreadOnly = false) {
        try {
            let query = this.supabase
                .from('notifications')
                .select('*')
                .eq('user_wallet', walletAddress.toLowerCase())
                .order('created_at', { ascending: false });

            if (unreadOnly) {
                query = query.eq('read', false);
            }

            const { data, error } = await query;

            if (error) throw error;
            return { success: true, data };
        } catch (error) {
            console.error('Error fetching notifications:', error);
            return { success: false, error: error.message };
        }
    }

    async markNotificationAsRead(notificationId) {
        try {
            const { data, error } = await this.supabase
                .from('notifications')
                .update({ read: true, updated_at: new Date().toISOString() })
                .eq('id', notificationId)
                .select();

            if (error) throw error;
            return { success: true, data: data[0] };
        } catch (error) {
            console.error('Error marking notification as read:', error);
            return { success: false, error: error.message };
        }
    }

    // 实时订阅
    subscribeToUserNotifications(walletAddress, callback) {
        return this.supabase
            .channel('user-notifications')
            .on('postgres_changes', {
                event: 'INSERT',
                schema: 'public',
                table: 'notifications',
                filter: `user_wallet=eq.${walletAddress.toLowerCase()}`
            }, callback)
            .subscribe();
    }

    // 健康检查
    async healthCheck() {
        try {
            const { data, error } = await this.supabase
                .from('users')
                .select('count')
                .limit(1);

            if (error) throw error;
            return { success: true, message: 'Supabase connection healthy' };
        } catch (error) {
            console.error('Supabase health check failed:', error);
            return { success: false, error: error.message };
        }
    }
}

module.exports = SupabaseService;