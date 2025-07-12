defmodule Shlinkedin.Repo.Migrations.CreateProvasAntigas do
  use Ecto.Migration

  def change do
    create table(:provas_antigas) do
      add :semestre, :string, null: false
      add :curso_dado, :string, null: false
      add :materia, :string, null: false
      add :file_path, :string, null: false
      add :professor_id, references(:professors, on_delete: :nothing), null: false
      add :profile_id, references(:profiles, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:provas_antigas, [:professor_id])
    create index(:provas_antigas, [:profile_id])
  end
end
