defmodule SeuApp.Repo.Migrations.CreateProfessors do
  use Ecto.Migration

  def change do
    create table(:professors) do
      add :nome_professor, :string, size: 200, null: false
      add :instituto, :string, size: 100, null: false
      add :nota, :integer, null: false
      add :qts_avaliacao, :integer, null: false
      add :qts_n1, :integer, null: false
      add :qts_n2, :integer, null: false
      add :qts_n3, :integer, null: false
      add :qts_n4, :integer, null: false
      add :qts_n5, :integer, null: false
      add :qts_n6, :integer, null: false
      add :qts_n7, :integer, null: false
      add :qts_n8, :integer, null: false
      add :qts_n9, :integer, null: false
      add :qts_n10, :integer, null: false

      timestamps()
    end
  end
end
