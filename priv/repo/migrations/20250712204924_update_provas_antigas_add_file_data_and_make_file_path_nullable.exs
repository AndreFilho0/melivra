defmodule Shlinkedin.Repo.Migrations.UpdateProvasAntigasAddFileDataAndMakeFilePathNullable do
  use Ecto.Migration

  def change do
    alter table(:provas_antigas) do
      modify :file_path, :string, null: true
      add :file_data, :binary
    end
  end
end
