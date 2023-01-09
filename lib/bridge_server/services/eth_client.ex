defmodule EthClient do
  alias ETH.Transaction.Signer
  alias Ethereumex.HttpClient
  require Logger

  def getBalanceOf(address, eth_contract_address) do
    abi_encoded_data_balanceOf =
      ABI.encode("balanceOf(address)", [decode_address(address)])
      |> Base.encode16(case: :lower)

    {_ok, balance_bytes} =
      HttpClient.eth_call(%{
        data: "0x" <> abi_encoded_data_balanceOf,
        to: eth_contract_address
      })

    ExW3.Utils.hex_to_integer(balance_bytes)
  end

  def mint(eth_mint_address, tokenUri, eth_contract_address, eth_owner_address) do
    abi_encoded_data =
      ABI.encode("mint(address, string)", [
        decode_address(eth_mint_address),
        tokenUri
      ])
      |> Base.encode16(case: :lower)

    %{
      from: eth_owner_address,
      to: eth_contract_address,
      data: abi_encoded_data |> hex_prefix(),
      gas_limit: 300_000 |> Integer.to_string(16) |> hex_prefix(),
      gas_price: gas_price() |> Integer.to_string(16) |> hex_prefix(),
      value: "",
      nonce:
        hex_prefix(get_transaction_count!(eth_owner_address, "pending") |> Integer.to_string(16))
    }
    |> Signer.sign_transaction(get_secret())
    |> Hexate.encode()
    |> case do
      v ->
        HttpClient.eth_send_raw_transaction(hex_prefix(v))
    end
  end

  def transferFrom(from_address, to_address, tokenId, eth_contract_address) do
    abi_encoded_data =
      ABI.encode("transferFrom(address, address, uint256)", [
        decode_address(from_address),
        decode_address(to_address),
        tokenId
      ])
      |> Base.encode16(case: :lower)

    %{
      from: from_address,
      to: eth_contract_address,
      data: abi_encoded_data |> hex_prefix(),
      gas_limit: 300_000 |> Integer.to_string(16) |> hex_prefix(),
      gas_price: gas_price() |> Integer.to_string(16) |> hex_prefix(),
      value: "",
      nonce: hex_prefix(get_transaction_count!(from_address, "pending") |> Integer.to_string(16))
    }
    |> Signer.sign_transaction(get_secret())
    |> Hexate.encode()
    |> case do
      v ->
        HttpClient.eth_send_raw_transaction(hex_prefix(v))
    end
  end

  # TODO: the file location will not be available in prod. Move this to packageable location
  def decode_address(address) do
    address
    |> String.slice(2..-1)
    |> Base.decode16!(case: :mixed)
  end

  defp get_secret() do
    with {:ok, file} <- File.read("../Ethereum/secrets.json"),
         %{"privateKey" => key} <- Jason.decode!(file) do
      key
    end
  end

  defp hex_prefix(str), do: "0x#{str}"

  defp get_transaction_count!(eth_address, state) do
    {:ok, hex_transaction_count} = HttpClient.eth_get_transaction_count(eth_address, state)

    convert_to_number(hex_transaction_count)
  end

  def gas_price do
    case HttpClient.eth_gas_price() do
      {:ok, hex_gas_price} -> convert_to_number(hex_gas_price)
      error -> error
    end
  end

  defp convert_to_number(result) do
    result
    |> String.slice(2..-1)
    |> Hexate.to_integer()
  end
end
