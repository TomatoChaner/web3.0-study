package main

import (
	"fmt"
	"log"
	"math/big"
	functions "task1/functions"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
)

func main() {
	fmt.Println("程序开始运行...")
	fmt.Println("正在连接以太坊节点...")
	client, err := ethclient.Dial("https://sepolia.infura.io/v3/63c698e1cd9d498e87d3f906dc607204")
	if err != nil {
		log.Fatalf("连接以太坊节点失败: %v", err)
	}

	// functions.QueryBlockInfo(client, 9233668)

	// 发送交易
	privateKey, err := crypto.HexToECDSA("此处填入你的私钥")
	if err != nil {
		log.Fatalf("私钥转换失败: %v", err)
	}
	to := common.HexToAddress("0x4592d8f8d7b001e72cb26a73e4fa1806a51ac79d")
	amount := big.NewInt(1000000000000000) // 0.001 ETH
	functions.TransferAccount(client, privateKey, to, amount)

	//执行合约
	functions.ExecutionContract(client)
}
