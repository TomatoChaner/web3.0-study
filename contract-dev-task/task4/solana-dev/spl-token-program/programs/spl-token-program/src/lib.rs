use anchor_lang::prelude::*;
use anchor_spl::token::{self, Mint, Token, TokenAccount, Transfer, MintTo, Burn};

declare_id!("J4JSTCBSasaHUKPFju135wi54VMwtc7Jz4ieLLAZxHR9");

#[program]
pub mod spl_token_program {
    use super::*;

    /// 初始化代币铸造账户
    pub fn initialize_mint(
        ctx: Context<InitializeMint>,
        decimals: u8,
        name: String,
        symbol: String,
    ) -> Result<()> {
        let token_metadata = &mut ctx.accounts.token_metadata;
        token_metadata.authority = ctx.accounts.authority.key();
        token_metadata.mint = ctx.accounts.mint.key();
        token_metadata.name = name;
        token_metadata.symbol = symbol;
        token_metadata.decimals = decimals;
        token_metadata.total_supply = 0;
        
        msg!("Token mint initialized: {}", ctx.accounts.mint.key());
        msg!("Name: {}, Symbol: {}, Decimals: {}", token_metadata.name, token_metadata.symbol, decimals);
        Ok(())
    }

    /// 铸造代币
    pub fn mint_tokens(
        ctx: Context<MintTokens>,
        amount: u64,
    ) -> Result<()> {
        let token_metadata = &mut ctx.accounts.token_metadata;
        
        // 检查权限
        require!(
            ctx.accounts.authority.key() == token_metadata.authority,
            ErrorCode::UnauthorizedMintAuthority
        );

        // 铸造代币
        let cpi_accounts = MintTo {
            mint: ctx.accounts.mint.to_account_info(),
            to: ctx.accounts.token_account.to_account_info(),
            authority: ctx.accounts.authority.to_account_info(),
        };
        let cpi_program = ctx.accounts.token_program.to_account_info();
        let cpi_ctx = CpiContext::new(cpi_program, cpi_accounts);
        
        token::mint_to(cpi_ctx, amount)?;
        
        // 更新总供应量
        token_metadata.total_supply = token_metadata.total_supply.checked_add(amount)
            .ok_or(ErrorCode::MathOverflow)?;
        
        msg!("Minted {} tokens to {}", amount, ctx.accounts.token_account.key());
        Ok(())
    }

    /// 转账代币
    pub fn transfer_tokens(
        ctx: Context<TransferTokens>,
        amount: u64,
    ) -> Result<()> {
        let cpi_accounts = Transfer {
            from: ctx.accounts.from.to_account_info(),
            to: ctx.accounts.to.to_account_info(),
            authority: ctx.accounts.authority.to_account_info(),
        };
        let cpi_program = ctx.accounts.token_program.to_account_info();
        let cpi_ctx = CpiContext::new(cpi_program, cpi_accounts);
        
        token::transfer(cpi_ctx, amount)?;
        
        msg!("Transferred {} tokens from {} to {}", 
             amount, 
             ctx.accounts.from.key(), 
             ctx.accounts.to.key());
        Ok(())
    }

    /// 销毁代币
    pub fn burn_tokens(
        ctx: Context<BurnTokens>,
        amount: u64,
    ) -> Result<()> {
        let token_metadata = &mut ctx.accounts.token_metadata;
        
        let cpi_accounts = Burn {
            mint: ctx.accounts.mint.to_account_info(),
            from: ctx.accounts.token_account.to_account_info(),
            authority: ctx.accounts.authority.to_account_info(),
        };
        let cpi_program = ctx.accounts.token_program.to_account_info();
        let cpi_ctx = CpiContext::new(cpi_program, cpi_accounts);
        
        token::burn(cpi_ctx, amount)?;
        
        // 更新总供应量
        token_metadata.total_supply = token_metadata.total_supply.checked_sub(amount)
            .ok_or(ErrorCode::MathUnderflow)?;
        
        msg!("Burned {} tokens from {}", amount, ctx.accounts.token_account.key());
        Ok(())
    }

    /// 更新铸造权限
    pub fn update_mint_authority(
        ctx: Context<UpdateMintAuthority>,
        new_authority: Option<Pubkey>,
    ) -> Result<()> {
        let token_metadata = &mut ctx.accounts.token_metadata;
        
        // 检查当前权限
        require!(
            ctx.accounts.current_authority.key() == token_metadata.authority,
            ErrorCode::UnauthorizedMintAuthority
        );

        // 更新权限
        if let Some(new_auth) = new_authority {
            token_metadata.authority = new_auth;
            msg!("Mint authority updated to: {}", new_auth);
        } else {
            // 如果设置为None，则禁用铸造功能
            token_metadata.authority = Pubkey::default();
            msg!("Mint authority disabled");
        }
        
        Ok(())
    }

    /// 获取代币信息
    pub fn get_token_info(ctx: Context<GetTokenInfo>) -> Result<()> {
        let token_metadata = &ctx.accounts.token_metadata;
        
        msg!("Token Info:");
        msg!("  Mint: {}", token_metadata.mint);
        msg!("  Name: {}", token_metadata.name);
        msg!("  Symbol: {}", token_metadata.symbol);
        msg!("  Decimals: {}", token_metadata.decimals);
        msg!("  Total Supply: {}", token_metadata.total_supply);
        msg!("  Authority: {}", token_metadata.authority);
        
        Ok(())
    }
}

// 账户结构定义

#[derive(Accounts)]
#[instruction(decimals: u8, name: String, symbol: String)]
pub struct InitializeMint<'info> {
    #[account(
        init,
        payer = authority,
        mint::decimals = decimals,
        mint::authority = authority,
    )]
    pub mint: Account<'info, Mint>,
    
    #[account(
        init,
        payer = authority,
        space = 8 + TokenMetadata::INIT_SPACE,
        seeds = [b"metadata", mint.key().as_ref()],
        bump
    )]
    pub token_metadata: Account<'info, TokenMetadata>,
    
    #[account(mut)]
    pub authority: Signer<'info>,
    
    pub token_program: Program<'info, Token>,
    pub system_program: Program<'info, System>,
    pub rent: Sysvar<'info, Rent>,
}

#[derive(Accounts)]
pub struct MintTokens<'info> {
    #[account(mut)]
    pub mint: Account<'info, Mint>,
    
    #[account(
        mut,
        seeds = [b"metadata", mint.key().as_ref()],
        bump
    )]
    pub token_metadata: Account<'info, TokenMetadata>,
    
    #[account(
        mut,
        associated_token::mint = mint,
        associated_token::authority = recipient,
    )]
    pub token_account: Account<'info, TokenAccount>,
    
    /// CHECK: This is the recipient of the tokens
    pub recipient: AccountInfo<'info>,
    
    pub authority: Signer<'info>,
    pub token_program: Program<'info, Token>,
}

#[derive(Accounts)]
pub struct TransferTokens<'info> {
    #[account(
        mut,
        associated_token::mint = mint,
        associated_token::authority = authority,
    )]
    pub from: Account<'info, TokenAccount>,
    
    #[account(mut)]
    pub to: Account<'info, TokenAccount>,
    
    pub mint: Account<'info, Mint>,
    pub authority: Signer<'info>,
    pub token_program: Program<'info, Token>,
}

#[derive(Accounts)]
pub struct BurnTokens<'info> {
    #[account(mut)]
    pub mint: Account<'info, Mint>,
    
    #[account(
        mut,
        seeds = [b"metadata", mint.key().as_ref()],
        bump
    )]
    pub token_metadata: Account<'info, TokenMetadata>,
    
    #[account(
        mut,
        associated_token::mint = mint,
        associated_token::authority = authority,
    )]
    pub token_account: Account<'info, TokenAccount>,
    
    pub authority: Signer<'info>,
    pub token_program: Program<'info, Token>,
}

#[derive(Accounts)]
pub struct UpdateMintAuthority<'info> {
    #[account(
        mut,
        seeds = [b"metadata", mint.key().as_ref()],
        bump
    )]
    pub token_metadata: Account<'info, TokenMetadata>,
    
    pub mint: Account<'info, Mint>,
    pub current_authority: Signer<'info>,
}

#[derive(Accounts)]
pub struct GetTokenInfo<'info> {
    #[account(
        seeds = [b"metadata", mint.key().as_ref()],
        bump
    )]
    pub token_metadata: Account<'info, TokenMetadata>,
    
    pub mint: Account<'info, Mint>,
}

// 数据结构定义

#[account]
#[derive(InitSpace)]
pub struct TokenMetadata {
    pub authority: Pubkey,
    pub mint: Pubkey,
    #[max_len(32)]
    pub name: String,
    #[max_len(10)]
    pub symbol: String,
    pub decimals: u8,
    pub total_supply: u64,
}

// 错误定义

#[error_code]
pub enum ErrorCode {
    #[msg("Unauthorized mint authority")]
    UnauthorizedMintAuthority,
    #[msg("Math overflow")]
    MathOverflow,
    #[msg("Math underflow")]
    MathUnderflow,
}
