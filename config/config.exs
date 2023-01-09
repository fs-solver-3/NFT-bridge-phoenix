# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :bridge_server,
  ecto_repos: [BridgeServer.Repo]

# Configures the endpoint
config :bridge_server, BridgeServerWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: BridgeServerWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: BridgeServer.PubSub,
  live_view: [signing_salt: "nhpdwDBc"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :bridge_server, BridgeServer.Mailer, adapter: Swoosh.Adapters.Local

# Swoosh API client is needed for adapters other than SMTP.
config :swoosh, :api_client, false

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.14.0",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# config variables
config :bridge_server,
  sol_custodial_address: "JC3DfEXheRf342LNyJgjk6K2sUihDqj5ZRu9b43cRge6",
  mint_address: "8RJLmkArbX1SaU2NqKzAbLtSXjJypTLoKbiGMb461VhE",
  api_key_id: "azUxcw9BppfsuOk",
  api_secret_key: "KjIcdKIEjIC7KI9",
  tokenUri: "https://arweave.net/B4T7noSr8mhPCekdMKWQI2haqnHrjsdJOwWG8I7fVbw",
  eth_contract_address: "0x53edEd17bCe2fE1Cf3fc6e1b8F76f0Fea226f06B",
  eth_owner_address: "0xF6B73a6546aDb38616289612D8E4cF7cC3f6789E",
  eth_mint_address: "0xF6B73a6546aDb38616289612D8E4cF7cC3f6789E",
  eth_custodial_address: "0x390A0815e69F068C7859A9fF07A01aC54A2a9968",
  solana_network: "devnet",
  solana_payer_wallet_file: "/Users/mac/.config/solana/bridge-wallet.json",
  solana_payer_account: "6bFMTrtXGoaPrkw6HPZbpHUPDTGRhX5N4NiNrWrnCLd9"

# config ethereum
config :ethereumex,
  url: "https://rinkeby.infura.io/v3/15c4175c70104ee490eb888b2b7ea225"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
