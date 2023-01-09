defmodule BridgeServer.Repo do
  use Ecto.Repo,
    otp_app: :bridge_server,
    adapter: Ecto.Adapters.Postgres
end
