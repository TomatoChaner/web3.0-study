package utils

import (
	"fmt"
	"math"
	"strconv"
	"strings"
	"time"

	"github.com/gagliardetto/solana-go"
)

const (
	// LAMPORTS_PER_SOL represents the number of lamports in one SOL
	LAMPORTS_PER_SOL = 1_000_000_000
)

// FormatSOL converts lamports to SOL with proper formatting
func FormatSOL(lamports uint64) string {
	sol := float64(lamports) / LAMPORTS_PER_SOL
	return fmt.Sprintf("%.9f SOL", sol)
}

// FormatSOLCompact converts lamports to SOL with compact formatting
func FormatSOLCompact(lamports uint64) string {
	sol := float64(lamports) / LAMPORTS_PER_SOL
	if sol >= 1 {
		return fmt.Sprintf("%.4f SOL", sol)
	}
	return fmt.Sprintf("%.9f SOL", sol)
}

// ParseSOL converts SOL string to lamports
func ParseSOL(solStr string) (uint64, error) {
	// Remove "SOL" suffix if present
	solStr = strings.TrimSpace(solStr)
	solStr = strings.TrimSuffix(solStr, "SOL")
	solStr = strings.TrimSpace(solStr)

	sol, err := strconv.ParseFloat(solStr, 64)
	if err != nil {
		return 0, fmt.Errorf("invalid SOL amount: %v", err)
	}

	if sol < 0 {
		return 0, fmt.Errorf("SOL amount cannot be negative")
	}

	lamports := uint64(sol * LAMPORTS_PER_SOL)
	return lamports, nil
}

// FormatLamports formats lamports with thousand separators
func FormatLamports(lamports uint64) string {
	return formatNumber(lamports) + " lamports"
}

// formatNumber adds thousand separators to a number
func formatNumber(n uint64) string {
	str := strconv.FormatUint(n, 10)
	if len(str) <= 3 {
		return str
	}

	var result strings.Builder
	for i, digit := range str {
		if i > 0 && (len(str)-i)%3 == 0 {
			result.WriteString(",")
		}
		result.WriteRune(digit)
	}
	return result.String()
}

// FormatDuration formats a duration in a human-readable way
func FormatDuration(d time.Duration) string {
	if d < time.Second {
		return fmt.Sprintf("%dms", d.Milliseconds())
	}
	if d < time.Minute {
		return fmt.Sprintf("%.1fs", d.Seconds())
	}
	if d < time.Hour {
		return fmt.Sprintf("%.1fm", d.Minutes())
	}
	return fmt.Sprintf("%.1fh", d.Hours())
}

// FormatTimestamp formats a Unix timestamp
func FormatTimestamp(timestamp int64) string {
	if timestamp == 0 {
		return "N/A"
	}
	return time.Unix(timestamp, 0).Format("2006-01-02 15:04:05 UTC")
}

// TruncateString truncates a string to the specified length with ellipsis
func TruncateString(s string, maxLen int) string {
	if len(s) <= maxLen {
		return s
	}
	if maxLen <= 3 {
		return s[:maxLen]
	}
	return s[:maxLen-3] + "..."
}

// FormatAddress formats a Solana address for display
func FormatAddress(address solana.PublicKey) string {
	addr := address.String()
	if len(addr) <= 12 {
		return addr
	}
	return addr[:6] + "..." + addr[len(addr)-6:]
}

// FormatSignature formats a transaction signature for display
func FormatSignature(signature solana.Signature) string {
	sig := signature.String()
	if len(sig) <= 16 {
		return sig
	}
	return sig[:8] + "..." + sig[len(sig)-8:]
}

// CalculatePercentage calculates percentage with proper formatting
func CalculatePercentage(part, total uint64) string {
	if total == 0 {
		return "0.00%"
	}
	percentage := (float64(part) / float64(total)) * 100
	return fmt.Sprintf("%.2f%%", percentage)
}

// FormatBytes formats bytes in human-readable format
func FormatBytes(bytes uint64) string {
	const unit = 1024
	if bytes < unit {
		return fmt.Sprintf("%d B", bytes)
	}
	div, exp := uint64(unit), 0
	for n := bytes / unit; n >= unit; n /= unit {
		div *= unit
		exp++
	}
	return fmt.Sprintf("%.1f %cB", float64(bytes)/float64(div), "KMGTPE"[exp])
}

// ValidatePublicKey validates if a string is a valid Solana public key
func ValidatePublicKey(pubkeyStr string) error {
	_, err := solana.PublicKeyFromBase58(pubkeyStr)
	return err
}

// ValidateSignature validates if a string is a valid Solana signature
func ValidateSignature(sigStr string) error {
	_, err := solana.SignatureFromBase58(sigStr)
	return err
}

// CalculateSwapOutput calculates swap output using constant product formula
// Implements x * y = k algorithm
func CalculateSwapOutput(inputAmount, inputReserve, outputReserve uint64, feeNumerator, feeDenominator uint64) uint64 {
	if inputAmount == 0 || inputReserve == 0 || outputReserve == 0 {
		return 0
	}

	// Calculate input amount after fee
	feeAmount := (inputAmount * feeNumerator) / feeDenominator
	inputAmountAfterFee := inputAmount - feeAmount

	// Apply constant product formula: (x + dx) * (y - dy) = x * y
	// Solving for dy: dy = (y * dx) / (x + dx)
	numerator := inputAmountAfterFee * outputReserve
	denominator := inputReserve + inputAmountAfterFee

	if denominator == 0 {
		return 0
	}

	return numerator / denominator
}

// CalculateSwapInput calculates required input for desired output
func CalculateSwapInput(outputAmount, inputReserve, outputReserve uint64, feeNumerator, feeDenominator uint64) uint64 {
	if outputAmount == 0 || inputReserve == 0 || outputReserve == 0 || outputAmount >= outputReserve {
		return 0
	}

	// Calculate required input before fee using constant product formula
	// (x + dx) * (y - dy) = x * y
	// Solving for dx: dx = (x * dy) / (y - dy)
	numerator := inputReserve * outputAmount
	denominator := outputReserve - outputAmount

	if denominator == 0 {
		return 0
	}

	inputAmountBeforeFee := numerator / denominator

	// Add fee to get total input amount
	// inputAmountAfterFee = inputAmount - fee
	// inputAmount = inputAmountAfterFee * feeDenominator / (feeDenominator - feeNumerator)
	totalInputAmount := (inputAmountBeforeFee * feeDenominator) / (feeDenominator - feeNumerator)

	return totalInputAmount
}

// CalculatePriceImpact calculates price impact percentage
func CalculatePriceImpact(inputAmount, outputAmount, inputReserve, outputReserve uint64) float64 {
	if inputReserve == 0 || outputReserve == 0 || inputAmount == 0 || outputAmount == 0 {
		return 0
	}

	// Current price: outputReserve / inputReserve
	currentPrice := float64(outputReserve) / float64(inputReserve)

	// Execution price: outputAmount / inputAmount
	executionPrice := float64(outputAmount) / float64(inputAmount)

	// Price impact = (currentPrice - executionPrice) / currentPrice * 100
	priceImpact := (currentPrice - executionPrice) / currentPrice * 100

	return math.Abs(priceImpact)
}

// CalculateSlippage calculates slippage tolerance
func CalculateSlippage(expectedAmount, actualAmount uint64) float64 {
	if expectedAmount == 0 {
		return 0
	}

	slippage := float64(expectedAmount-actualAmount) / float64(expectedAmount) * 100
	return math.Abs(slippage)
}

// CalculateSwapFee calculates the swap fee based on input amount and fee parameters
func CalculateSwapFee(inputAmount uint64, feeNumerator uint64, feeDenominator uint64) uint64 {
	return (inputAmount * feeNumerator) / feeDenominator
}

// ApplySlippageTolerance applies slippage tolerance to an amount
func ApplySlippageTolerance(amount uint64, slippagePercent float64, isMinimum bool) uint64 {
	slippageMultiplier := slippagePercent / 100.0

	if isMinimum {
		// For minimum amounts (selling), reduce by slippage
		return uint64(float64(amount) * (1.0 - slippageMultiplier))
	} else {
		// For maximum amounts (buying), increase by slippage
		return uint64(float64(amount) * (1.0 + slippageMultiplier))
	}
}

// FormatSlippage formats slippage percentage
func FormatSlippage(slippage float64) string {
	return fmt.Sprintf("%.2f%%", slippage)
}

// FormatPriceImpact formats price impact with color coding
func FormatPriceImpact(impact float64) string {
	return fmt.Sprintf("%.2f%%", impact)
}

// IsHighPriceImpact checks if price impact is considered high
func IsHighPriceImpact(impact float64) bool {
	return impact > 5.0 // 5% threshold
}

// IsExcessiveSlippage checks if slippage is excessive
func IsExcessiveSlippage(slippage float64) bool {
	return slippage > 10.0 // 10% threshold
}

// SafeAdd performs safe addition to prevent overflow
func SafeAdd(a, b uint64) (uint64, error) {
	if a > math.MaxUint64-b {
		return 0, fmt.Errorf("addition overflow")
	}
	return a + b, nil
}

// SafeSubtract performs safe subtraction to prevent underflow
func SafeSubtract(a, b uint64) (uint64, error) {
	if a < b {
		return 0, fmt.Errorf("subtraction underflow")
	}
	return a - b, nil
}

// SafeMultiply performs safe multiplication to prevent overflow
func SafeMultiply(a, b uint64) (uint64, error) {
	if a == 0 || b == 0 {
		return 0, nil
	}
	if a > math.MaxUint64/b {
		return 0, fmt.Errorf("multiplication overflow")
	}
	return a * b, nil
}

// SafeDivide performs safe division to prevent division by zero
func SafeDivide(a, b uint64) (uint64, error) {
	if b == 0 {
		return 0, fmt.Errorf("division by zero")
	}
	return a / b, nil
}