import Config

config :logger, level: :warn

config :arctic_client_mint_adapter, mint_http2_adapter: ArcticClientMintAdapter.MintHTTP2.Mock
