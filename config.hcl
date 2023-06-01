include = [
  "./config_gofernext.hcl"
]

variables {
  # List of feeds that are allowed to send price updates and event attestations.
  feeds = try(env.CFG_FEEDS == "" ? [] : split(",", env.CFG_FEEDS), [
    "0xDA1d2961Da837891f43235FddF66BAD26f41368b",
    "0x4b0E327C08e23dD08cb87Ec994915a5375619aa2",
    "0x75ef8432566A79C86BBF207A47df3963B8Cf0753",
    "0x83e23C207a67a9f9cB680ce84869B91473403e7d",
    "0xFbaF3a7eB4Ec2962bd1847687E56aAEE855F5D00",
    "0xfeEd00AA3F0845AFE52Df9ECFE372549B74C69D2",
    "0x71eCFF5261bAA115dcB1D9335c88678324b8A987",
    "0x8ff6a38A1CD6a42cAac45F08eB0c802253f68dfD",
    "0x16655369Eb59F3e1cAFBCfAC6D3Dd4001328f747",
    "0xD09506dAC64aaA718b45346a032F934602e29cca",
    "0xc00584B271F378A0169dd9e5b165c0945B4fE498",
    "0x60da93D9903cb7d3eD450D4F81D402f7C4F71dd9",
    "0xa580BBCB1Cee2BCec4De2Ea870D20a12A964819e",
    "0xD27Fa2361bC2CfB9A591fb289244C538E190684B",
    "0x8de9c5F1AC1D4d02bbfC25fD178f5DAA4D5B26dC",
    "0xE6367a7Da2b20ecB94A25Ef06F3b551baB2682e6",
    "0xA8EB82456ed9bAE55841529888cDE9152468635A",
    "0x130431b4560Cd1d74A990AE86C337a33171FF3c6",
    "0x8aFBD9c3D794eD8DF903b3468f4c4Ea85be953FB",
    "0xd94BBe83b4a68940839cD151478852d16B3eF891",
    "0xC9508E9E3Ccf319F5333A5B8c825418ABeC688BA",
    "0x77EB6CF8d732fe4D92c427fCdd83142DB3B742f7",
    "0x3CB645a8f10Fb7B0721eaBaE958F77a878441Cb9",
    "0x4f95d9B4D842B2E2B1d1AC3f2Cf548B93Fd77c67",
    "0xaC8519b3495d8A3E3E44c041521cF7aC3f8F63B3",
    "0xd72BA9402E9f3Ff01959D6c841DDD13615FFff42"
  ])
}

ethereum {
  rand_keys = try(env.CFG_ETH_FROM, "") == "" ? ["default"] : []

  dynamic "key" {
    for_each = try(env.CFG_ETH_FROM, "") == "" ? [] : [1]
    labels   = ["default"]
    content {
      address         = try(env.CFG_ETH_FROM, "")
      keystore_path   = try(env.CFG_ETH_KEYS, "")
      passphrase_file = try(env.CFG_ETH_PASS, "")
    }
  }

  client "default" {
    rpc_urls     = try(env.CFG_ETH_RPC_URLS == "" ? [] : split(",", env.CFG_ETH_RPC_URLS), [
      "https://eth.public-rpc.com"
    ])
    chain_id     = tonumber(try(env.CFG_ETH_CHAIN_ID, "1"))
    ethereum_key = "default"
  }

  client "arbitrum" {
    rpc_urls     = try(env.CFG_ETH_ARB_RPC_URLS == "" ? [] : split(",", env.CFG_ETH_ARB_RPC_URLS), [
      "https://arbitrum.public-rpc.com"
    ])
    chain_id     = tonumber(try(env.CFG_ETH_ARB_CHAIN_ID, "42161"))
    ethereum_key = "default"
  }

  client "optimism" {
    rpc_urls     = try(env.CFG_ETH_OPT_RPC_URLS == "" ? [] : split(",", env.CFG_ETH_OPT_RPC_URLS), [
      "https://mainnet.optimism.io"
    ])
    chain_id     = tonumber(try(env.CFG_ETH_OPT_CHAIN_ID, "10"))
    ethereum_key = "default"
  }
}

transport {
  # LibP2P transport configuration. Always enabled.
  libp2p {
    feeds           = var.feeds
    priv_key_seed   = try(env.CFG_LIBP2P_PK_SEED, "")
    listen_addrs    = try(split(",", env.CFG_LIBP2P_LISTEN_ADDRS), ["/ip4/0.0.0.0/tcp/8000"])
    bootstrap_addrs = try(env.CFG_LIBP2P_BOOTSTRAP_ADDRS == "" ? [] : split(",", env.CFG_LIBP2P_BOOTSTRAP_ADDRS), [
      "/dns/spire-bootstrap1.makerops.services/tcp/8000/p2p/12D3KooWRfYU5FaY9SmJcRD5Ku7c1XMBRqV6oM4nsnGQ1QRakSJi",
      "/dns/spire-bootstrap2.makerops.services/tcp/8000/p2p/12D3KooWBGqjW4LuHUoYZUhbWW1PnDVRUvUEpc4qgWE3Yg9z1MoR"
    ])
    direct_peers_addrs = try(env.CFG_LIBP2P_DIRECT_PEERS_ADDRS == "" ? [] : split(",", env.CFG_LIBP2P_DIRECT_PEERS_ADDRS), [])
    blocked_addrs      = try(env.CFG_LIBP2P_BLOCKED_ADDRS == "" ? [] : split(",", env.CFG_LIBP2P_BLOCKED_ADDRS), [])
    disable_discovery  = tobool(try(env.CFG_LIBP2P_DISABLE_DISCOVERY, false))
    ethereum_key       = try(env.CFG_ETH_FROM, "") == "" ? "" : "default"
  }

  # WebAPI transport configuration. Enabled if CFG_WEBAPI_LISTEN_ADDR is set to a listen address.
  dynamic "webapi" {
    for_each = try(env.CFG_WEBAPI_LISTEN_ADDR, "") == "" ? [] : [1]
    content {
      feeds             = var.feeds
      listen_addr       = try(env.CFG_WEBAPI_LISTEN_ADDR, "0.0.0.0.8080")
      socks5_proxy_addr = try(env.CFG_WEBAPI_SOCKS5_PROXY_ADDR, "127.0.0.1:9050")
      ethereum_key      = try(env.CFG_ETH_FROM, "") == "" ? "" : "default"

      # Ethereum based address book. Enabled if CFG_WEBAPI_ETH_ADDR_BOOK is set to a contract address.
      dynamic "ethereum_address_book" {
        for_each = try(env.CFG_WEBAPI_ETH_ADDR_BOOK, "") == "" ? [] : [1]
        content {
          contract_addr   = try(env.CFG_WEBAPI_ETH_ADDR_BOOK, "")
          ethereum_client = "default"
        }
      }

      # Static address book. Enabled if CFG_WEBAPI_STATIC_ADDR_BOOK is set to a comma separated list of addresses.
      dynamic "static_address_book" {
        for_each = try(env.CFG_WEBAPI_STATIC_ADDR_BOOK, "") == "" ? [] : [1]
        content {
          addresses = try(split(",", env.CFG_WEBAPI_STATIC_ADDR_BOOK), "")
        }
      }
    }
  }
}

spire {
  rpc_listen_addr = try(env.CFG_SPIRE_RPC_ADDR, "0.0.0.0:9100")
  rpc_agent_addr  = try(env.CFG_SPIRE_RPC_ADDR, "127.0.0.1:9100")

  # List of pairs that are collected by the spire node. Other pairs are ignored.
  pairs = try(env.CFG_SPIRE_PAIRS == "" ? [] : split(",", env.CFG_SPIRE_PAIRS), [
    "AAVEUSD",
    "AVAXUSD",
    "BALUSD",
    "BATUSD",
    "BTCUSD",
    "COMPUSD",
    "CRVUSD",
    "DOTUSD",
    "ETHBTC",
    "ETHUSD",
    "FILUSD",
    "GNOUSD",
    "IBTAUSD",
    "LINKUSD",
    "LRCUSD",
    "MANAUSD",
    "MKRETH",
    "MKRUSD",
    "PAXGUSD",
    "RETHUSD",
    "SNXUSD",
    "SOLUSD",
    "UNIUSD",
    "USDTUSD",
    "WNXMUSD",
    "XRPUSD",
    "XTZUSD",
    "YFIUSD",
    "ZECUSD",
    "ZRXUSD",
    "STETHUSD",
    "WSTETHUSD",
    "MATICUSD"
  ])
}

ghost {
  ethereum_key = "default"
  interval     = try(tonumber(env.CFG_GHOST_INTERVAL, 60))
  pairs        = try(env.CFG_GHOST_PAIRS == "" ? [] : split(",", env.CFG_GHOST_PAIRS), [
    "AAVE/USD",
    "AVAX/USD",
    "BAL/USD",
    "BAT/USD",
    "BTC/USD",
    "COMP/USD",
    "CRV/USD",
    "DOT/USD",
    "ETH/BTC",
    "ETH/USD",
    "FIL/USD",
    "GNO/USD",
    "IBTA/USD",
    "LINK/USD",
    "LRC/USD",
    "MANA/USD",
    "MKR/ETH",
    "MKR/USD",
    "PAXG/USD",
    "RETH/USD",
    "SNX/USD",
    "SOL/USD",
    "UNI/USD",
    "USDT/USD",
    "WNXM/USD",
    "XRP/USD",
    "XTZ/USD",
    "YFI/USD",
    "ZEC/USD",
    "ZRX/USD",
    "STETH/USD",
    "WSTETH/USD",
    "MATIC/USD"
  ])
}

gofer {
  

  price_model "ETH/GSU" "median" {
    source "ETH/GSU" "origin" { origin = "gsu" }
    source "ETH/GSU" "origin" { origin = "gsu1" }
    source "ETH/GSU" "origin" { origin = "gsu2" }
    min_sources = 1
  }
}

leeloo {
  ethereum_key = "default"

  # Arbitrum
  # Enabled if CFG_TELEPORT_EVM_ARB_CONTRACT_ADDRS is set.
  dynamic "teleport_evm" {
    for_each = try(env.CFG_TELEPORT_EVM_ARB_CONTRACT_ADDRS, "") == "" ? [] : [1]
    content {
      ethereum_client     = "arbitrum"
      interval            = tonumber(try(env.CFG_TELEPORT_EVM_ARB_INTERVAL, 60))
      prefetch_period     = tonumber(try(env.CFG_TELEPORT_EVM_ARB_PREFETCH_PERIOD, 3600 * 24 * 7))
      block_confirmations = tonumber(try(env.CFG_TELEPORT_EVM_ARB_BLOCK_CONFIRMATIONS, 0))
      block_limit         = tonumber(try(env.CFG_TELEPORT_EVM_ARB_BLOCK_LIMIT, 1000))
      replay_after        = concat(
        [60, 300, 3600, 3600*2, 3600*4],
        [for i in range(3600 * 6, 3600 * 24 * 7, 3600 * 6) :i]
      )
      contract_addrs = try(split(",", env.CFG_TELEPORT_EVM_ARB_CONTRACT_ADDRS), [])
    }
  }

  # Optimism
  # Enabled if CFG_TELEPORT_EVM_OPT_CONTRACT_ADDRS is set.
  dynamic "teleport_evm" {
    for_each = try(env.CFG_TELEPORT_EVM_OPT_CONTRACT_ADDRS, "") == "" ? [] : [1]
    content {
      ethereum_client     = "optimism"
      interval            = tonumber(try(env.CFG_TELEPORT_EVM_OPT_INTERVAL, 60))
      prefetch_period     = tonumber(try(env.CFG_TELEPORT_EVM_OPT_PREFETCH_PERIOD, 3600 * 24 * 7))
      block_confirmations = tonumber(try(env.CFG_TELEPORT_EVM_OPT_BLOCK_CONFIRMATIONS, 0))
      block_limit         = tonumber(try(env.CFG_TELEPORT_EVM_OPT_BLOCK_LIMIT, 1000))
      replay_after        = concat(
        [60, 300, 3600, 3600*2, 3600*4],
        [for i in range(3600 * 6, 3600 * 24 * 7, 3600 * 6) :i]
      )
      contract_addrs = try(split(",", env.CFG_TELEPORT_EVM_OPT_CONTRACT_ADDRS), [])
    }
  }

  # Starknet
  # Enabled if CFG_TELEPORT_STARKNET_CONTRACT_ADDRS is set.
  dynamic "teleport_starknet" {
    for_each = try(env.CFG_TELEPORT_STARKNET_CONTRACT_ADDRS, "") == "" ? [] : [1]
    content {
      sequencer       = try(env.CFG_TELEPORT_STARKNET_SEQUENCER, "https://alpha-mainnet.starknet.io")
      interval        = tonumber(try(env.CFG_TELEPORT_STARKNET_INTERVAL, 60))
      prefetch_period = tonumber(try(env.CFG_TELEPORT_STARKNET_PREFETCH_PERIOD, 3600 * 24 * 7))
      replay_after    = concat(
        [60, 300, 3600, 3600*2, 3600*4],
        [for i in range(3600 * 6, 3600 * 24 * 7, 3600 * 6) :i]
      )
      contract_addrs = try(split(",", env.CFG_TELEPORT_STARKNET_CONTRACT_ADDRS), [])
    }
  }
}

lair {
  listen_addr = try(env.CFG_LAIR_LISTEN_ADDR, "0.0.0.0:8082")

  # Configuration for memory storage. Enabled if CFG_LAIR_STORAGE is "memory" or unset.
  dynamic "storage_memory" {
    for_each = try(env.CFG_LAIR_STORAGE, "memory") == "memory" ? [1] : []
    content {}
  }

  # Configuration for redis storage. Enabled if CFG_LAIR_STORAGE is "redis".
  dynamic "storage_redis" {
    for_each = try(env.CFG_LAIR_STORAGE, "") == "redis" ? [1] : []
    content {
      addr                     = try(env.CFG_LAIR_REDIS_ADDR, "127.0.0.1:6379")
      user                     = try(env.CFG_LAIR_REDIS_USER, "")
      pass                     = try(env.CFG_LAIR_REDIS_PASS, "")
      db                       = tonumber(try(env.CFG_LAIR_REDIS_DB, 0))
      memory_limit             = tonumber(try(env.CFG_LAIR_REDIS_MEMORY_LIMIT, 0))
      tls                      = tobool(try(env.CFG_LAIR_REDIS_TLS, false))
      tls_server_name          = try(env.CFG_LAIR_REDIS_TLS_SERVER_NAME, "")
      tls_cert_file            = try(env.CFG_LAIR_REDIS_TLS_CERT_FILE, "")
      tls_key_file             = try(env.CFG_LAIR_REDIS_TLS_KEY_FILE, "")
      tls_root_ca_file         = try(env.CFG_LAIR_REDIS_TLS_ROOT_CA_FILE, "")
      tls_insecure_skip_verify = tobool(try(env.CFG_LAIR_REDIS_TLS_INSECURE, false))
      cluster                  = tobool(try(env.CFG_LAIR_REDIS_CLUSTER, false))
      cluster_addrs            = try(env.CFG_LAIR_REDIS_CLUSTER_ADDRS == "" ? [] : split(",", env.CFG_LAIR_REDIS_CLUSTER_ADDRS), [])
    }
  }
}
