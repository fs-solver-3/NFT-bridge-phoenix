defmodule BridgeServer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      BridgeServer.Repo,
      # Start the Telemetry supervisor
      BridgeServerWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: BridgeServer.PubSub},
      # Start the Endpoint (http/https)
      BridgeServerWeb.Endpoint,
      {Redix, name: :redix, host: System.get_env("REDIS_HOST", "localhost"), sync_connect: true},
      {BridgeServer.SolanaClient, []}
      # Start a worker by calling: BridgeServer.Worker.start_link(arg)
      # {BridgeServer.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BridgeServer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    BridgeServerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
