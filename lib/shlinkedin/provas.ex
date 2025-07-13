defmodule Shlinkedin.Provas do
  import Ecto.Query
  alias Shlinkedin.Repo
  alias Shlinkedin.Provas.ProvaAntiga

  @semestre_regex ~r/^\d{4}\.(1|2|3|4)$/

  def create_prova_antiga(attrs \\ %{}) do
    changeset = ProvaAntiga.changeset(%ProvaAntiga{}, attrs)

    if changeset.valid? do
      Repo.insert(changeset)
    else
      {:validation_error, changeset}
    end
  end

  def change_prova_antiga(%ProvaAntiga{} = prova_antiga \\ %ProvaAntiga{}) do
    ProvaAntiga.changeset(prova_antiga, %{})
  end

  def get_prova_antiga(id) do
    case Repo.get(ProvaAntiga, id) do
      nil ->
        {:error, :not_found}

      prova ->
        prova = Repo.preload(prova, [:professor, :profile])

        {:ok, prova}
    end
  end

  def update_file_path(id, object_key) do
    case Repo.get(ProvaAntiga, id) do
      nil ->
        {:error, :not_found}

      %ProvaAntiga{} = prova ->
        prova
        |> ProvaAntiga.changeset(%{file_path: object_key, file_data: nil})
        |> Repo.update()

        {:ok, prova}
    end
  end

  def processar_prova_antiga(%ProvaAntiga{} = prova, bucket) do
    try do
      file_data = prova.file_data

      file_path =
        build_file_path(%{
          "professor_nome" => prova.professor.nome_professor,
          "instituto" => prova.professor.instituto,
          "semestre" => prova.semestre,
          "curso_dado" => prova.curso_dado,
          "materia" => prova.materia
        })

      object_key = file_path

      case upload_to_s3(bucket, object_key, file_data) do
        {:ok, _response} ->
          update_file_path(prova.id, object_key)
          {:ok, :uploaded}

        {:error, reason} ->
          # Se o upload falhou, retorne o erro
          {:error, reason}
      end
    rescue
      e ->
        {:error, e}
    end
  end

  defp upload_to_s3(bucket, object_key, file_data) do
    case ExAws.S3.put_object(bucket, object_key, file_data) |> ExAws.request() do
      {:ok, response} ->
        if response.status_code == 200 do
          {:ok, response}
        else
          {:error, "Upload failed with status: #{response.status_code}"}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

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

    "provas/#{instituto}/#{nome_formatado}_#{semestre}_#{curso_formatado}_#{materia_formatada}_#{uuid}.pdf"
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
