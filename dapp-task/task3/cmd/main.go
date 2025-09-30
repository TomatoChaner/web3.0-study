package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"strconv"
	"time"

	"github.com/spf13/cobra"

	"solana-go-assignment/internal/config"
	"solana-go-assignment/pkg/chain"
	"solana-go-assignment/pkg/contract"
)

var (
	network     string
	rpcURL      string
	wsURL       string
	verbose     bool
	configFile  string
)

// rootCmd represents the base command when called without any subcommands
var rootCmd = &cobra.Command{
	Use:   "solana-go-assignment",
	Short: "Solana blockchain interaction tool",
	Long: `A comprehensive Solana blockchain interaction tool that provides:
- Blockchain data querying
- Token swap operations
- Event listening and monitoring
- Smart contract interactions`,
}

// chainCmd represents the chain command
var chainCmd = &cobra.Command{
	Use:   "chain",
	Short: "Blockchain interaction commands",
	Long:  "Commands for interacting with the Solana blockchain",
}

// balanceCmd gets account balance
var balanceCmd = &cobra.Command{
	Use:   "balance [address]",
	Short: "Get account balance",
	Args:  cobra.ExactArgs(1),
	Run: func(cmd *cobra.Command, args []string) {
		cfg := getConfig()
		client, err := chain.NewClient(cfg.RPCEndpoint, cfg.WSEndpoint, cfg.Network)
		if err != nil {
			log.Fatalf("Failed to create client: %v", err)
		}
		defer client.Close()
		
		ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cancel()

		accountInfo, err := client.GetAccountBalance(ctx, args[0])
		if err != nil {
			log.Fatalf("Failed to get balance: %v", err)
		}

		fmt.Printf("Account: %s\n", args[0])
		fmt.Printf("Balance: %.9f SOL\n", float64(accountInfo.Balance)/1e9)
	},
}

// blockCmd gets block information
var blockCmd = &cobra.Command{
	Use:   "block [slot]",
	Short: "Get block information",
	Args:  cobra.ExactArgs(1),
	Run: func(cmd *cobra.Command, args []string) {
		cfg := getConfig()
		client, err := chain.NewClient(cfg.RPCEndpoint, cfg.WSEndpoint, cfg.Network)
		if err != nil {
			log.Fatalf("Failed to create client: %v", err)
		}
		defer client.Close()
		
		ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cancel()

		slot, err := strconv.ParseUint(args[0], 10, 64)
		if err != nil {
			log.Fatalf("Invalid slot number: %v", err)
		}

		blockInfo, err := client.GetBlock(ctx, slot)
		if err != nil {
			log.Fatalf("Failed to get block info: %v", err)
		}

		fmt.Printf("Slot: %d\n", blockInfo.Slot)
		fmt.Printf("Block Hash: %s\n", blockInfo.Blockhash)
		fmt.Printf("Parent Slot: %d\n", blockInfo.ParentSlot)
		fmt.Printf("Transaction Count: %d\n", blockInfo.Transactions)
		if blockInfo.BlockTime != nil {
			fmt.Printf("Block Time: %s\n", time.Unix(*blockInfo.BlockTime, 0).Format(time.RFC3339))
		}
	},
}

// swapCmd represents the swap command
var swapCmd = &cobra.Command{
	Use:   "swap",
	Short: "Token swap operations",
	Long:  "Commands for token swap operations",
}

// quoteCmd gets swap quote
var quoteCmd = &cobra.Command{
	Use:   "quote [pool] [input-mint] [output-mint] [amount]",
	Short: "Get swap quote",
	Args:  cobra.ExactArgs(4),
	Run: func(cmd *cobra.Command, args []string) {
		cfg := getConfig()
		chainClient, err := chain.NewClient(cfg.RPCEndpoint, cfg.WSEndpoint, cfg.Network)
		if err != nil {
			log.Fatalf("Failed to create client: %v", err)
		}
		defer chainClient.Close()
		
		swapClient := contract.NewTokenSwapClient(chainClient, cfg.Network)
		
		ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cancel()

		amount, err := strconv.ParseUint(args[3], 10, 64)
		if err != nil {
			log.Fatalf("Invalid amount: %v", err)
		}

		quote, err := swapClient.GetSwapQuote(ctx, args[0], args[1], args[2], amount, 1.0)
		if err != nil {
			log.Fatalf("Failed to get swap quote: %v", err)
		}

		fmt.Printf("Swap Quote:\n")
		fmt.Printf("  Input Amount: %d\n", quote.InputAmount)
		fmt.Printf("  Output Amount: %d\n", quote.OutputAmount)
		fmt.Printf("  Min Output: %d\n", quote.MinOutput)
		fmt.Printf("  Price Impact: %.4f%%\n", quote.PriceImpact)
		fmt.Printf("  Fee: %d\n", quote.Fee)
		fmt.Printf("  Exchange Rate: %.6f\n", quote.ExchangeRate)
	},
}

// simulateCmd simulates a swap
var simulateCmd = &cobra.Command{
	Use:   "simulate [pool] [input-mint] [output-mint] [amount]",
	Short: "Simulate token swap",
	Args:  cobra.ExactArgs(4),
	Run: func(cmd *cobra.Command, args []string) {
		cfg := getConfig()
		chainClient, err := chain.NewClient(cfg.RPCEndpoint, cfg.WSEndpoint, cfg.Network)
		if err != nil {
			log.Fatalf("Failed to create client: %v", err)
		}
		defer chainClient.Close()
		
		swapClient := contract.NewTokenSwapClient(chainClient, cfg.Network)
		
		ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cancel()

		amount, err := strconv.ParseUint(args[3], 10, 64)
		if err != nil {
			log.Fatalf("Invalid amount: %v", err)
		}

		result, err := swapClient.SimulateSwap(ctx, args[0], args[1], args[2], amount, 1.0)
		if err != nil {
			log.Fatalf("Failed to simulate swap: %v", err)
		}

		fmt.Printf("Swap Simulation:\n")
		fmt.Printf("  Status: %s\n", result.Status)
		fmt.Printf("  Input Amount: %d\n", result.InputAmount)
		fmt.Printf("  Output Amount: %d\n", result.OutputAmount)
		fmt.Printf("  Price Impact: %.4f%%\n", result.PriceImpact)
		fmt.Printf("  Fee: %d\n", result.Fee)
		fmt.Printf("  Timestamp: %s\n", result.Timestamp.Format(time.RFC3339))
	},
}

// poolCmd gets pool information
var poolCmd = &cobra.Command{
	Use:   "pool [address]",
	Short: "Get pool information",
	Args:  cobra.ExactArgs(1),
	Run: func(cmd *cobra.Command, args []string) {
		cfg := getConfig()
		chainClient, err := chain.NewClient(cfg.RPCEndpoint, cfg.WSEndpoint, cfg.Network)
		if err != nil {
			log.Fatalf("Failed to create client: %v", err)
		}
		defer chainClient.Close()
		
		swapClient := contract.NewTokenSwapClient(chainClient, cfg.Network)
		
		ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cancel()

		poolInfo, err := swapClient.GetPoolInfo(ctx, args[0])
		if err != nil {
			log.Fatalf("Failed to get pool info: %v", err)
		}

		fmt.Printf("Pool Information:\n")
		fmt.Printf("  Address: %s\n", poolInfo.Address.String())
		fmt.Printf("  Token A Reserve: %d\n", poolInfo.ReserveA)
		fmt.Printf("  Token B Reserve: %d\n", poolInfo.ReserveB)
		fmt.Printf("  LP Token Supply: %d\n", poolInfo.LPTokenSupply)
		fmt.Printf("  Fee Rate: %.2f%%\n", float64(poolInfo.FeeNumerator)/float64(poolInfo.FeeDenominator)*100)
		fmt.Printf("  Trading Enabled: %t\n", poolInfo.TradingEnabled)
	},
}

// statsCmd gets pool statistics
var statsCmd = &cobra.Command{
	Use:   "stats [pool]",
	Short: "Get pool statistics",
	Args:  cobra.ExactArgs(1),
	Run: func(cmd *cobra.Command, args []string) {
		cfg := getConfig()
		chainClient, err := chain.NewClient(cfg.RPCEndpoint, cfg.WSEndpoint, cfg.Network)
		if err != nil {
			log.Fatalf("Failed to create client: %v", err)
		}
		defer chainClient.Close()
		
		swapClient := contract.NewTokenSwapClient(chainClient, cfg.Network)
		
		ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cancel()

		stats, err := swapClient.GetPoolStats(ctx, args[0])
		if err != nil {
			log.Fatalf("Failed to get pool stats: %v", err)
		}

		fmt.Printf("Pool Statistics:\n")
		for key, value := range stats {
			fmt.Printf("  %s: %v\n", key, value)
		}
	},
}

// versionCmd shows version information
var versionCmd = &cobra.Command{
	Use:   "version",
	Short: "Show version information",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("Solana Go Assignment v1.0.0")
		fmt.Println("A comprehensive Solana blockchain interaction tool")
	},
}

func init() {
	// Global flags
	rootCmd.PersistentFlags().StringVar(&network, "network", "devnet", "Solana network (mainnet, testnet, devnet)")
	rootCmd.PersistentFlags().StringVar(&rpcURL, "rpc-url", "", "Custom RPC URL")
	rootCmd.PersistentFlags().StringVar(&wsURL, "ws-url", "", "Custom WebSocket URL")
	rootCmd.PersistentFlags().BoolVar(&verbose, "verbose", false, "Enable verbose logging")
	rootCmd.PersistentFlags().StringVar(&configFile, "config", "", "Config file path")

	// Add subcommands
	rootCmd.AddCommand(chainCmd)
	rootCmd.AddCommand(swapCmd)
	rootCmd.AddCommand(versionCmd)

	// Chain subcommands
	chainCmd.AddCommand(balanceCmd)
	chainCmd.AddCommand(blockCmd)

	// Swap subcommands
	swapCmd.AddCommand(quoteCmd)
	swapCmd.AddCommand(simulateCmd)
	swapCmd.AddCommand(poolCmd)
	swapCmd.AddCommand(statsCmd)
}

func getConfig() *config.Config {
	var networkType config.NetworkType
	switch network {
	case "mainnet":
		networkType = config.MainNet
	case "testnet":
		networkType = config.TestNet
	case "devnet":
		networkType = config.DevNet
	default:
		log.Fatalf("Invalid network: %s", network)
	}

	cfg, err := config.NewConfig(networkType)
	if err != nil {
		log.Fatalf("Failed to create config: %v", err)
	}

	// Override with custom URLs if provided
	if rpcURL != "" {
		cfg.RPCEndpoint = rpcURL
	}
	if wsURL != "" {
		cfg.WSEndpoint = wsURL
	}

	return cfg
}

func main() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
}