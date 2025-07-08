defmodule SeuApp.Repo.Migrations.CreateComentarios do
  use Ecto.Migration

  def change do
    create table(:comentarios) do
      add :comentario, :text, null: false
      add :nome_professor, :string, size: 200, null: false
      add :inst_professor, :string, size: 200, null: false
      add :publicavel, :boolean, default: true, null: false

      # Chave estrangeira para users (criadoBY)
      add :criado_by, references(:users, type: :bigint, on_delete: :delete_all), null: false

      # Chave estrangeira para professors
      add :professor_id, references(:professors, type: :bigint, on_delete: :delete_all),
        null: false

      timestamps()
    end
  end
end
