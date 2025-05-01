defmodule Shlinkedin.Professors do
  import Ecto.Query, warn: false
  alias Shlinkedin.Repo
  alias Shlinkedin.Professors.Professor
  alias Shlinkedin.Profiles.Profile
  alias Shlinkedin.Timeline.{Post, Comment, Like, CommentLike, Story, StoryView, SocialPrompt}

  @bucket "melivra"
  @expiration_time 300

  def search_professors(name, instituto) do
    from(p in Professor,
      where: p.nome_professor == ^name and p.instituto == ^instituto
    )
    |> Repo.one()
  end

  def search_professors_instituto(instituto) do
    from(p in Professor,
      where: p.instituto == ^instituto,
      select: p.nome_professor,
      order_by: [asc: p.nome_professor]
    )
    |> Repo.all()
  end

  def create_post(
        %Profile{} = profile,
        %Professor{id: professor_id} = _professor,
        attrs \\ %{},
        post \\ %Post{},
        after_save \\ &{:ok, &1}
      ) do
    post = %{post | profile_id: profile.id, professor_id: professor_id, type: "sobre_professor"}

    post =
      post
      |> Post.changeset(attrs)
      |> Repo.insert!()
      |> Repo.preload([:profile, :likes, comments: [:profile, :likes]])

    broadcast({:ok, post}, :post_created)
  end

  defp broadcast({:error, _reason} = error, _), do: error

  defp broadcast({:ok, post}, event) do
    Phoenix.PubSub.broadcast(Shlinkedin.PubSub, "posts", {event, post})
    {:ok, post}
  end

  def update_professor_rating(name, instituto, nota) do
    professor =
      from(p in Professor,
        where: p.nome_professor == ^name and p.instituto == ^instituto,
        select: p
      )
      |> Repo.one()

    if professor do
      nova_nota = String.to_integer(nota)

      nova_soma_notas = professor.nota + nova_nota
      nova_qts_avaliacao = professor.qts_avaliacao + 1

      updated_professor =
        case nova_nota do
          1 -> %{professor | qts_n1: professor.qts_n1 + 1}
          2 -> %{professor | qts_n2: professor.qts_n2 + 1}
          3 -> %{professor | qts_n3: professor.qts_n3 + 1}
          4 -> %{professor | qts_n4: professor.qts_n4 + 1}
          5 -> %{professor | qts_n5: professor.qts_n5 + 1}
          6 -> %{professor | qts_n6: professor.qts_n6 + 1}
          7 -> %{professor | qts_n7: professor.qts_n7 + 1}
          8 -> %{professor | qts_n8: professor.qts_n8 + 1}
          9 -> %{professor | qts_n9: professor.qts_n9 + 1}
          10 -> %{professor | qts_n10: professor.qts_n10 + 1}
          _ -> professor
        end

      changeset =
        professor
        |> Professor.changeset(%{
          nota: nova_soma_notas,
          qts_avaliacao: nova_qts_avaliacao,
          qts_n1: updated_professor.qts_n1,
          qts_n2: updated_professor.qts_n2,
          qts_n3: updated_professor.qts_n3,
          qts_n4: updated_professor.qts_n4,
          qts_n5: updated_professor.qts_n5,
          qts_n6: updated_professor.qts_n6,
          qts_n7: updated_professor.qts_n7,
          qts_n8: updated_professor.qts_n8,
          qts_n9: updated_professor.qts_n9,
          qts_n10: updated_professor.qts_n10
        })

      case Repo.update(changeset) do
        {:ok, updated_professor} ->
          {:ok, updated_professor}

        {:error, changeset} ->
          {:error, changeset}
      end
    else
      {:error, "Professor não encontrado"}
    end
  end

  def get_temporary_urls(institute, professor_name) do
    directory = "turmas/#{institute}/"

    # Busca todos os arquivos no diretório
    {:ok, %{body: %{contents: contents}}} =
      ExAws.S3.list_objects(@bucket, prefix: directory)
      |> ExAws.request()

    # Filtra os arquivos pelo nome do professor
    matched_files =
      contents
      |> Enum.map(& &1.key)
      |> Enum.filter(&String.contains?(&1, professor_name))

    # Gera URLs temporárias
    Enum.map(matched_files, fn file_key ->
      generate_presigned_url(file_key)
    end)
  end

  def upload_image(institute, file_path, file_content) do
    directory = "turmas/#{institute}/"

    object_key = directory <> Path.basename(file_path)


    ExAws.S3.put_object(@bucket, object_key, file_content)
    |> ExAws.request()
  end

  defp generate_presigned_url(file_key) do
    ExAws.S3.presigned_url(
      # Configuração correta
      ExAws.Config.new(:s3),
      :get,
      @bucket,
      file_key,
      expires_in: @expiration_time,
      query_params: [{"response-content-disposition", "attachment"}]
    )
  end
end
