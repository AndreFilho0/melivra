defmodule Shlinkedin.Repo.Migrations.AddNumeroProvaProvasAntigas do
  use Ecto.Migration

  def change do
    alter table(:provas_antigas) do
      add :numero_prova, :string, null: true
    end
  end
end
