defmodule Shlinkedin.Professors.Professor do
  use Ecto.Schema
  import Ecto.Changeset

  schema "professors" do
    field :nome_professor, :string
    field :instituto, :string
    field :nota, :integer
    field :qts_avaliacao, :integer
    field :qts_n1, :integer
    field :qts_n2, :integer
    field :qts_n3, :integer
    field :qts_n4, :integer
    field :qts_n5, :integer
    field :qts_n6, :integer
    field :qts_n7, :integer
    field :qts_n8, :integer
    field :qts_n9, :integer
    field :qts_n10, :integer

    timestamps()
  end

  def changeset(professor, attrs) do
    professor
    |> cast(attrs, [
      :nome_professor, :instituto, :nota, :qts_avaliacao,
      :qts_n1, :qts_n2, :qts_n3, :qts_n4, :qts_n5,
      :qts_n6, :qts_n7, :qts_n8, :qts_n9, :qts_n10
    ])
    |> validate_required([:nome_professor, :instituto, :nota, :qts_avaliacao])
  end
end
