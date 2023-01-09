defmodule BridgeServer.Deposit do
  use Ecto.Schema
  import Ecto.Changeset
  alias BridgeServer.Repo
  alias BridgeServer.Deposit

  schema "deposits" do
    field(:owner_address, :string)
    field(:receipt_address, :string)
    field(:mint_address, :string)
    field(:signatures, :string)
    field(:name, :string)
    field(:symbol, :string)
    field(:uri, :string)

    timestamps()
  end

  def changeset(deposit, attrs \\ %{}) do
    deposit
    |> cast(attrs, [
      :owner_address,
      :receipt_address,
      :mint_address,
      :signatures,
      :name,
      :symbol,
      :uri
    ])
    |> validate_required([
      :owner_address,
      :receipt_address,
      :mint_address,
      :signatures,
      :name,
      :symbol,
      :uri
    ])
  end

  def create(attrs) do
    %Deposit{}
    |> Deposit.changeset(attrs)
    |> Repo.insert()
  end

  # def find_by_token(token_id) do
  #   case Repo.get_by(Deposit, token_id: token_id) do
  #     nil -> :error
  #     val -> val
  #   end
  # end

  # def update_to_next_state(deposit) do
  #   deposit
  #   |> changeset()
  #   |> put_change(:status, deposit.status |> next_step())
  #   |> Repo.insert!()
  # end

  # defp next_step(:init), do: :deposited
  # defp next_step(:deposited), do: :bridged
end
