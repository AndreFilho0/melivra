defmodule Shlinkedin.Repo.Migrations.AddPriceAndQuantityToAds do
  use Ecto.Migration

  def change do
    alter table(:ads) do
      add :quantity, :integer, default: 3
      add :price, :integer, default: 10000
    end
  end
end
