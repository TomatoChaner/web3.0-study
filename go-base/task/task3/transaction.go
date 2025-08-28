/*
假设有两个表： accounts 表（包含字段 id 主键， balance 账户余额）
和 transactions 表（包含字段 id 主键， from_account_id 转出账户ID， to_account_id 转入账户ID， amount 转账金额）。
要求 ：
编写一个事务，实现从账户 A 向账户 B 转账 100 元的操作。
在事务中，需要先检查账户 A 的余额是否足够，
如果足够则从账户 A 扣除 100 元，向账户 B 增加 100 元，
并在 transactions 表中记录该笔转账信息。如果余额不足，则回滚事务。
*/
package main

import (
	"errors"
	"fmt"
	"log"

	"gorm.io/gorm"
)

type Account struct {
	ID      uint `gorm:"primarykey"`
	Balance int  `gorm:"default:0"`
}

type Transaction struct {
	ID            uint `gorm:"primarykey"`
	FromAccountID uint
	ToAccountID   uint
	Amount        int `gorm:"default:0"`
}

// 转账函数
func Transfer(db *gorm.DB, fromAccountID, toAccountID uint, amount int) error {
	log.Printf("开始转账操作: 从账户%d向账户%d转账%d元", fromAccountID, toAccountID, amount)

	// 开启事务
	tx := db.Begin()
	if tx.Error != nil {
		log.Printf("开启事务失败: %v", tx.Error)
		return tx.Error
	}
	log.Println("事务开启成功")

	// 检查账户 A 的余额是否足够
	var fromAccount Account
	tx.Where("id = ?", fromAccountID).First(&fromAccount)
	log.Printf("查询转出账户%d余额: %d元", fromAccountID, fromAccount.Balance)

	if fromAccount.Balance < amount {
		// 余额不足，回滚事务
		log.Printf("余额不足，当前余额%d元，转账金额%d元，开始回滚事务", fromAccount.Balance, amount)
		tx.Rollback()
		log.Println("事务回滚完成")
		return errors.New("余额不足")
	}
	log.Printf("余额检查通过，当前余额%d元，转账金额%d元", fromAccount.Balance, amount)

	// 从账户 A 扣除金额
	log.Printf("从账户%d扣除%d元", fromAccountID, amount)
	tx.Model(&Account{}).Where("id = ?", fromAccountID).Update("balance", gorm.Expr("balance - ?", amount))
	log.Printf("账户%d扣款完成", fromAccountID)

	// 向账户 B 增加金额
	log.Printf("向账户%d增加%d元", toAccountID, amount)
	tx.Model(&Account{}).Where("id = ?", toAccountID).Update("balance", gorm.Expr("balance + ?", amount))
	log.Printf("账户%d入账完成", toAccountID)

	// 记录转账信息
	log.Println("开始记录转账信息")
	tx.Create(&Transaction{
		FromAccountID: fromAccountID,
		ToAccountID:   toAccountID,
		Amount:        amount,
	})
	log.Printf("转账记录创建完成: 从账户%d到账户%d，金额%d元", fromAccountID, toAccountID, amount)

	// 提交事务
	log.Println("开始提交事务")
	tx.Commit()
	fmt.Printf("转账成功: 从账户%d向账户%d转账%d元\n", fromAccountID, toAccountID, amount)
	return nil
}
