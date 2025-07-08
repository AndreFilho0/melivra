defmodule Shlinkedin.Repo.Migrations.AddPostTypeAndProfessorRelation do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      # Sempre terá um valor padrão
      add :type, :string, null: false, default: "normal"
      # Pode ser NULL
      add :professor_id, references(:professors, on_delete: :nilify_all)
    end
  end
end
