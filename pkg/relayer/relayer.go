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

package relayer

import (
	"context"
	"errors"
	"math/big"
	"sync"
	"time"

	"github.com/makerdao/gofer/internal/oracle"
)

type Relayer struct {
	mu sync.Mutex

	interval time.Duration
	pairs    map[string]Pair
	doneCh   chan bool
}

type Pair struct {
	// AssetPair is the name of asset pair, e.g. ETHUSD.
	AssetPair string
	// OracleSpread is the minimum spread between the oracle price and new price
	// required to send update.
	OracleSpread float64
	// OracleExpiration is the minimum time difference between the oracle time
	// and current time required to send update.
	OracleExpiration time.Duration
	// PriceExpiration is the maximum TTL of the price from feeder.
	PriceExpiration time.Duration
	// Median is the instance of the oracle.Median which is the interface for
	// the median oracle contract.
	Median *oracle.Median
	// prices contains list of prices form the feeders.
	prices *Prices
}

func NewRelayer(interval time.Duration) *Relayer {
	return &Relayer{
		interval: interval,
		pairs:    make(map[string]Pair, 0),
		doneCh:   make(chan bool, 0),
	}
}

func (r *Relayer) AddPair(pair Pair) {
	r.mu.Lock()
	defer r.mu.Unlock()

	pair.prices = NewPrices(pair.AssetPair, pair.PriceExpiration)
	r.pairs[pair.AssetPair] = pair
}

func (r *Relayer) Collect(price *oracle.Price) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	if price.Val.Cmp(big.NewInt(0)) == 0 {
		return errors.New("invalid price")
	}

	err := r.pairs[price.AssetPair].prices.Add(price)
	if err != nil {
		return err
	}

	return nil
}

func (r *Relayer) Start(onSuccessChan chan<- string, onErrChan chan<- error) {
	r.doneCh = make(chan bool)
	ticker := time.NewTicker(r.interval)
	go func() {
		for {
			select {
			case <-r.doneCh:
				ticker.Stop()
				return
			case <-ticker.C:
				r.mu.Lock()
				for assetPair, pair := range r.pairs {
					if pair.prices.Len() == 0 {
						continue
					}

					err := r.relay(assetPair)
					if err != nil && onErrChan != nil {
						onErrChan <- err
					}
					if err == nil && onSuccessChan != nil {
						onSuccessChan <- assetPair
					}
				}
				r.mu.Unlock()
			}
		}
	}()
}

func (r *Relayer) Stop() {
	r.doneCh <- true
}

func (r *Relayer) relay(assetPair string) error {
	ctx := context.Background()

	pair := r.pairs[assetPair]
	pair.prices.ClearExpired()

	// Check if the oracle price is expired:
	oracleTime, err := pair.Median.Age(ctx)
	if err != nil {
		return err
	}
	if oracleTime.Add(pair.OracleExpiration).After(time.Now()) {
		return errors.New("unable to update oracle, price is not expired yet")
	}

	// Check if there are enough prices to achieve a quorum:
	quorum, err := pair.Median.Bar(ctx)
	if err != nil {
		return err
	}
	if pair.prices.Len() < quorum {
		return errors.New("unable to update oracle, there is not enough prices to achieve a quorum")
	}

	// Use only a minimum prices required to achieve a quorum, this will save some gas:
	pair.prices.Truncate(quorum)

	// Check if spread is large enough:
	medianPrice := pair.prices.Median()
	oldPrice, err := pair.Median.Price(ctx)
	if err != nil {
		return err
	}
	spread := calcSpread(oldPrice, medianPrice)
	if spread < pair.OracleSpread {
		return errors.New("unable to update oracle, spread is too low")
	}

	// Send transaction:
	_, err = pair.Median.Poke(ctx, pair.prices.Get())

	// Remove prices:
	pair.prices.Clear()

	return err
}

func calcSpread(oldPrice, newPrice *big.Int) float64 {
	oldPriceF := new(big.Float).SetInt(oldPrice)
	newPriceF := new(big.Float).SetInt(newPrice)

	x := new(big.Float).Sub(newPriceF, oldPriceF)
	x = new(big.Float).Quo(x, oldPriceF)
	x = new(big.Float).Mul(x, big.NewFloat(100))

	xf, _ := x.Float64()

	return xf
}
