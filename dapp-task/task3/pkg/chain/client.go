package chain

import (
	"context"
	"fmt"
	"time"

	"github.com/gagliardetto/solana-go"
	"github.com/gagliardetto/solana-go/programs/system"
	"github.com/gagliardetto/solana-go/rpc"
	"github.com/sirupsen/logrus"

	"solana-go-assignment/internal/config"
	"solana-go-assignment/internal/utils"
)

// Client represents a Solana blockchain client
type Client struct {
	rpcClient *rpc.Client
	wsURL     string
	network   config.NetworkType
	logger    *logrus.Logger
}

// BlockInfo represents block information
type BlockInfo struct {
	Blockhash     string
	Slot          uint64
	BlockHeight   *uint64
	BlockTime     *int64
	ParentSlot    uint64
	Transactions  int
}

// AccountInfo represents account information
type AccountInfo struct {
	Address    string
	Balance    uint64
	Owner      string
	Executable bool
	RentEpoch  uint64
	DataSize   int
}

// TransactionResult represents transaction result
type TransactionResult struct {
	Signature     string
	Slot          uint64
	BlockTime     *int64
	Confirmations *uint64
	Status        string
	Fee           uint64
	Error         string
}

// NewClient creates a new Solana client
func NewClient(rpcEndpoint, wsEndpoint string, network config.NetworkType) (*Client, error) {
	rpcClient := rpc.New(rpcEndpoint)
	
	logger := logrus.New()
	logger.SetLevel(logrus.InfoLevel)

	client := &Client{
		rpcClient: rpcClient,
		wsURL:     wsEndpoint,
		network:   network,
		logger:    logger,
	}

	// Test connection
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	_, err := rpcClient.GetHealth(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to Solana RPC: %v", err)
	}

	client.logger.WithFields(logrus.Fields{
		"network":  network,
		"endpoint": rpcEndpoint,
	}).Info("Solana client initialized successfully")

	return client, nil
}

// Close closes the client connections
func (c *Client) Close() {
	c.logger.Info("Closing Solana client")
}

// GetNetwork returns the current network
func (c *Client) GetNetwork() config.NetworkType {
	return c.network
}

// GetHealth checks the health of the RPC node
func (c *Client) GetHealth(ctx context.Context) error {
	_, err := c.rpcClient.GetHealth(ctx)
	return err
}

// GetLatestBlockhash gets the latest blockhash
func (c *Client) GetLatestBlockhash(ctx context.Context) (*BlockInfo, error) {
	result, err := c.rpcClient.GetLatestBlockhash(ctx, rpc.CommitmentFinalized)
	if err != nil {
		return nil, fmt.Errorf("failed to get latest blockhash: %v", err)
	}

	blockInfo := &BlockInfo{
		Blockhash: result.Value.Blockhash.String(),
		Slot:      result.Context.Slot,
	}

	c.logger.WithFields(logrus.Fields{
		"blockhash": blockInfo.Blockhash,
		"slot":      blockInfo.Slot,
	}).Debug("Retrieved latest blockhash")

	return blockInfo, nil
}

// GetSlot gets the current slot
func (c *Client) GetSlot(ctx context.Context) (uint64, error) {
	slot, err := c.rpcClient.GetSlot(ctx, rpc.CommitmentFinalized)
	if err != nil {
		return 0, fmt.Errorf("failed to get slot: %v", err)
	}

	c.logger.WithField("slot", slot).Debug("Retrieved current slot")
	return slot, nil
}

// GetBlockHeight gets the current block height
func (c *Client) GetBlockHeight(ctx context.Context) (uint64, error) {
	height, err := c.rpcClient.GetBlockHeight(ctx, rpc.CommitmentFinalized)
	if err != nil {
		return 0, fmt.Errorf("failed to get block height: %v", err)
	}

	c.logger.WithField("height", height).Debug("Retrieved block height")
	return height, nil
}

// GetBlock gets block information by slot
func (c *Client) GetBlock(ctx context.Context, slot uint64) (*BlockInfo, error) {
	block, err := c.rpcClient.GetBlock(ctx, slot)
	if err != nil {
		return nil, fmt.Errorf("failed to get block %d: %v", slot, err)
	}

	var blockTime *int64
	if block.BlockTime != nil {
		t := int64(*block.BlockTime)
		blockTime = &t
	}

	blockInfo := &BlockInfo{
		Blockhash:    block.Blockhash.String(),
		Slot:         slot,
		BlockHeight:  block.BlockHeight,
		BlockTime:    blockTime,
		ParentSlot:   block.ParentSlot,
		Transactions: len(block.Transactions),
	}

	c.logger.WithFields(logrus.Fields{
		"slot":         slot,
		"blockhash":    blockInfo.Blockhash,
		"transactions": blockInfo.Transactions,
	}).Debug("Retrieved block information")

	return blockInfo, nil
}

// GetAccountBalance gets the balance of an account
func (c *Client) GetAccountBalance(ctx context.Context, address string) (*AccountInfo, error) {
	pubkey, err := solana.PublicKeyFromBase58(address)
	if err != nil {
		return nil, fmt.Errorf("invalid public key: %v", err)
	}

	balance, err := c.rpcClient.GetBalance(ctx, pubkey, rpc.CommitmentFinalized)
	if err != nil {
		return nil, fmt.Errorf("failed to get balance: %v", err)
	}

	accountInfo := &AccountInfo{
		Address: address,
		Balance: balance.Value,
	}

	c.logger.WithFields(logrus.Fields{
		"address": utils.FormatAddress(pubkey),
		"balance": utils.FormatSOL(balance.Value),
	}).Debug("Retrieved account balance")

	return accountInfo, nil
}

// GetAccountInfo gets detailed account information
func (c *Client) GetAccountInfo(ctx context.Context, address string) (*AccountInfo, error) {
	pubkey, err := solana.PublicKeyFromBase58(address)
	if err != nil {
		return nil, fmt.Errorf("invalid public key: %v", err)
	}

	accountInfo, err := c.rpcClient.GetAccountInfo(ctx, pubkey)
	if err != nil {
		return nil, fmt.Errorf("failed to get account info: %v", err)
	}

	if accountInfo.Value == nil {
		return &AccountInfo{
			Address: address,
			Balance: 0,
		}, nil
	}

	info := &AccountInfo{
		Address:    address,
		Balance:    accountInfo.Value.Lamports,
		Owner:      accountInfo.Value.Owner.String(),
		Executable: accountInfo.Value.Executable,
		RentEpoch:  accountInfo.Value.RentEpoch,
		DataSize:   len(accountInfo.Value.Data.GetBinary()),
	}

	c.logger.WithFields(logrus.Fields{
		"address":    utils.FormatAddress(pubkey),
		"balance":    utils.FormatSOL(info.Balance),
		"owner":      utils.FormatAddress(accountInfo.Value.Owner),
		"executable": info.Executable,
		"data_size":  info.DataSize,
	}).Debug("Retrieved account information")

	return info, nil
}

// CreateTransferTransaction creates a transfer transaction
func (c *Client) CreateTransferTransaction(ctx context.Context, from, to solana.PrivateKey, lamports uint64) (*solana.Transaction, error) {
	// Get recent blockhash
	recent, err := c.rpcClient.GetLatestBlockhash(ctx, rpc.CommitmentFinalized)
	if err != nil {
		return nil, fmt.Errorf("failed to get recent blockhash: %v", err)
	}

	// Create transfer instruction
	instruction := system.NewTransferInstruction(
		lamports,
		from.PublicKey(),
		to.PublicKey(),
	).Build()

	// Create transaction
	tx, err := solana.NewTransaction(
		[]solana.Instruction{instruction},
		recent.Value.Blockhash,
		solana.TransactionPayer(from.PublicKey()),
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create transaction: %v", err)
	}

	// Sign transaction
	_, err = tx.Sign(func(key solana.PublicKey) *solana.PrivateKey {
		if key.Equals(from.PublicKey()) {
			return &from
		}
		return nil
	})
	if err != nil {
		return nil, fmt.Errorf("failed to sign transaction: %v", err)
	}

	c.logger.WithFields(logrus.Fields{
		"from":     utils.FormatAddress(from.PublicKey()),
		"to":       utils.FormatAddress(to.PublicKey()),
		"amount":   utils.FormatSOL(lamports),
	}).Info("Created transfer transaction")

	return tx, nil
}

// SendTransaction sends a transaction to the network
func (c *Client) SendTransaction(ctx context.Context, tx *solana.Transaction) (solana.Signature, error) {
	signature, err := c.rpcClient.SendTransaction(ctx, tx)
	if err != nil {
		return solana.Signature{}, fmt.Errorf("failed to send transaction: %v", err)
	}

	c.logger.WithField("signature", utils.FormatSignature(signature)).Info("Transaction sent")
	return signature, nil
}

// ConfirmTransaction waits for transaction confirmation
func (c *Client) ConfirmTransaction(ctx context.Context, signature solana.Signature) (*TransactionResult, error) {
	// Wait for confirmation with timeout
	confirmCtx, cancel := context.WithTimeout(ctx, 60*time.Second)
	defer cancel()

	// Poll for confirmation
	ticker := time.NewTicker(2 * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-confirmCtx.Done():
			return nil, fmt.Errorf("transaction confirmation timeout")
		case <-ticker.C:
			status, err := c.rpcClient.GetSignatureStatuses(ctx, true, signature)
			if err != nil {
				c.logger.WithError(err).Warn("Failed to get signature status")
				continue
			}

			if len(status.Value) > 0 && status.Value[0] != nil {
				result := &TransactionResult{
					Signature:     signature.String(),
					Slot:          status.Value[0].Slot,
					Confirmations: status.Value[0].Confirmations,
					Status:        "confirmed",
				}

				if status.Value[0].Err != nil {
					result.Status = "failed"
					result.Error = fmt.Sprintf("%v", status.Value[0].Err)
				}

				c.logger.WithFields(logrus.Fields{
					"signature":     utils.FormatSignature(signature),
					"slot":          result.Slot,
					"confirmations": result.Confirmations,
					"status":        result.Status,
				}).Info("Transaction confirmed")

				return result, nil
			}
		}
	}
}

// SendAndConfirmTransaction sends a transaction and waits for confirmation
func (c *Client) SendAndConfirmTransaction(ctx context.Context, tx *solana.Transaction) (*TransactionResult, error) {
	signature, err := c.SendTransaction(ctx, tx)
	if err != nil {
		return nil, err
	}

	return c.ConfirmTransaction(ctx, signature)
}

// GetTransactionHistory gets transaction history for an account
func (c *Client) GetTransactionHistory(ctx context.Context, address string, limit int) ([]*TransactionResult, error) {
	pubkey, err := solana.PublicKeyFromBase58(address)
	if err != nil {
		return nil, fmt.Errorf("invalid public key: %v", err)
	}

	signatures, err := c.rpcClient.GetSignaturesForAddress(ctx, pubkey)
	if err != nil {
		return nil, fmt.Errorf("failed to get signatures: %v", err)
	}

	var results []*TransactionResult
	for _, sig := range signatures {
		var blockTime *int64
		if sig.BlockTime != nil {
			t := int64(*sig.BlockTime)
			blockTime = &t
		}

		result := &TransactionResult{
			Signature: sig.Signature.String(),
			Slot:      sig.Slot,
			BlockTime: blockTime,
			Status:    "confirmed",
		}

		if sig.Err != nil {
			result.Status = "failed"
			result.Error = fmt.Sprintf("%v", sig.Err)
		}

		results = append(results, result)
	}

	c.logger.WithFields(logrus.Fields{
		"address":      utils.FormatAddress(pubkey),
		"transactions": len(results),
	}).Debug("Retrieved transaction history")

	return results, nil
}

// GetTokenAccounts gets token accounts for an address
func (c *Client) GetTokenAccounts(ctx context.Context, address string) ([]AccountInfo, error) {
	pubkey, err := solana.PublicKeyFromBase58(address)
	if err != nil {
		return nil, fmt.Errorf("invalid public key: %v", err)
	}

	accounts, err := c.rpcClient.GetTokenAccountsByOwner(ctx, pubkey, &rpc.GetTokenAccountsConfig{
		ProgramId: &solana.TokenProgramID,
	}, &rpc.GetTokenAccountsOpts{
		Encoding: solana.EncodingBase64,
	})
	if err != nil {
		return nil, fmt.Errorf("failed to get token accounts: %v", err)
	}

	var results []AccountInfo
	for _, account := range accounts.Value {
		info := AccountInfo{
			Address:    account.Pubkey.String(),
			Balance:    account.Account.Lamports,
			Owner:      account.Account.Owner.String(),
			Executable: account.Account.Executable,
			RentEpoch:  account.Account.RentEpoch,
			DataSize:   len(account.Account.Data.GetBinary()),
		}
		results = append(results, info)
	}

	c.logger.WithFields(logrus.Fields{
		"address":       utils.FormatAddress(pubkey),
		"token_accounts": len(results),
	}).Debug("Retrieved token accounts")

	return results, nil
}

// EstimateTransactionFee estimates the fee for a transaction
func (c *Client) EstimateTransactionFee(ctx context.Context, tx *solana.Transaction) (uint64, error) {
	// For now, return a default fee estimate
	// The actual implementation would depend on the specific RPC method available
	defaultFee := uint64(5000) // 5000 lamports as default fee
	
	c.logger.WithField("fee", utils.FormatLamports(defaultFee)).Debug("Estimated transaction fee")
	return defaultFee, nil
}

// GetMinimumBalanceForRentExemption gets minimum balance for rent exemption
func (c *Client) GetMinimumBalanceForRentExemption(ctx context.Context, dataSize uint64) (uint64, error) {
	balance, err := c.rpcClient.GetMinimumBalanceForRentExemption(ctx, dataSize, rpc.CommitmentFinalized)
	if err != nil {
		return 0, fmt.Errorf("failed to get minimum balance: %v", err)
	}

	c.logger.WithFields(logrus.Fields{
		"data_size": dataSize,
		"balance":   utils.FormatSOL(balance),
	}).Debug("Retrieved minimum balance for rent exemption")

	return balance, nil
}