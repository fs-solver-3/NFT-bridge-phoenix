defmodule BridgeServerWeb.SolanaControllerTest do
  use BridgeServerWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Welcome to Phoenix!"
  end

  test "GET /solana", %{conn: conn} do
    conn = get(conn, "/solana")

    assert json_response(conn, 200) == %{
             "data" => %{
               "collection_name" => "Game - DevNet",
               "mint" => "8RJLmkArbX1SaU2NqKzAbLtSXjJypTLoKbiGMb461VhE",
               "symbol" => "GME",
               "update_authority" => "FzVaYRJbM65LVVLxrxv5L8pjKm6o1qAzU1L2XLxKkeqH",
               "uri" => "https://arweave.net/B4T7noSr8mhPCekdMKWQI2haqnHrjsdJOwWG8I7fVbw"
             }
           }
  end

  test "GET /solana-mint", %{conn: conn} do
    conn = get(conn, "/solana-mint")
    solana_payer_account = Application.get_env(:bridge_server, :solana_payer_account)

    assert json_response(conn, 200)["data"]["mint_account"] == solana_payer_account
  end
end
