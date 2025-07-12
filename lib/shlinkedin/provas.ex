defmodule Shlinkedin.Provas do
  import Ecto.Query
  alias Shlinkedin.Repo
  alias Shlinkedin.Provas.ProvaAntiga

  @semestre_regex ~r/^\d{4}\.(1|2|3|4)$/

  def list_provas_filtradas(params) do
    with :ok <- validate_params(params) do
      dynamic_filters = build_filters(params)

      query =
        from p in ProvaAntiga,
          where: ^dynamic_filters,
          order_by: [desc: p.inserted_at]

      Repo.all(query)
    end
  end

  defp build_filters(params) do
    # Começa com a condição obrigatória do professor_id
    dynamic =
      dynamic([p], p.professor_id == ^params["professor_id"])

    dynamic =
      if semestre = params["semestre"] do
        dynamic([p], ^dynamic and p.semestre == ^semestre)
      else
        dynamic
      end

    dynamic =
      if curso = params["curso_dado"] do
        curso = String.downcase(curso)
        dynamic([p], ^dynamic and p.curso_dado == ^curso)
      else
        dynamic
      end

    dynamic =
      if materia = params["materia"] do
        materia = String.downcase(materia)
        dynamic([p], ^dynamic and p.materia == ^materia)
      else
        dynamic
      end

    dynamic =
      if data_inicio = params["data_inicio"] do
        dynamic([p], ^dynamic and p.inserted_at >= ^data_inicio)
      else
        dynamic
      end

    dynamic =
      if data_fim = params["data_fim"] do
        dynamic([p], ^dynamic and p.inserted_at <= ^data_fim)
      else
        dynamic
      end

    dynamic
  end

  def build_file_path(%{
        "professor_nome" => nome,
        "instituto" => instituto,
        "semestre" => semestre,
        "curso_dado" => curso,
        "materia" => materia
      }) do
    nome_formatado = nome |> String.downcase() |> String.replace(~r/\s+/, "_")
    curso_formatado = curso |> String.downcase() |> String.replace(~r/\s+/, "_")
    materia_formatada = materia |> String.downcase() |> String.replace(~r/\s+/, "_")
    uuid = Ecto.UUID.generate()

    "/provas/#{instituto}/#{nome_formatado}_#{semestre}_#{curso_formatado}_#{materia_formatada}_#{uuid}.pdf"
  end

  defp validate_params(%{"professor_id" => id} = params)
       when is_integer(id) or is_binary(id) do
    cond do
      Map.has_key?(params, "semestre") and
          not Regex.match?(@semestre_regex, params["semestre"]) ->
        {:error, "Semestre inválido. Use o formato 2024.1 até 2024.4"}

      true ->
        :ok
    end
  end

  defp validate_params(_), do: {:error, "Parâmetro professor_id obrigatório"}
end
