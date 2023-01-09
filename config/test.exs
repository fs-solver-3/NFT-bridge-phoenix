import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :bridge_server, BridgeServer.Repo,
  username: "mac",
  password: "root",
  hostname: "localhost",
  database: "bridge_server_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :bridge_server, BridgeServerWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "yQGF1gVQQ1z3WyTHJJwykArzHVAyn2F/Yb9IeRHh3i46oP4nS2CHLF3MQtnCpszf",
  server: false

# In test we don't send emails.
config :bridge_server, BridgeServer.Mailer, adapter: Swoosh.Adapters.Test

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
