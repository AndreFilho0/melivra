defmodule Shlinkedin.Repo.Migrations.AddPostTypeAndProfessorRelation do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      add :type, :string, null: false, default: "normal"  # Sempre terá um valor padrão
      add :professor_id, references(:professors, on_delete: :nilify_all)  # Pode ser NULL
    end
  end
end
