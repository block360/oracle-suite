# gofer

[![CircleCI](https://circleci.com/gh/makerdao/gofer.svg?style=svg&circle-token=a7007c0430edac55d1625526a2ad7c0151bbc8c6)](https://circleci.com/gh/makerdao/gofer)

## Building and testing

Build binaries to `workdir/`

```sh
make build
```

Run tests

```sh
make test
```

Run benchmarks

```sh
make bench
```

## Structure

  - `cmd/` CLI entrypoints
  - `app/` run-time entrypoint
  - `reducer/` business logic
  - `config/` run-time configuration using JSON files


## Query Engine

#### Worker Pool Usage

```go
package main

import (
	"fmt"
	"makerdao/gofer/query"
)

func main() {
	pool := query.NewWorkerPool(5)
	pool.Start()

	q := &query.HTTPRequest{URL: "https://www.binance.com/api/v3/ticker/price?symbol=ETHBTC"}
	for j := 1; j <= 10; j++ {
		res := pool.Query(q)
		if res.Error != nil {
			fmt.Println("failed to make request", res.Error)
		} else {
			fmt.Println("we got response", string(res.Body))
		}
	}
	pool.Stop()
}
```
