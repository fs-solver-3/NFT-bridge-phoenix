defmodule BridgeServer.Repo.Migrations.Deposits do
  use Ecto.Migration

  def change do
    create table(:deposits) do
      add(:owner_address, :string)
      add(:receipt_address, :string)
      add(:mint_address, :string)
      add(:signatures, :string)
      add(:name, :string)
      add(:symbol, :string)
      add(:uri, :string)

      timestamps()
    end
  end
end
