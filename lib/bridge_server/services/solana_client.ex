defmodule BridgeServer.SolanaClient do
  use GenServer, restart: :permanent
  require Logger
  alias BridgeServer.Deposit
  alias BridgeServer.Metadata
  @genserver_name :solana
  @devnet "https://api.devnet.solana.com"
  @solana_block "solana_block_height"

  @spec start_link(any) :: {:error, any} | {:ok, pid}

  def start_link(_) do
    Logger.info("start_link")
    GenServer.start_link(__MODULE__, :ok, name: @genserver_name)
  end

  def init(state) do
    Logger.info("init")

    case get_current_block() do
      # storage is empty
      {:ok, nil} ->
        update_block_height()

      {:ok, val} ->
        GenServer.cast(@genserver_name, {:inspect_next_block, String.to_integer(val)})
    end

    {:ok, state}
  end

  def handle_cast({:inspect_next_block, val}, state) do
    next_block = val + 1

    case process_block(next_block) do
      :ok ->
        {:ok, "OK"} = update_current_block(next_block)
        GenServer.cast(@genserver_name, {:inspect_next_block, next_block})

      :error ->
        receive do
        after
          1000 -> GenServer.cast(@genserver_name, {:inspect_next_block, next_block})
        end
    end

    {:noreply, state}
  end

  def process_block(block_height) do
    Logger.info("Get block #{block_height}")

    req = """
      {
        "jsonrpc": "2.0",
        "id":1,
        "method":"getBlock",
        "params":[#{block_height},
          {"encoding": "json","transactionDetails":"full","rewards":false}
        ]
      }
    """

    with res <- HTTPoison.post(@devnet, req, [{"Content-Type", "application/json"}]),
         {:ok, %HTTPoison.Response{body: body}} <- res,
         {:ok, res} <- Jason.decode(body) do
      case Map.has_key?(res, "result") do
        true ->
          handle_listen_transaction(res)

        false ->
          case Map.has_key?(res, "error") do
            true ->
              case res["error"]["code"] do
                -32007 -> :ok
                _ -> :error
              end
          end
      end
    else
      e ->
        Logger.error(inspect(e))
        :error
    end
  end

  def handle_listen_transaction(response) do
    response["result"]["transactions"]
    |> Enum.filter(fn item ->
      item["transaction"]["message"]["accountKeys"]
      |> Enum.any?(fn account ->
        account == Application.get_env(:bridge_server, :sol_custodial_address)
      end)
    end)
    |> case do
      [] ->
        Logger.info("No transactions found")

      list ->
        Logger.info("Incoming transaction detected")
        Logger.info(list)

        transaction = get_first_item(is_list(list), list)
        process_transaction(transaction)
    end
  end

  def update_block_height() do
    Logger.info("Update_block_height")

    req = """
      {"jsonrpc":"2.0","id":1, "method":"getBlockHeight"}
    """

    with res <- HTTPoison.post(@devnet, req, [{"Content-Type", "application/json"}]),
         {:ok, %HTTPoison.Response{body: body}} <- res,
         {:ok, %{"result" => block_height}} <- Jason.decode(body) do
      Logger.info("Set height #{block_height}")
      {:ok, "OK"} = update_current_block(block_height)
      :ok
    else
      e -> raise e
    end
  end

  def get_signature(transaction) do
    signatures = transaction["transaction"]["signatures"]
    get_first_item(is_list(signatures), signatures)
  end

  def get_receiverTokenInfo(transaction) do
    transaction["meta"]["postTokenBalances"]
    |> Enum.filter(fn item ->
      item["accountIndex"] == 1
    end)
    |> case do
      list ->
        get_first_item(is_list(list), list)
    end
  end

  def get_ownerTokenInfo(transaction) do
    transaction["meta"]["postTokenBalances"]
    |> Enum.filter(fn item ->
      item["accountIndex"] == 2
    end)
    |> case do
      list ->
        get_first_item(is_list(list), list)
    end
  end

  def get_metadata(mintAddress) do
    pda = Metadata.get_pda(mintAddress)
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
      Metadata.parse(raw)
    else
      e ->
        Logger.error(inspect(e))
        :error
    end
  end

  def process_transaction(transaction) do
    valid_attrs = %{
      owner_address: "",
      receipt_address: "",
      mint_address: "",
      signatures: "",
      name: "",
      symbol: "",
      uri: ""
    }

    valid_attrs = Map.put(valid_attrs, :signatures, get_signature(transaction))

    ownerTokenInfo = get_ownerTokenInfo(transaction)
    valid_attrs = Map.put(valid_attrs, :owner_address, ownerTokenInfo["owner"])

    receiverTokenInfo = get_receiverTokenInfo(transaction)
    valid_attrs = Map.put(valid_attrs, :mint_address, receiverTokenInfo["mint"])
    valid_attrs = Map.put(valid_attrs, :receipt_address, receiverTokenInfo["owner"])

    tokenMetadata = get_metadata(receiverTokenInfo["mint"])
    valid_attrs = Map.put(valid_attrs, :name, tokenMetadata.data.name)
    valid_attrs = Map.put(valid_attrs, :uri, tokenMetadata.data.uri)

    valid_attrs = Map.put(valid_attrs, :symbol, tokenMetadata.data.symbol)

    Logger.info(valid_attrs)

    case Deposit.create(valid_attrs) do
      {:ok, _} ->
        Logger.info("Insert the Deposit Data")

      e ->
        Logger.error(inspect(e))
        :error
    end
  end

  defp get_current_block(), do: Redix.command(:redix, ["GET", @solana_block])
  defp update_current_block(val), do: Redix.command(:redix, ["SET", @solana_block, val])
  defp get_first_item(true, items), do: items |> List.first()
  defp get_first_item(false, _items), do: ""
end
