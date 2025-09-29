/*
*
发送交易函数  以main.go调用该函数为基础
准备一个 Sepolia 测试网络的以太坊账户，并获取其私钥。
编写 Go 代码，使用 ethclient 连接到 Sepolia 测试网络。
构造一笔简单的以太币转账交易，指定发送方、接收方和转账金额。
对交易进行签名，并将签名后的交易发送到网络。
输出交易的哈希值。
*/
package functions

import (
	"context"
	"crypto/ecdsa"
	"fmt"
	"log"
	"math/big"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
)

// 发送交易
func TransferAccount(client *ethclient.Client, privateKey *ecdsa.PrivateKey, to common.Address, amount *big.Int) {
	// 获取发送方地址
	publicKey := privateKey.Public()
	publicKeyECDSA, ok := publicKey.(*ecdsa.PublicKey)
	if !ok {
		log.Fatal("无法转换公钥")
	}
	fromAddress := crypto.PubkeyToAddress(*publicKeyECDSA)

	// 使用 PendingNonceAt 获取 nonce
	nonce, err := client.PendingNonceAt(context.Background(), fromAddress)
	if err != nil {
		log.Fatalf("获取 nonce 失败: %v", err)
	}
	fmt.Printf("当前 nonce: %d\n", nonce)

	// 获取建议的 Gas 价格
	gasPrice, err := client.SuggestGasPrice(context.Background())
	if err != nil {
		log.Fatalf("获取 Gas 价格失败: %v", err)
	}
	fmt.Printf("建议 Gas 价格: %s Gwei\n", weiToGwei(gasPrice))

	// 构造交易
	gasLimit := uint64(21000) // 标准转账的 Gas 限制
	tx := types.NewTransaction(nonce, to, amount, gasLimit, gasPrice, nil)

	// 获取链ID (Sepolia 测试网络)
	chainID := big.NewInt(11155111)

	// 签名交易
	signedTx, err := types.SignTx(tx, types.NewEIP155Signer(chainID), privateKey)
	if err != nil {
		log.Fatalf("签名交易失败: %v", err)
	}

	// 发送交易
	err = client.SendTransaction(context.Background(), signedTx)
	if err != nil {
		log.Fatalf("发送交易失败: %v", err)
	}

	fmt.Printf("交易已发送!\n")
	fmt.Printf("交易哈希: %s\n", signedTx.Hash().Hex())
	fmt.Printf("发送方: %s\n", fromAddress.Hex())
	fmt.Printf("接收方: %s\n", to.Hex())
	fmt.Printf("金额: %s ETH\n", weiToEther(amount))
}
