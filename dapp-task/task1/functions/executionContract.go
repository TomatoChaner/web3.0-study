package functions

import (
	"context"
	"fmt"
	"log"

	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"

	counter "task1/contract"
)

func ExecutionContract(client *ethclient.Client) {
	const contractAddressHex = "0x2418E6b2335b22dB3e2c3513587578BC0870510E"
	contractAddress := common.HexToAddress(contractAddressHex)

	counterContract, err1 := counter.NewCounter(contractAddress, client)
	if err1 != nil {
		log.Fatal(err1)
	}

	//获取chainID
	chainId, err2 := client.NetworkID(context.Background())
	if err2 != nil {
		log.Fatal(err2)
	}
	fmt.Printf("chainId: %s\n", chainId)

	//私钥
	privateKey, err3 := crypto.HexToECDSA("此处填入你的私钥")
	if err3 != nil {
		log.Fatal(err3)
	}

	//利用私钥创建交易签名
	opt, err4 := bind.NewKeyedTransactorWithChainID(privateKey, chainId)
	if err4 != nil {
		log.Fatal(err4)
	}

	tx, err5 := counterContract.Increment(opt)
	if err5 != nil {
		log.Fatal(err5)
	}

	fmt.Println("tx hash:", tx.Hash().Hex())

	result, err6 := counterContract.Count(&bind.CallOpts{})
	if err6 != nil {
		log.Fatal(err6)
	}

	fmt.Println("v:", result)
}
