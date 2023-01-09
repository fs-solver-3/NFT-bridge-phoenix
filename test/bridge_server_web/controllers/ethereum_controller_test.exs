defmodule BridgeServerWeb.EthereumControllerTest do
  use BridgeServerWeb.ConnCase

  test "POST /api/eth-mint", %{conn: conn} do
    eth_mint_address = Application.get_env(:bridge_server, :eth_mint_address)
    tokenUri = Application.get_env(:bridge_server, :tokenUri)

    conn =
      post(conn, "/api/eth-mint", %{
        eth_mint_address: eth_mint_address,
        tokenUri: tokenUri
      })

    assert json_response(conn, 200)["data"]["eth_mint_address"] == eth_mint_address
  end

  test "POST /api/eth-transfer", %{conn: conn} do
    eth_from_address = Application.get_env(:bridge_server, :eth_mint_address)
    eth_custodial_address = Application.get_env(:bridge_server, :eth_custodial_address)

    conn =
      post(conn, "/api/eth-transfer", %{
        eth_from_address: eth_from_address,
        tokenId: 1
      })

    assert json_response(conn, 200)["data"]["eth_custodial_address"] == eth_custodial_address
  end
end
