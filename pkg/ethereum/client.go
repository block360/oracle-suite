//  Copyright (C) 2020 Maker Ecosystem Growth Holdings, INC.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as
//  published by the Free Software Foundation, either version 3 of the
//  License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.

package ethereum

import (
	"context"
	"math/big"

	"github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/core/types"
)

// Transaction represents Ethereum transaction.
//
// Deprecated.
type Transaction struct {
	// Address is the contract's address.
	Address Address
	// Nonce is the transaction nonce. If zero, the nonce will be filled
	// automatically.
	Nonce uint64
	// PriorityFee is the maximum tip value. If nil, the suggested gas tip value
	// will be used.
	PriorityFee *big.Int
	// MaxFee is the maximum fee value. If nil, double value of a suggested
	// gas fee will be used.
	MaxFee *big.Int
	// GasLimit is the maximum gas available to be used for this transaction.
	GasLimit *big.Int
	// Data is the raw transaction data.
	Data []byte
	// ChainID is the transaction chain ID. If nil, the chan ID will be filled
	// automatically.
	ChainID *big.Int
	// SignedTx contains signed transaction. The data type stored here may
	// be different for various implementations.
	SignedTx interface{}
}

// Call represents a call to a contract.
//
// Deprecated.
type Call struct {
	// Address is the contract's address.
	Address Address
	// Data is the raw call data.
	Data []byte
}

// Client is an interface for Ethereum blockchain.
//
// Deprecated.
type Client interface {
	// BlockNumber returns the current block number.
	BlockNumber(ctx context.Context) (*big.Int, error)
	// Block returns the block data. The block number can be changed by using
	// the WithBlockNumber context.
	Block(ctx context.Context) (*types.Block, error)
	// Call executes a message call transaction, which is directly
	// executed in the VM of the node, but never mined into the blockchain.
	Call(ctx context.Context, call Call) ([]byte, error)
	// CallBlocks executes the same call on multiple blocks (counting back from the latest)
	// and returns multiple results in a slice
	CallBlocks(ctx context.Context, call Call, blocks []int64) ([][]byte, error)
	// MultiCall works like the Call function but allows to execute multiple
	// calls at once.
	MultiCall(ctx context.Context, calls []Call) ([][]byte, error)
	// Storage returns the value of key in the contract storage of the
	// given account.
	Storage(ctx context.Context, address Address, key Hash) ([]byte, error)
	// SendTransaction injects a signed transaction into the pending pool
	// for execution.
	SendTransaction(ctx context.Context, transaction *Transaction) (*Hash, error)
	// FilterLogs executes a filter query.
	FilterLogs(ctx context.Context, query ethereum.FilterQuery) ([]types.Log, error)
}

type contextKey string

const contextBlockNumber contextKey = "ethereum_block_number"

// WithBlockNumber sets the block number in the context.
//
// Deprecated.
func WithBlockNumber(ctx context.Context, block *big.Int) context.Context {
	return context.WithValue(ctx, contextBlockNumber, block)
}

// BlockNumberFromContext returns the block number from the context.
//
// Deprecated.
func BlockNumberFromContext(ctx context.Context) *big.Int {
	n, ok := ctx.Value(contextBlockNumber).(*big.Int)
	if ok {
		return n
	}
	return nil
}
