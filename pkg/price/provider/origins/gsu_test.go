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

package origins

import (
	"fmt"
	"testing"

	"github.com/stretchr/testify/suite"

	"github.com/chronicleprotocol/oracle-suite/pkg/util/query"
)

// Define the suite, and absorb the built-in basic suite
// functionality from testify - including a T() method which
// returns the current testing context
type GSUSuite struct {
	suite.Suite
	pool   query.WorkerPool
	origin *BaseExchangeHandler
}

func (suite *GSUSuite) Origin() Handler {
	return suite.origin
}

// Setup exchange
func (suite *GSUSuite) SetupSuite() {
	suite.origin = NewBaseExchangeHandler(GSU{WorkerPool: query.NewMockWorkerPool()}, nil)
}

func (suite *GSUSuite) TearDownTest() {
	// cleanup created pool from prev test
	if suite.pool != nil {
		suite.pool = nil
	}
}

func (suite *GSUSuite) TestLocalPair() {
	ex := suite.origin.ExchangeHandler.(GSU)
	suite.EqualValues("BTC", ex.localPairName(Pair{Base: "BTC", Quote: "GSU"}))
	suite.EqualValues("ETH", ex.localPairName(Pair{Base: "ETH", Quote: "GSU"}))
}

func (suite *GSUSuite) TestFailOnWrongInput() {
	pair := Pair{Base: "BTC", Quote: "ETH"}
	// nil as response
	cr := suite.origin.Fetch([]Pair{pair})
	suite.Equal(ErrEmptyOriginResponse, cr[0].Error)

	// error in response
	ourErr := fmt.Errorf("error")
	resp := &query.HTTPResponse{
		Error: ourErr,
	}
	suite.origin.ExchangeHandler.(GSU).Pool().(*query.MockWorkerPool).MockResp(resp)
	cr = suite.origin.Fetch([]Pair{pair})
	suite.Equal(ourErr, cr[0].Error)

	// Error unmarshal
	resp = &query.HTTPResponse{
		Body: []byte(""),
	}
	suite.origin.ExchangeHandler.(GSU).Pool().(*query.MockWorkerPool).MockResp(resp)
	cr = suite.origin.Fetch([]Pair{pair})
	suite.Error(cr[0].Error)

	// Error parsing
	resp = &query.HTTPResponse{
		Body: []byte(`[{"last":"abc"}]`),
	}
	suite.origin.ExchangeHandler.(GSU).Pool().(*query.MockWorkerPool).MockResp(resp)
	cr = suite.origin.Fetch([]Pair{pair})
	suite.Error(cr[0].Error)

	// Error parsing
	resp = &query.HTTPResponse{
		Body: []byte(`[{"last":"1","ask":"abc"}]`),
	}
	suite.origin.ExchangeHandler.(GSU).Pool().(*query.MockWorkerPool).MockResp(resp)
	cr = suite.origin.Fetch([]Pair{pair})
	suite.Error(cr[0].Error)

	// Error parsing
	resp = &query.HTTPResponse{
		Body: []byte(`[{"last":"1","ask":"1","volume":"abc"}]`),
	}
	suite.origin.ExchangeHandler.(GSU).Pool().(*query.MockWorkerPool).MockResp(resp)
	cr = suite.origin.Fetch([]Pair{pair})
	suite.Error(cr[0].Error)

	// Error parsing
	resp = &query.HTTPResponse{
		Body: []byte(`[{"last":"1","ask":"1","volume":"1","bid":"abc"}]`),
	}
	suite.origin.ExchangeHandler.(GSU).Pool().(*query.MockWorkerPool).MockResp(resp)
	cr = suite.origin.Fetch([]Pair{pair})
	suite.Error(cr[0].Error)

	// Error parsing
	resp = &query.HTTPResponse{
		Body: []byte(`[{"last":"1","ask":"1","volume":"1","bid":"abc","symbol":"abc"}]`),
	}
	suite.origin.ExchangeHandler.(GSU).Pool().(*query.MockWorkerPool).MockResp(resp)
	cr = suite.origin.Fetch([]Pair{pair})
	suite.Error(cr[0].Error)

	// Error parsing
	resp = &query.HTTPResponse{
		Body: []byte(`{"last":"1","ask":"2","volume":"3","bid":"4","symbol":"BTCETH","timestamp":"2020-04-24T20:09:36.229Z"}`),
	}
	suite.origin.ExchangeHandler.(GSU).Pool().(*query.MockWorkerPool).MockResp(resp)
	cr = suite.origin.Fetch([]Pair{pair})
	suite.Error(cr[0].Error)
}

func (suite *GSUSuite) TestSuccessResponse() {
	// Empty fetch.
	cr := suite.origin.Fetch([]Pair{})
	suite.Len(cr, 0)

	pair := Pair{Base: "BTC", Quote: "ETH"}
	resp := &query.HTTPResponse{
		Body: []byte(`{"price":"1249611560404303900000","ask":"0","volume":"0","bid":"bid"}`),
	}
	suite.origin.ExchangeHandler.(GSU).Pool().(*query.MockWorkerPool).MockResp(resp)
	cr = suite.origin.Fetch([]Pair{pair})
	suite.NoError(cr[0].Error)
	suite.Equal(1249.6115604043039, cr[0].Price.Price)
	suite.Equal(0.0, cr[0].Price.Ask)
	suite.Equal(0.0, cr[0].Price.Volume24h)
	suite.Equal(0.0, cr[0].Price.Bid)
}

func (suite *GSUSuite) TestRealAPICall() {
	hitbtc := NewBaseExchangeHandler(Hitbtc{WorkerPool: query.NewHTTPWorkerPool(1)}, nil)

	testRealAPICall(suite, hitbtc, "ETH", "GSU")
	testRealBatchAPICall(suite, hitbtc, []Pair{
		{Base: "BTC", Quote: "GSU"},
		{Base: "ETH", Quote: "GSU"},
	})
}

// In order for 'go test' to run this suite, we need to create
// a normal test function and pass our suite to suite.Run
func TestGSUSuite(t *testing.T) {
	suite.Run(t, new(GSUSuite))
}
