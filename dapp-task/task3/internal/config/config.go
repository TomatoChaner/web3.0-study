package config

import (
	"fmt"
	"os"
	"strings"
)

// NetworkType represents different Solana networks
type NetworkType string

const (
	MainNet NetworkType = "mainnet"
	TestNet NetworkType = "testnet"
	DevNet  NetworkType = "devnet"
)

// NetworkConfig holds configuration for a specific network
type NetworkConfig struct {
	Name     NetworkType
	RPC      string
	WS       string
	Explorer string
}

// Config holds the application configuration
type Config struct {
	RPCEndpoint string
	WSEndpoint  string
	Network     NetworkType
	LogLevel    string
}

// Predefined network configurations
var (
	MainNetConfig = NetworkConfig{
		Name:     MainNet,
		RPC:      "https://api.mainnet-beta.solana.com",
		WS:       "wss://api.mainnet-beta.solana.com",
		Explorer: "https://explorer.solana.com",
	}

	TestNetConfig = NetworkConfig{
		Name:     TestNet,
		RPC:      "https://api.testnet.solana.com",
		WS:       "wss://api.testnet.solana.com",
		Explorer: "https://explorer.solana.com",
	}

	DevNetConfig = NetworkConfig{
		Name:     DevNet,
		RPC:      "https://api.devnet.solana.com",
		WS:       "wss://api.devnet.solana.com",
		Explorer: "https://explorer.solana.com",
	}
)

// GetNetworkConfig returns the configuration for the specified network
func GetNetworkConfig(network NetworkType) (NetworkConfig, error) {
	switch network {
	case MainNet:
		return MainNetConfig, nil
	case TestNet:
		return TestNetConfig, nil
	case DevNet:
		return DevNetConfig, nil
	default:
		return NetworkConfig{}, fmt.Errorf("unsupported network: %s", network)
	}
}

// GetDefaultConfig returns the default configuration (DevNet)
func GetDefaultConfig() *Config {
	return &Config{
		RPCEndpoint: DevNetConfig.RPC,
		WSEndpoint:  DevNetConfig.WS,
		Network:     DevNet,
		LogLevel:    "info",
	}
}

// NewConfig creates a new configuration with the specified network
func NewConfig(network NetworkType) (*Config, error) {
	netConfig, err := GetNetworkConfig(network)
	if err != nil {
		return nil, err
	}

	return &Config{
		RPCEndpoint: netConfig.RPC,
		WSEndpoint:  netConfig.WS,
		Network:     network,
		LogLevel:    "info",
	}, nil
}

// NewConfigFromEnv creates configuration from environment variables
func NewConfigFromEnv() *Config {
	config := GetDefaultConfig()

	// Override with environment variables if present
	if rpc := os.Getenv("SOLANA_RPC_ENDPOINT"); rpc != "" {
		config.RPCEndpoint = rpc
	}

	if ws := os.Getenv("SOLANA_WS_ENDPOINT"); ws != "" {
		config.WSEndpoint = ws
	}

	if network := os.Getenv("SOLANA_NETWORK"); network != "" {
		config.Network = NetworkType(strings.ToLower(network))
	}

	if logLevel := os.Getenv("LOG_LEVEL"); logLevel != "" {
		config.LogLevel = strings.ToLower(logLevel)
	}

	return config
}

// Validate checks if the configuration is valid
func (c *Config) Validate() error {
	if c.RPCEndpoint == "" {
		return fmt.Errorf("RPC endpoint cannot be empty")
	}

	if c.WSEndpoint == "" {
		return fmt.Errorf("WebSocket endpoint cannot be empty")
	}

	if c.Network == "" {
		return fmt.Errorf("network cannot be empty")
	}

	// Validate network type
	switch c.Network {
	case MainNet, TestNet, DevNet:
		// Valid network
	default:
		return fmt.Errorf("invalid network: %s", c.Network)
	}

	return nil
}

// String returns a string representation of the configuration
func (c *Config) String() string {
	return fmt.Sprintf("Config{Network: %s, RPC: %s, WS: %s, LogLevel: %s}",
		c.Network, c.RPCEndpoint, c.WSEndpoint, c.LogLevel)
}

// IsMainNet returns true if the configuration is for MainNet
func (c *Config) IsMainNet() bool {
	return c.Network == MainNet
}

// IsTestNet returns true if the configuration is for TestNet
func (c *Config) IsTestNet() bool {
	return c.Network == TestNet
}

// IsDevNet returns true if the configuration is for DevNet
func (c *Config) IsDevNet() bool {
	return c.Network == DevNet
}

// GetExplorerURL returns the explorer URL for the configured network
func (c *Config) GetExplorerURL() string {
	netConfig, err := GetNetworkConfig(c.Network)
	if err != nil {
		return "https://explorer.solana.com"
	}
	return netConfig.Explorer
}

// GetExplorerTxURL returns the explorer URL for a specific transaction
func (c *Config) GetExplorerTxURL(signature string) string {
	baseURL := c.GetExplorerURL()
	cluster := ""
	
	if c.Network != MainNet {
		cluster = fmt.Sprintf("?cluster=%s", c.Network)
	}
	
	return fmt.Sprintf("%s/tx/%s%s", baseURL, signature, cluster)
}

// GetExplorerAccountURL returns the explorer URL for a specific account
func (c *Config) GetExplorerAccountURL(address string) string {
	baseURL := c.GetExplorerURL()
	cluster := ""
	
	if c.Network != MainNet {
		cluster = fmt.Sprintf("?cluster=%s", c.Network)
	}
	
	return fmt.Sprintf("%s/account/%s%s", baseURL, address, cluster)
}