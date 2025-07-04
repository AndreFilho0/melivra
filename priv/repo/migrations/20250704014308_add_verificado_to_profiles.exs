defmodule Shlinkedin.Repo.Migrations.AddVerificadoToProfiles do
  use Ecto.Migration

  def change do
    alter table(:profiles) do
      add :verificado, :boolean, default: false
    end
  end
end
