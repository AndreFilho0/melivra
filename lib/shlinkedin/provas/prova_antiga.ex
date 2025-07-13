defmodule Shlinkedin.Provas.ProvaAntiga do
  use Ecto.Schema
  import Ecto.Changeset

  schema "provas_antigas" do
    belongs_to :professor, Shlinkedin.Professors.Professor
    belongs_to :profile, Shlinkedin.Profiles.Profile

    field :semestre, :string
    field :curso_dado, :string
    field :materia, :string
    field :file_path, :string
    field :file_data, :binary

    timestamps()
  end

  @doc false

  def changeset(prova_antiga, attrs) do
    prova_antiga
    |> cast(attrs, [
      :professor_id,
      :profile_id,
      :semestre,
      :curso_dado,
      :materia,
      :file_path,
      :file_data
    ])
    |> validate_required([
      :professor_id,
      :profile_id,
      :semestre,
      :curso_dado,
      :materia
    ])
    |> validate_format(:semestre, ~r/^\d{4}\.(1|2|3|4)$/,
      message: "formato deve ser ano.período (ex: 2024.1 ou 2020.2)"
    )
    |> update_change(:curso_dado, &String.downcase/1)
    |> update_change(:materia, &String.downcase/1)
    |> foreign_key_constraint(:professor_id)
    |> foreign_key_constraint(:profile_id)
  end
end
