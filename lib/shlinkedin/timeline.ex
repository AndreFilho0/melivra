defmodule Shlinkedin.Timeline do
  @moduledoc """
  The Timeline context.
  """
  import Ecto.Query, warn: false
  alias Shlinkedin.Repo

  alias Shlinkedin.Timeline.{Post, Comment, Like, CommentLike, Story, StoryView, SocialPrompt}
  alias Shlinkedin.Profiles.Profile
  alias Shlinkedin.Professors.Professor
  alias Shlinkedin.Profiles.ProfileNotifier
  alias Shlinkedin.Groups.Group
  alias Shlinkedin.Helpers

  @doc """
  Gets post if user is allowed to edit it.
  """
  def get_allowed_change_post(%Profile{} = profile, post_id) do
    post = get_post!(post_id)
    if profile_allowed_to_delete_post?(profile, post), do: {:ok, post}
  end

  @doc """
  Gets comment if user is allowed to edit it.
  """
  def get_allowed_change_comment(%Profile{} = profile, comment_id) do
    comment = get_comment!(comment_id)
    if profile_allowed_to_delete_comment?(profile, comment), do: {:ok, comment}
  end

  def profile_allowed_to_edit_post?(nil, %Post{}), do: false

  def profile_allowed_to_edit_post?(%Profile{} = profile, %Post{} = post) do
    post.profile_id == profile.id or profile.admin
  end

  def profile_allowed_to_delete_post?(nil, %Post{}), do: false

  def profile_allowed_to_delete_post?(%Profile{} = profile, %Post{} = post) do
    post.profile_id == profile.id or profile.admin
  end

  def profile_allowed_to_delete_comment?(nil, %Comment{}), do: false

  def profile_allowed_to_delete_comment?(%Profile{} = profile, %Comment{} = comment) do
    comment.profile_id == profile.id or profile.admin
  end

  def create_story(%Profile{} = profile, %Story{} = story, attrs \\ %{}, after_save \\ &{:ok, &1}) do
    story = %{story | profile_id: profile.id}

    story
    |> Story.changeset(attrs)
    |> Repo.insert()
    |> after_save(after_save)
  end

  def delete_story(%Story{} = story) do
    Repo.delete(story)
  end

  def change_story(%Story{} = story, attrs \\ %{}) do
    Story.changeset(story, attrs)
  end

  def list_stories() do
    now = NaiveDateTime.utc_now()

    Repo.all(
      from(s in Story,
        where: s.inserted_at >= datetime_add(^now, -1, "day"),
        preload: [:profile],
        distinct: s.profile_id,
        order_by: [desc: s.inserted_at]
      )
    )
  end

  def seen_all_stories?(%Profile{} = watcher, %Profile{} = storyteller) do
    stories = list_stories_given_profile(storyteller)
    watched = list_story_views_for_profile(watcher)

    stories -- watched == []
  end

  def list_stories_given_profile(%Profile{} = profile) do
    now = NaiveDateTime.utc_now()

    Repo.all(
      from(s in Story,
        where: s.profile_id == ^profile.id,
        select: s.id,
        where: s.inserted_at >= datetime_add(^now, -1, "day")
      )
    )
  end

  def list_story_views_for_profile(%Profile{} = profile) do
    Repo.all(
      from(v in StoryView,
        where: v.from_profile_id == ^profile.id,
        select: v.story_id
      )
    )
  end

  def get_story!(id) do
    now = NaiveDateTime.utc_now()

    Repo.one(
      from(s in Story,
        where: s.inserted_at >= datetime_add(^now, -1, "day") and s.id == ^id,
        preload: :profile
      )
    )
  end

  def get_next_story(profile_id, story_id) do
    now = NaiveDateTime.utc_now()

    Repo.one(
      from(s in Story,
        where:
          s.inserted_at >= datetime_add(^now, -1, "day") and s.profile_id == ^profile_id and
            s.id > ^story_id,
        order_by: [asc: s.id],
        limit: 1,
        select: s.id
      )
    )
  end

  def get_prev_story(profile_id, story_id) do
    now = NaiveDateTime.utc_now()

    Repo.one(
      from(s in Story,
        where:
          s.inserted_at >= datetime_add(^now, -1, "day") and s.profile_id == ^profile_id and
            s.id < ^story_id,
        order_by: [asc: s.id],
        limit: 1,
        select: s.id
      )
    )
  end

  def get_profile_story(profile_id) do
    now = NaiveDateTime.utc_now()

    Repo.one(
      from(s in Story,
        where: s.inserted_at >= datetime_add(^now, -1, "day") and s.profile_id == ^profile_id,
        order_by: [asc: s.id],
        preload: :profile,
        limit: 1
      )
    )
  end

  def get_story_ids(profile_id) do
    now = NaiveDateTime.utc_now()

    Repo.all(
      from(s in Story,
        where: s.inserted_at >= datetime_add(^now, -1, "day") and s.profile_id == ^profile_id,
        select: s.id
      )
    )
  end

  def create_story_view(%Story{} = story, %Profile{} = watcher, attrs \\ %{}) do
    %StoryView{story_id: story.id, from_profile_id: watcher.id}
    |> StoryView.changeset(attrs)
    |> Repo.insert()
  end

  def list_story_views(%Story{} = story) do
    Repo.all(
      from(v in StoryView,
        where: v.story_id == ^story.id,
        distinct: v.from_profile_id,
        preload: :profile
      )
    )
  end

  def list_unique_notifications(count) do
    Repo.all(
      from(n in Shlinkedin.Profiles.Notification,
        limit: ^count,
        preload: [:profile],
        order_by: [desc: n.inserted_at],
        distinct: true,
        where: n.type != "new_profile" and n.type != "admin_message"
      )
    )
    |> Enum.uniq_by(fn x -> x.action end)
  end

  def num_posts(%Profile{id: nil}), do: 0

  def num_posts(%Profile{} = profile) do
    Repo.aggregate(from(p in Post, where: p.profile_id == ^profile.id), :count)
  end

  # List posts when account is first created and profile is nil
  def list_posts(%Profile{id: nil}, criteria, _feed_options) do
    query =
      from(p in Post,
      where: p.type == "normal",
        order_by: [desc: p.pinned, desc: p.inserted_at]
      )
      |> viewable_posts_query()

    paged_query = paginate(query, criteria)

    from(p in paged_query,
      preload: [:profile, :likes, comments: [:profile, :likes]]
    )
    |> Repo.all()
  end

  def list_posts(object, criteria, feed_object) when is_list(criteria) do
    query = get_feed_query(object, feed_object) |> viewable_posts_query()

    IO.inspect(query)
    paged_query = paginate(query, criteria)

    IO.inspect(paged_query)
    from(p in paged_query,
      preload: [:profile, :likes, comments: [:profile, :likes]]
    )
    |> Repo.all()
    |> parse_results(feed_object)
  end

  defp viewable_posts_query(query) do
    from p in query, where: p.removed == false
  end

  defp parse_results(posts, %{type: "reactions"}) do
    Enum.map(posts, fn {_likes, post} -> post end)
  end

  defp parse_results(posts, _), do: posts

  def get_feed_query(object, %{type: type, time: time}) do
    time_in_seconds = Helpers.parse_time(time)
    IO.inspect(object)
    case type do
      "new" ->
        from(p in Post,
        where: p.type == "normal",
          order_by: [desc: p.pinned, desc: p.id]
        )

      "featured" ->
        from(p in Post,
          where: not is_nil(p.featured_date),
          order_by: [desc: p.pinned, desc: p.inserted_at]
        )

      "reactions" ->
        time =
          NaiveDateTime.utc_now()
          |> NaiveDateTime.add(time_in_seconds, :second)

        from(p in Post,
          where: p.inserted_at >= ^time and p.type == "normal",
          left_join: l in assoc(p, :likes),
          group_by: p.id,
          order_by: [desc: p.pinned],
          order_by: fragment("count DESC"),
          order_by: [desc: p.id],
          select: {count(l.profile_id, :distinct), p}
        )

      "group" ->
        %Group{id: id} = object
        from(p in Post, where: p.group_id == ^id, order_by: [desc: p.inserted_at])

      "profile" ->
        %Profile{id: id} = object

        from(p in Post,
          order_by: [desc: p.pinned, desc: p.id],
          where: p.profile_id == ^id and p.type == "normal"
        )
      "professor" ->

        %Shlinkedin.Professors.Professor{id: id} = object



        from(p in Post,
          order_by: [desc: p.pinned, desc: p.id],
          where: p.professor_id == ^id and p.type =="sobre_professor"
        )

    end
  end

  defp paginate(query, criteria) do
    Enum.reduce(criteria, query, fn {:paginate, %{page: page, per_page: per_page}}, query ->
      from(q in query, offset: ^((page - 1) * per_page), limit: ^per_page)
    end)
  end

  @doc """
  Gets a single post.

  Raises `Ecto.NoResultsError` if the Post does not exist.

  ## Examples

      iex> get_post!(123)
      %Post{}

      iex> get_post!(456)
      ** (Ecto.NoResultsError)

  """
  def get_post!(id), do: Repo.get!(Post, id)

  def get_post_preload_profile(id) do
    from(p in Post,
      where: p.id == ^id,
      select: p,
      preload: [:profile]
    )
    |> Repo.one()
  end

  def get_post_count(%Profile{} = profile, start_date) do
    Repo.one(
      from(p in Post,
        where: p.profile_id == ^profile.id and p.inserted_at >= ^start_date,
        select: count(p.id)
      )
    )
  end

  def get_post_preload_all(id) do
    Repo.one(
      from(p in Post,
        where: p.id == ^id,
        left_join: profile in assoc(p, :profile),
        left_join: comments in assoc(p, :comments),
        left_join: profs in assoc(comments, :profile),
        left_join: likes in assoc(comments, :likes),
        preload: [:profile, :likes, comments: {comments, profile: profs, likes: likes}]
      )
    )
  end

  def get_comment!(id), do: Repo.get!(Comment, id)

  @doc """
  Creates a post.

  ## Examples

      iex> create_post(%{field: value})
      {:ok, %Post{}}

      iex> create_post(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_post(
        %Profile{} = profile,
        attrs \\ %{},
        post \\ %Post{},
        after_save \\ &{:ok, &1}
      ) do
    post = %{post | profile_id: profile.id}

    post =
      post
      |> Post.changeset(attrs)
      |> Repo.insert!()
      |> after_save(after_save)
      |> Repo.preload([:profile, :likes, comments: [:profile, :likes]])

    broadcast({:ok, post}, :post_created)
  end

  def get_gif_from_text(text) do
    text = String.replace(text, ~r/\s+/, "_") |> String.slice(0..5)

    api =
      "https://api.giphy.com/v1/gifs/translate?api_key=#{System.get_env("GIPHY_API_KEY")}&s=#{text}&weirdness=10"

    gif_response = HTTPoison.get!(api)

    Jason.decode!(gif_response.body)["data"]["images"]["fixed_width_downsampled"]["webp"]
  end

  defp after_save({:ok, post}, func) do
    {:ok, _post} = func.(post)
  end

  defp after_save(error, _func), do: error

  def create_comment(%Profile{} = profile, %Post{id: post_id}, attrs \\ %{}) do
    new_comment =
      %Comment{post_id: post_id, profile_id: profile.id}
      |> Comment.changeset(attrs)
      |> Repo.insert()

    case new_comment do
      {:ok, _} ->
        # could be optimized
        post = get_post_preload_all(post_id)

        # notify person
        ProfileNotifier.observer(new_comment, :comment, profile, post.profile)

        broadcast(
          {:ok, post},
          :post_updated
        )

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def create_like(%Profile{} = profile, %Post{} = post, like_type) do
    {:ok, _like} =
      %Like{}
      |> Like.changeset(%{profile_id: profile.id, post_id: post.id, like_type: like_type})
      |> Repo.insert()
      |> ProfileNotifier.observer(:like, profile, post.profile)

    # could be optimized
    post = get_post_preload_all(post.id)

    broadcast({:ok, post}, :post_updated)
  end

  def create_comment_like(%Profile{} = profile, %Comment{} = comment, like_type) do
    {:ok, _comment} =
      %CommentLike{
        profile_id: profile.id,
        comment_id: comment.id,
        like_type: like_type
      }
      |> Repo.insert()
      |> ProfileNotifier.observer(:comment_like, profile, comment.profile)

    # could be optimized
    post = get_post_preload_all(comment.post_id)

    broadcast({:ok, post}, :post_updated)
  end

  @doc """
  Tells us whether profile has liked that post
  before. This is important for notifications,
  because we only want to create a notification if
  that person hasn't reacted to the post before.
  """
  def is_first_like_on_post?(%Profile{} = profile, %Post{} = post) do
    Repo.one(
      from(l in Like,
        where: l.post_id == ^post.id and l.profile_id == ^profile.id,
        select: count(l.profile_id)
      )
    ) == 1
  end

  def is_first_like_on_comment?(%Profile{} = profile, %Comment{} = comment) do
    Repo.one(
      from(l in CommentLike,
        where: l.comment_id == ^comment.id and l.profile_id == ^profile.id,
        select: count(l.profile_id)
      )
    ) == 1
  end

  @doc """

  Returns:

  [
    %{count: 12, likes: "Pity", name: "DUbncan"},
    %{count: 1, likes: "Pity", name: "charless"},
    %{count: 5, likes: "Um...", name: "charless"},
    %{count: 1, likes: "Zoop", name: "charless"}
  ]
  """
  def list_likes(%Post{} = post) do
    Repo.all(
      from(l in Like,
        join: p in assoc(l, :profile),
        where: l.post_id == ^post.id,
        group_by: [p.persona_name, p.photo_url, p.slug, l.like_type],
        select: %{
          name: p.persona_name,
          photo_url: p.photo_url,
          like_type: l.like_type,
          like_type: l.like_type,
          count: count(l.like_type),
          slug: p.slug
        },
        order_by: p.persona_name
      )
    )
  end

  def list_comment_likes(%Comment{} = comment) do
    Repo.all(
      from(l in CommentLike,
        join: p in assoc(l, :profile),
        where: l.comment_id == ^comment.id,
        group_by: [p.persona_name, p.photo_url, p.slug, l.like_type],
        select: %{
          name: p.persona_name,
          photo_url: p.photo_url,
          like_type: l.like_type,
          like_type: l.like_type,
          count: count(l.like_type),
          slug: p.slug
        },
        order_by: p.persona_name
      )
    )
  end

  @doc """
  Updates a post.

  ## Examples

      iex> update_post(post, %{field: new_value})
      {:ok, %Post{}}

      iex> update_post(post, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_post(%Profile{} = profile, %Post{} = post, attrs, after_save \\ &{:ok, &1}) do
    post
    |> Post.changeset(attrs)
    |> Post.validate_allowed(post, profile)
    |> after_save(after_save)
    |> Repo.update()
  end

  @doc """
  Only used in Moderation to uncensor a post.
  """
  def censor_post(%Post{} = post) do
    post
    |> Post.changeset(%{removed: true})
    |> Repo.update()
  end

  def uncensor_post(%Post{} = post) do
    post
    |> Post.changeset(%{removed: false})
    |> Repo.update()
  end

  def censor_comment(%Comment{} = comment) do
    comment
    |> Comment.changeset(%{removed: true})
    |> Repo.update()
  end

  def uncensor_comment(%Comment{} = comment) do
    comment
    |> Comment.changeset(%{removed: false})
    |> Repo.update()
  end

  @doc """
  Deletes a post.

  ## Examples

      iex> delete_post(post)
      {:ok, %Post{}}

      iex> delete_post(post)
      {:error, %Ecto.Changeset{}}

  """
  def delete_post(%Post{} = post) do
    Repo.delete(post)
    |> broadcast(:post_deleted)
  end

  def delete_comment(%Comment{} = comment) do
    Repo.delete(comment)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking post changes.

  ## Examples

      iex> change_post(post)
      %Ecto.Changeset{data: %Post{}}

  """
  def change_post(%Post{} = post, attrs \\ %{}) do
    Post.changeset(post, attrs)
  end

  def change_comment(%Comment{} = comment, attrs \\ %{}) do
    Comment.changeset(comment, attrs)
  end

  def subscribe do
    Phoenix.PubSub.subscribe(Shlinkedin.PubSub, "posts")
  end

  defp broadcast({:error, _reason} = error, _), do: error

  defp broadcast({:ok, post}, event) do
    Phoenix.PubSub.broadcast(Shlinkedin.PubSub, "posts", {event, post})
    {:ok, post}
  end

  def sponsor do
    [
      "Jamba juice is BETTER than my marriage!",
      "With Jamba Juice, you can harness the power of fruits. #JamOutWithJamba",
      "Uh-oh, it’s #JambaTime! Put down that water and buy a juice!",
      "I love #JambaJuice. Their fresh ingredients and inventive flavor blends are a gateway to lasting happiness! Try the new Manic Mango Mud Slide!",
      "I lost my virginity at Jamba Juice! #JamOutWithJamba #JambaTime #SexualEncounter",
      "Drink Jamba Juice and experience true vigor.",
      "Tired of your job? Quit, and drink Jamba juice."
    ]
    |> Enum.random()
  end

  def like_map do
    %{
      "🌶️" => %{
        active: true,
        like_type: " 🌶️",
        is_emoji: true,
        emoji: "🌶️",
        color: "text-red-500",
        bg: "bg-red-600"
      },
      "🏆" => %{
        active: true,
        like_type: "🏆",
        is_emoji: true,
        emoji: "🏆",
        color: "text-yellow-500",
        bg: "bg-yellow-600"
      },
      "Cafézinho" => %{
        active: true,
        like_type: "Cafézinho ☕",
        is_emoji: true,
        emoji: "☕",
        color: "text-brown-500",
        bg: "bg-brown-600"
      },
      "Me Livra" => %{
        active: true,
        like_type: "Me Livra 🙏",
        is_emoji: true,
        emoji: "🙏",
        color: "text-green-500",
        bg: "bg-green-600"
      },
      "Topzera" => %{
        active: true,
        like_type: "Topzera 👏",
        is_emoji: true,
        emoji: "👏",
        color: "text-indigo-500",
        bg: "bg-indigo-600"
      },
      "" => %{
        active: true,
        like_type: "📈",
        is_emoji: true,
        emoji: "📈",
        color: "text-green-500",
        bg: "bg-green-600"
      },
      "Risada" => %{
        active: true,
        like_type: " 😂",
        is_emoji: true,
        emoji: "😂",
        color: "text-orange-500",
        bg: "bg-orange-600"
      },
      "Shiii" => %{
        active: true,
        like_type: "Shiii 🤫",
        is_emoji: true,
        emoji: "🤫",
        color: "text-gray-500",
        bg: "bg-gray-600"
      },
      "Hmm..." => %{
        active: true,
        like_type: "Hmm... 🤔",
        is_emoji: true,
        emoji: "🤔",
        color: "text-gray-500",
        bg: "bg-gray-600"
      },
      "Faz o L" => %{
        active: true,
        like_type: "Faz o L",
        is_emoji: true,
        emoji: "🖖",
        color: "text-green-500",
        bg: "bg-green-600"
      }
    }
  end

  def comment_like_map do
    %{
      "Zap" => %{
        is_emoji: false,
        like_type: "Zap",
        bg: "bg-yellow-500",
        color: "text-yellow-500",
        bg_hover: "bg-yellow-600",
        fill: "",
        svg_path:
          "M11.3 1.046A1 1 0 0112 2v5h4a1 1 0 01.82 1.573l-7 10A1 1 0 018 18v-5H4a1 1 0 01-.82-1.573l7-10a1 1 0 011.12-.38z"
      },
      "Slap" => %{
        is_emoji: false,
        like_type: "Slap",
        bg: "bg-indigo-500",
        color: "text-indigo-500",
        bg_hover: "bg-indigo-600",
        fill: "even-odd",
        svg_path:
          "M9 3a1 1 0 012 0v5.5a.5.5 0 001 0V4a1 1 0 112 0v4.5a.5.5 0 001 0V6a1 1 0 112 0v5a7 7 0 11-14 0V9a1 1 0 012 0v2.5a.5.5 0 001 0V4a1 1 0 012 0v4.5a.5.5 0 001 0V3z"
      },
      "Warm" => %{
        is_emoji: false,
        like_type: "Warm",
        bg: "bg-red-500",
        color: "text-red-500",
        bg_hover: "bg-red-600",
        fill: "even-odd",
        svg_path:
          "M3.172 5.172a4 4 0 015.656 0L10 6.343l1.172-1.171a4 4 0 115.656 5.656L10 17.657l-6.828-6.829a4 4 0 010-5.656z"
      }
    }
  end

  def comment_ai do
    [
      "É sobre isso e tá tudo bem.",
      "Procrastinei lendo isso, mas valeu a pena!",
      "Se não for pra fazer TCC chorando, eu nem começo.",
      "Faltou só o ‘aí papai, paraaa!’.",
      "Isso aqui vai cair na prova?",
      "Enem vibes total!",
      "Copiei, mas mudei as palavras pra não parecer igual.",
      "Se vira nos 30, bixo!",
      "Sextou na aula de Cálculo 3!",
      "Quando o professor diz: ‘Só vai precisar de lápis e borracha na prova’.",
      "Aqui jaz minha esperança de passar direto.",
      "Universitário raiz usa café e sonhos.",
      "Alguém sabe se isso dá ponto extra?",
      "Vou apresentar no seminário e fingir que entendi.",
      "Isso tá mais difícil que os boletos de um graduando.",
      "Chama na xérox!",
      "Plot twist: o professor atrasou o prazo do TCC.",
      "Essa é a energia de um aluno às 23:59.",
      "Bicho, me manda isso aí no grupo do zap da turma.",
      "Nem Freud explica essa matéria.",
      "Tava tudo bem, mas o RU estragou meu dia.",
      "Quem nunca colou na prova que atire a primeira pedra.",
      "Anotem, vai cair na prova final!",
      "Isso é mais polêmico que lista de chamada em greve.",
      "Hoje é dia de chorar no ombro da monitoria.",
      "Já pode pedir música no Fantástico!",
      "Passar na matéria é bom, mas já tomou caldo de cana depois da aula?",
      "Isso aqui tá mais confuso que horário de veterano.",
      "Vai no presencial ou vai assistir no YouTube?",
      "Prova surpresa = trauma eterno.",
      "Eu tinha uma vida antes dessa graduação."
    ]
    |> Enum.random()
  end

  def comment_loading do
    [
      "Calibrando a pamonha, tá esquentando...",
      "Chamando o carro da pamonha...",
      "Dando uma volta na Praça do Sol...",
      "Ajustando o tempero do pequi...",
      "Alinhando o sertanejo universitário...",
      "Pediram jantinha? Já tá quase pronta!",
      "Indo buscar no pit dog, calma aí...",
      "Consultando o mapa da Feira Hippie...",
      "Organizando o rolê no Vaca Brava...",
      "Passando na Praça Cívica...",
      "Esperando o pão de queijo crescer...",
      "Ligando pro vizinho pra pedir o tereré...",
      "Subindo o morro pra achar sinal...",
      "Chamando o Goiás Esporte Clube...",
      "Deixando o arroz no ponto, calma...",
      "Pegando o cacho de banana na beira da estrada...",
      "Indo na conveniência pra pegar um refri...",
      "Testando o melhor pit dog de Goiânia...",
      "Procurando vaga no Flamboyant...",
      "Cuidando das mudas de IPÊ...",
      "Organizando o churrasco na laje...",
      "Atualizando a playlist de modão...",
      "Descascando o pequi, com cuidado...",
      "Arrumando a cadeira de plástico na calçada...",
      "Chamando o povo pra Feira do Cerrado...",
      "Verificando se o pão de queijo tá no ponto...",
      "Preparando o suco de caju natural...",
      "Passando na rodoviária pra pegar um comboio...",
      "Arrumando a pamonha, já tá quase!",
      "Atualizando o zap da família...",
      "Calibrando o som do carro pra tocar sertanejo...",
      "Checando a previsão pra ver se vai dar chuva...",
      "Resolvendo se vai pra jantinha ou pit dog...",
      "Tirando o arroz carreteiro do fogo...",
      "Arrumando a botina pra ir pro sertão...",
      "Rodando a pracinha de moto, pera aí...",
      "Ligando pra chamar o povo do interior!",
      "Buscando o pastel na feira...",
      "Tirando foto no lago de Corumbá...",
      "Procurando a chave do carro de boi..."
    ]
    |> Enum.random()
  end

  alias Shlinkedin.Timeline.Template

  @doc """
  Returns the list of templates.

  ## Examples

      iex> list_templates()
      [%Template{}, ...]

  """
  def list_templates do
    Repo.all(Template)
  end

  @doc """
  Gets a single template.

  Raises `Ecto.NoResultsError` if the Template does not exist.

  ## Examples

      iex> get_template!(123)
      %Template{}

      iex> get_template!(456)
      ** (Ecto.NoResultsError)

  """
  def get_template!(id), do: Repo.get!(Template, id)

  def get_template_by_title_return_body(title) do
    Repo.one(from(t in Template, where: t.title == ^title, select: t.body))
  end

  @doc """
  Creates a template.

  ## Examples

      iex> create_template(%{field: value})
      {:ok, %Template{}}

      iex> create_template(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_template(attrs \\ %{}) do
    %Template{}
    |> Template.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a template.

  ## Examples

      iex> update_template(template, %{field: new_value})
      {:ok, %Template{}}

      iex> update_template(template, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_template(%Template{} = template, attrs) do
    template
    |> Template.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a template.

  ## Examples

      iex> delete_template(template)
      {:ok, %Template{}}

      iex> delete_template(template)
      {:error, %Ecto.Changeset{}}

  """
  def delete_template(%Template{} = template) do
    Repo.delete(template)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking template changes.

  ## Examples

      iex> change_template(template)
      %Ecto.Changeset{data: %Template{}}

  """
  def change_template(%Template{} = template, attrs \\ %{}) do
    Template.changeset(template, attrs)
  end

  alias Shlinkedin.Timeline.Tagline

  def get_random_tagline do
    Repo.one(
      from(t in Tagline,
        where: t.active,
        order_by: fragment("RANDOM()"),
        limit: 1
      )
    )
  end

  @doc """
  Returns the list of taglines.

  ## Examples

      iex> list_taglines()
      [%Tagline{}, ...]

  """
  def list_taglines do
    Repo.all(Tagline)
  end

  @doc """
  Gets a single tagline.

  Raises `Ecto.NoResultsError` if the Tagline does not exist.

  ## Examples

      iex> get_tagline!(123)
      %Tagline{}

      iex> get_tagline!(456)
      ** (Ecto.NoResultsError)

  """
  def get_tagline!(id), do: Repo.get!(Tagline, id)

  @doc """
  Creates a tagline.

  ## Examples

      iex> create_tagline(%{field: value})
      {:ok, %Tagline{}}

      iex> create_tagline(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_tagline(attrs \\ %{}) do
    %Tagline{}
    |> Tagline.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a tagline.

  ## Examples

      iex> update_tagline(tagline, %{field: new_value})
      {:ok, %Tagline{}}

      iex> update_tagline(tagline, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_tagline(%Tagline{} = tagline, attrs) do
    tagline
    |> Tagline.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a tagline.

  ## Examples

      iex> delete_tagline(tagline)
      {:ok, %Tagline{}}

      iex> delete_tagline(tagline)
      {:error, %Ecto.Changeset{}}

  """
  def delete_tagline(%Tagline{} = tagline) do
    Repo.delete(tagline)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking tagline changes.

  ## Examples

      iex> change_tagline(tagline)
      %Ecto.Changeset{data: %Tagline{}}

  """
  def change_tagline(%Tagline{} = tagline, attrs \\ %{}) do
    Tagline.changeset(tagline, attrs)
  end

  @doc """
  Returns the list of social_prompts.

  ## Examples

      iex> list_social_prompts()
      [%SocialPrompt{}, ...]

  """
  def list_social_prompts do
    Repo.all(SocialPrompt)
  end

  @doc """
  Gets random social prompt
  """
  def get_random_prompt() do
    Repo.one(
      from(t in SocialPrompt,
        where: t.active,
        order_by: fragment("RANDOM()"),
        limit: 1
      )
    )
    |> create_prompt_if_nil()
  end

  defp create_prompt_if_nil(nil) do
    {:ok, prompt} = create_social_prompt(%{text: "This is so inspiring: "})
    prompt
  end

  defp create_prompt_if_nil(prompt), do: prompt

  @doc """
  Gets a single social_prompt.

  Raises `Ecto.NoResultsError` if the Social prompt does not exist.

  ## Examples

      iex> get_social_prompt!(123)
      %SocialPrompt{}

      iex> get_social_prompt!(456)
      ** (Ecto.NoResultsError)

  """
  def get_social_prompt!(id), do: Repo.get!(SocialPrompt, id)

  @doc """
  Creates a social_prompt.

  ## Examples

      iex> create_social_prompt(%{field: value})
      {:ok, %SocialPrompt{}}

      iex> create_social_prompt(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_social_prompt(attrs \\ %{}) do
    %SocialPrompt{}
    |> SocialPrompt.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a social_prompt.

  ## Examples

      iex> update_social_prompt(social_prompt, %{field: new_value})
      {:ok, %SocialPrompt{}}

      iex> update_social_prompt(social_prompt, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_social_prompt(%SocialPrompt{} = social_prompt, attrs) do
    social_prompt
    |> SocialPrompt.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a social_prompt.

  ## Examples

      iex> delete_social_prompt(social_prompt)
      {:ok, %SocialPrompt{}}

      iex> delete_social_prompt(social_prompt)
      {:error, %Ecto.Changeset{}}

  """
  def delete_social_prompt(%SocialPrompt{} = social_prompt) do
    Repo.delete(social_prompt)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking social_prompt changes.

  ## Examples

      iex> change_social_prompt(social_prompt)
      %Ecto.Changeset{data: %SocialPrompt{}}

  """
  def change_social_prompt(%SocialPrompt{} = social_prompt, attrs \\ %{}) do
    SocialPrompt.changeset(social_prompt, attrs)
  end

  def og_image_url() do
    System.get_env("OG_IMAGE_URL")
  end

  alias Shlinkedin.Timeline.RewardMessage

  @doc """
  Returns the list of reward_messages.

  ## Examples

      iex> list_reward_messages()
      [%RewardMessage{}, ...]

  """
  def list_reward_messages do
    Repo.all(RewardMessage)
  end

  def get_random_reward_message() do
    Repo.one(
      from(t in RewardMessage,
        order_by: fragment("RANDOM()"),
        limit: 1
      )
    )
    |> create_reward_message_if_nil()
  end

  defp create_reward_message_if_nil(nil) do
    {:ok, prompt} =
      create_reward_message(%{text: "Keep it up and you’ll get a promotion, maybe!"})

    prompt
  end

  defp create_reward_message_if_nil(message), do: message

  @doc """
  Gets a single reward_message.

  Raises `Ecto.NoResultsError` if the Reward message does not exist.

  ## Examples

      iex> get_reward_message!(123)
      %RewardMessage{}

      iex> get_reward_message!(456)
      ** (Ecto.NoResultsError)

  """
  def get_reward_message!(id), do: Repo.get!(RewardMessage, id)

  @doc """
  Creates a reward_message.

  ## Examples

      iex> create_reward_message(%{field: value})
      {:ok, %RewardMessage{}}

      iex> create_reward_message(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_reward_message(attrs \\ %{}) do
    %RewardMessage{}
    |> RewardMessage.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a reward_message.

  ## Examples

      iex> update_reward_message(reward_message, %{field: new_value})
      {:ok, %RewardMessage{}}

      iex> update_reward_message(reward_message, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_reward_message(%RewardMessage{} = reward_message, attrs) do
    reward_message
    |> RewardMessage.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a reward_message.

  ## Examples

      iex> delete_reward_message(reward_message)
      {:ok, %RewardMessage{}}

      iex> delete_reward_message(reward_message)
      {:error, %Ecto.Changeset{}}

  """
  def delete_reward_message(%RewardMessage{} = reward_message) do
    Repo.delete(reward_message)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking reward_message changes.

  ## Examples

      iex> change_reward_message(reward_message)
      %Ecto.Changeset{data: %RewardMessage{}}

  """
  def change_reward_message(%RewardMessage{} = reward_message, attrs \\ %{}) do
    RewardMessage.changeset(reward_message, attrs)
  end
end
