package contract

import (
	"context"
	"fmt"
	"math/big"
	"time"

	"github.com/gagliardetto/solana-go"
	"github.com/sirupsen/logrus"

	"solana-go-assignment/internal/config"
	"solana-go-assignment/internal/utils"
	"solana-go-assignment/pkg/chain"
)

// TokenSwapProgram represents the Solana Token Swap program
const TokenSwapProgram = "SwaPpA9LAaLfeLi3a68M4DjnLqgtticKg6CnyNwgAC8"

// SwapDirection represents the direction of a token swap
type SwapDirection int

const (
	SwapDirectionAToB SwapDirection = iota
	SwapDirectionBToA
)

// TokenInfo represents information about a token
type TokenInfo struct {
	Mint     solana.PublicKey `json:"mint"`
	Symbol   string           `json:"symbol"`
	Name     string           `json:"name"`
	Decimals uint8            `json:"decimals"`
	Supply   uint64           `json:"supply"`
}

// PoolInfo represents information about a liquidity pool
type PoolInfo struct {
	Address        solana.PublicKey `json:"address"`
	TokenA         TokenInfo        `json:"token_a"`
	TokenB         TokenInfo        `json:"token_b"`
	ReserveA       uint64           `json:"reserve_a"`
	ReserveB       uint64           `json:"reserve_b"`
	LPTokenMint    solana.PublicKey `json:"lp_token_mint"`
	LPTokenSupply  uint64           `json:"lp_token_supply"`
	FeeNumerator   uint64           `json:"fee_numerator"`
	FeeDenominator uint64           `json:"fee_denominator"`
	TradingEnabled bool             `json:"trading_enabled"`
}

// SwapQuote represents a swap quote
type SwapQuote struct {
	InputAmount       uint64  `json:"input_amount"`
	OutputAmount      uint64  `json:"output_amount"`
	MinOutput         uint64  `json:"min_output"`
	PriceImpact       float64 `json:"price_impact"`
	Fee               uint64  `json:"fee"`
	ExchangeRate      float64 `json:"exchange_rate"`
	SlippageTolerance float64 `json:"slippage_tolerance"`
}

// LiquidityQuote represents a liquidity provision quote
type LiquidityQuote struct {
	TokenAAmount  uint64  `json:"token_a_amount"`
	TokenBAmount  uint64  `json:"token_b_amount"`
	LPTokenAmount uint64  `json:"lp_token_amount"`
	ShareOfPool   float64 `json:"share_of_pool"`
}

// SwapResult represents the result of a swap transaction
type SwapResult struct {
	Signature    string    `json:"signature"`
	InputAmount  uint64    `json:"input_amount"`
	OutputAmount uint64    `json:"output_amount"`
	Fee          uint64    `json:"fee"`
	PriceImpact  float64   `json:"price_impact"`
	Timestamp    time.Time `json:"timestamp"`
	Status       string    `json:"status"`
}

// TokenSwapClient manages token swap operations
type TokenSwapClient struct {
	chainClient *chain.Client
	network     config.NetworkType
	logger      *logrus.Logger
}

// NewTokenSwapClient creates a new token swap client
func NewTokenSwapClient(chainClient *chain.Client, network config.NetworkType) *TokenSwapClient {
	logger := logrus.New()
	logger.SetLevel(logrus.InfoLevel)

	return &TokenSwapClient{
		chainClient: chainClient,
		network:     network,
		logger:      logger,
	}
}

// GetTokenInfo retrieves information about a token
func (c *TokenSwapClient) GetTokenInfo(ctx context.Context, mintAddress string) (*TokenInfo, error) {
	mint, err := solana.PublicKeyFromBase58(mintAddress)
	if err != nil {
		return nil, fmt.Errorf("invalid mint address: %v", err)
	}

	// Get mint account info
	_, err = c.chainClient.GetAccountInfo(ctx, mintAddress)
	if err != nil {
		return nil, fmt.Errorf("failed to get mint account info: %v", err)
	}

	// Parse mint data (simplified - in real implementation, you'd parse the actual mint data)
	tokenInfo := &TokenInfo{
		Mint:     mint,
		Symbol:   "UNKNOWN",
		Name:     "Unknown Token",
		Decimals: 9, // Default decimals
		Supply:   0,
	}

	c.logger.WithFields(logrus.Fields{
		"mint":     utils.FormatAddress(mint),
		"decimals": tokenInfo.Decimals,
	}).Debug("Retrieved token info")

	return tokenInfo, nil
}

// GetPoolInfo retrieves information about a liquidity pool
func (c *TokenSwapClient) GetPoolInfo(ctx context.Context, poolAddress string) (*PoolInfo, error) {
	pool, err := solana.PublicKeyFromBase58(poolAddress)
	if err != nil {
		return nil, fmt.Errorf("invalid pool address: %v", err)
	}

	// Get pool account info
	_, err = c.chainClient.GetAccountInfo(ctx, poolAddress)
	if err != nil {
		return nil, fmt.Errorf("failed to get pool account info: %v", err)
	}

	// In a real implementation, you would parse the pool account data
	// For now, we'll create a mock pool info
	poolInfo := &PoolInfo{
		Address:        pool,
		TokenA:         TokenInfo{Decimals: 9},
		TokenB:         TokenInfo{Decimals: 6},
		ReserveA:       1000000000, // 1000 tokens with 9 decimals
		ReserveB:       500000000,  // 500 tokens with 6 decimals
		LPTokenSupply:  707106781,  // sqrt(1000 * 500) * 1000
		FeeNumerator:   25,         // 0.25%
		FeeDenominator: 10000,
		TradingEnabled: true,
	}

	c.logger.WithFields(logrus.Fields{
		"pool":      utils.FormatAddress(pool),
		"reserve_a": poolInfo.ReserveA,
		"reserve_b": poolInfo.ReserveB,
	}).Debug("Retrieved pool info")

	return poolInfo, nil
}

// GetSwapQuote calculates a swap quote
func (c *TokenSwapClient) GetSwapQuote(ctx context.Context, poolAddress string, inputMint string, outputMint string, inputAmount uint64, slippageTolerance float64) (*SwapQuote, error) {
	poolInfo, err := c.GetPoolInfo(ctx, poolAddress)
	if err != nil {
		return nil, fmt.Errorf("failed to get pool info: %v", err)
	}

	// Determine swap direction
	var reserveIn, reserveOut uint64
	
	inputMintKey, err := solana.PublicKeyFromBase58(inputMint)
	if err != nil {
		return nil, fmt.Errorf("invalid input mint: %v", err)
	}

	if inputMintKey.Equals(poolInfo.TokenA.Mint) {
		reserveIn = poolInfo.ReserveA
		reserveOut = poolInfo.ReserveB
	} else {
		reserveIn = poolInfo.ReserveB
		reserveOut = poolInfo.ReserveA
	}

	// Calculate output amount using constant product formula (x * y = k)
	feeMultiplier := poolInfo.FeeDenominator - poolInfo.FeeNumerator
	
	numerator := new(big.Int).Mul(
		new(big.Int).SetUint64(inputAmount),
		new(big.Int).Mul(
			new(big.Int).SetUint64(uint64(feeMultiplier)),
			new(big.Int).SetUint64(reserveOut),
		),
	)
	
	denominator := new(big.Int).Add(
		new(big.Int).Mul(
			new(big.Int).SetUint64(reserveIn),
			new(big.Int).SetUint64(poolInfo.FeeDenominator),
		),
		new(big.Int).Mul(
			new(big.Int).SetUint64(inputAmount),
			new(big.Int).SetUint64(uint64(feeMultiplier)),
		),
	)

	outputAmount := new(big.Int).Div(numerator, denominator).Uint64()

	// Calculate fee
	fee := utils.CalculateSwapFee(inputAmount, poolInfo.FeeNumerator, poolInfo.FeeDenominator)

	// Calculate price impact
	priceImpact := utils.CalculatePriceImpact(inputAmount, outputAmount, reserveIn, reserveOut)

	// Calculate minimum output with slippage
	minOutput := uint64(float64(outputAmount) * (1.0 - slippageTolerance/100.0))

	// Calculate exchange rate
	exchangeRate := float64(outputAmount) / float64(inputAmount)

	quote := &SwapQuote{
		InputAmount:       inputAmount,
		OutputAmount:      outputAmount,
		MinOutput:         minOutput,
		PriceImpact:       priceImpact,
		Fee:               fee,
		ExchangeRate:      exchangeRate,
		SlippageTolerance: slippageTolerance,
	}

	c.logger.WithFields(logrus.Fields{
		"input_amount":  inputAmount,
		"output_amount": outputAmount,
		"price_impact":  fmt.Sprintf("%.4f%%", priceImpact),
		"fee":          fee,
	}).Debug("Calculated swap quote")

	return quote, nil
}

// GetLiquidityQuote calculates a liquidity provision quote
func (c *TokenSwapClient) GetLiquidityQuote(ctx context.Context, poolAddress string, tokenAAmount uint64, tokenBAmount uint64) (*LiquidityQuote, error) {
	poolInfo, err := c.GetPoolInfo(ctx, poolAddress)
	if err != nil {
		return nil, fmt.Errorf("failed to get pool info: %v", err)
	}

	// Calculate optimal amounts based on current pool ratio
	var optimalTokenAAmount, optimalTokenBAmount uint64

	if tokenAAmount > 0 && tokenBAmount > 0 {
		// Both amounts provided - use the limiting one
		ratioA := new(big.Int).Div(
			new(big.Int).Mul(new(big.Int).SetUint64(tokenAAmount), new(big.Int).SetUint64(poolInfo.ReserveB)),
			new(big.Int).SetUint64(poolInfo.ReserveA),
		).Uint64()

		ratioB := new(big.Int).Div(
			new(big.Int).Mul(new(big.Int).SetUint64(tokenBAmount), new(big.Int).SetUint64(poolInfo.ReserveA)),
			new(big.Int).SetUint64(poolInfo.ReserveB),
		).Uint64()

		if ratioA <= tokenBAmount {
			optimalTokenAAmount = tokenAAmount
			optimalTokenBAmount = ratioA
		} else {
			optimalTokenAAmount = ratioB
			optimalTokenBAmount = tokenBAmount
		}
	} else if tokenAAmount > 0 {
		// Only token A amount provided
		optimalTokenAAmount = tokenAAmount
		optimalTokenBAmount = new(big.Int).Div(
			new(big.Int).Mul(new(big.Int).SetUint64(tokenAAmount), new(big.Int).SetUint64(poolInfo.ReserveB)),
			new(big.Int).SetUint64(poolInfo.ReserveA),
		).Uint64()
	} else if tokenBAmount > 0 {
		// Only token B amount provided
		optimalTokenBAmount = tokenBAmount
		optimalTokenAAmount = new(big.Int).Div(
			new(big.Int).Mul(new(big.Int).SetUint64(tokenBAmount), new(big.Int).SetUint64(poolInfo.ReserveA)),
			new(big.Int).SetUint64(poolInfo.ReserveB),
		).Uint64()
	} else {
		return nil, fmt.Errorf("at least one token amount must be provided")
	}

	// Calculate LP token amount using geometric mean
	lpTokenAmount := new(big.Int).Sqrt(
		new(big.Int).Mul(
			new(big.Int).SetUint64(optimalTokenAAmount),
			new(big.Int).SetUint64(optimalTokenBAmount),
		),
	).Uint64()

	// Calculate share of pool
	newTotalSupply := poolInfo.LPTokenSupply + lpTokenAmount
	shareOfPool := float64(lpTokenAmount) / float64(newTotalSupply) * 100.0

	quote := &LiquidityQuote{
		TokenAAmount:  optimalTokenAAmount,
		TokenBAmount:  optimalTokenBAmount,
		LPTokenAmount: lpTokenAmount,
		ShareOfPool:   shareOfPool,
	}

	c.logger.WithFields(logrus.Fields{
		"token_a_amount": optimalTokenAAmount,
		"token_b_amount": optimalTokenBAmount,
		"lp_tokens":      lpTokenAmount,
		"share_of_pool":  fmt.Sprintf("%.4f%%", shareOfPool),
	}).Debug("Calculated liquidity quote")

	return quote, nil
}

// SimulateSwap simulates a token swap without executing it
func (c *TokenSwapClient) SimulateSwap(ctx context.Context, poolAddress string, inputMint string, outputMint string, inputAmount uint64, slippageTolerance float64) (*SwapResult, error) {
	quote, err := c.GetSwapQuote(ctx, poolAddress, inputMint, outputMint, inputAmount, slippageTolerance)
	if err != nil {
		return nil, fmt.Errorf("failed to get swap quote: %v", err)
	}

	result := &SwapResult{
		Signature:    "simulation",
		InputAmount:  quote.InputAmount,
		OutputAmount: quote.OutputAmount,
		Fee:          quote.Fee,
		PriceImpact:  quote.PriceImpact,
		Timestamp:    time.Now(),
		Status:       "simulated",
	}

	c.logger.WithFields(logrus.Fields{
		"input_amount":  result.InputAmount,
		"output_amount": result.OutputAmount,
		"price_impact":  fmt.Sprintf("%.4f%%", result.PriceImpact),
		"fee":          result.Fee,
	}).Info("Swap simulated")

	return result, nil
}

// GetPoolStats returns statistics for a liquidity pool
func (c *TokenSwapClient) GetPoolStats(ctx context.Context, poolAddress string) (map[string]interface{}, error) {
	poolInfo, err := c.GetPoolInfo(ctx, poolAddress)
	if err != nil {
		return nil, fmt.Errorf("failed to get pool info: %v", err)
	}

	// Calculate total value locked (simplified)
	tvl := poolInfo.ReserveA + poolInfo.ReserveB

	// Calculate pool ratio
	ratio := float64(poolInfo.ReserveA) / float64(poolInfo.ReserveB)

	stats := map[string]interface{}{
		"pool_address":     utils.FormatAddress(poolInfo.Address),
		"reserve_a":        poolInfo.ReserveA,
		"reserve_b":        poolInfo.ReserveB,
		"lp_token_supply":  poolInfo.LPTokenSupply,
		"fee_rate":         fmt.Sprintf("%.2f%%", float64(poolInfo.FeeNumerator)/float64(poolInfo.FeeDenominator)*100),
		"trading_enabled":  poolInfo.TradingEnabled,
		"tvl":             tvl,
		"pool_ratio":      fmt.Sprintf("%.6f", ratio),
		"token_a_symbol":  poolInfo.TokenA.Symbol,
		"token_b_symbol":  poolInfo.TokenB.Symbol,
	}

	c.logger.WithFields(logrus.Fields{
		"pool":    utils.FormatAddress(poolInfo.Address),
		"tvl":     tvl,
		"ratio":   fmt.Sprintf("%.6f", ratio),
	}).Debug("Retrieved pool statistics")

	return stats, nil
}