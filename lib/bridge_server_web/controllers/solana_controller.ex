defmodule BridgeServerWeb.SolanaController do
  use BridgeServerWeb, :controller
  require Logger
  alias BridgeServer.Metadata
  alias BridgeServer.Minter

  @devnet "https://api.devnet.solana.com"

  def index(conn, _params) do
    pda = Metadata.get_pda(Application.get_env(:bridge_server, :mint_address))
    Logger.info(inspect(pda))

    req = """
      {
        "jsonrpc": "2.0",
        "id": 1,
        "method": "getAccountInfo",
        "params": [
          "#{pda}",
          {"encoding": "base64"}
        ]
      }
    """

    with res <- HTTPoison.post(@devnet, req, [{"Content-Type", "application/json"}]),
         {:ok, %HTTPoison.Response{body: body}} <- res,
         {:ok, res} <- Jason.decode(body) do
      [head, _tail] = res["result"]["value"]["data"]
      raw = Base.decode64!(head)
      metadata = Metadata.parse(raw)
      Logger.info(metadata.update_authority)
      Logger.info(metadata.mint)
      Logger.info(metadata.data.name)
      Logger.info(metadata.data.symbol)
      Logger.info(metadata.data.uri)

      json(conn, %{
        data: %{
          collection_name: metadata.data.name,
          mint: metadata.mint,
          symbol: metadata.data.symbol,
          update_authority: metadata.update_authority,
          uri: metadata.data.uri
        }
      })
    else
      e -> raise e
    end

    # render(conn, "index.html")
  end

  def mint(conn, _params) do
    solana_wallet_file = Application.get_env(:bridge_server, :solana_payer_wallet_file)
    solana_payer_account = Application.get_env(:bridge_server, :solana_payer_account)
    Logger.info(solana_wallet_file)
    {:ok, payer} = Solana.Key.pair_from_file(solana_wallet_file)

    metadata = %{
      name: "Game - DevNet - Jack",
      symbol: "GMEM",
      uri: Application.get_env(:bridge_server, :tokenUri),
      seller_fee_basis_points: 0,
      creators: [
        address: B58.encode58(Solana.pubkey!(payer)),
        verified: 1,
        share: 100
      ]
    }

    case Minter.mint(payer, metadata) do
      signature ->
        Logger.info(Base.encode16(signature))

        json(conn, %{
          data: %{
            signature: Base.encode16(signature),
            mint_account: solana_payer_account
          }
        })
    end
  end
end
