defmodule BridgeServerWeb.EthereumController do
  use BridgeServerWeb, :controller
  require Logger

  alias Ethereumex.HttpClient

  def index(conn, _params) do
    res = HttpClient.web3_client_version()
    Logger.info(inspect(res))

    render(conn, "index.html")
  end

  def mint(conn, params) do
    case EthClient.mint(
           params["eth_mint_address"],
           params["tokenUri"],
           Application.get_env(:bridge_server, :eth_contract_address),
           Application.get_env(:bridge_server, :eth_owner_address)
         ) do
      {:ok, hash} ->
        json(conn, %{data: %{hash: hash, eth_mint_address: params["eth_mint_address"]}})

      {:error, _} ->
        json(conn, %{data: %{error: "Error processing request"}})
    end
  end

  def transferFrom(conn, params) do
    eth_custodial_address = Application.get_env(:bridge_server, :eth_custodial_address)

    case EthClient.transferFrom(
           params["eth_from_address"],
           eth_custodial_address,
           params["tokenId"],
           Application.get_env(:bridge_server, :eth_contract_address)
         ) do
      {:ok, hash} ->
        json(conn, %{data: %{hash: hash, eth_custodial_address: eth_custodial_address}})

      {:error, _} ->
        json(conn, %{data: %{error: "Error processing request"}})
    end
  end

  def getBalanceETH(conn, params) do
    case ExW3.balance(params["address"]) do
      balanceETH ->
        json(conn, %{data: %{balanceETH: balanceETH}})
    end
  end

  def getBalanceNFT(conn, params) do
    case EthClient.getBalanceOf(
           params["address"],
           Application.get_env(:bridge_server, :eth_contract_address)
         ) do
      {:ok, balanceInt} ->
        json(conn, %{data: %{balanceNFT: balanceInt}})

      {:error, _} ->
        json(conn, %{data: %{error: "Error processing request"}})
    end
  end
end
