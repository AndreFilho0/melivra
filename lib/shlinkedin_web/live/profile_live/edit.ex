defmodule ShlinkedinWeb.ProfileLive.Edit do
  use ShlinkedinWeb, :live_view
  alias Shlinkedin.Profiles
  alias Shlinkedin.Profiles.Profile
  alias Shlinkedin.Accounts

  @bio_placeholders [
    "Minha jornada acadêmica começou com uma paixão por descobrir como as coisas funcionam. Agora, estou aqui para compartilhar conhecimento, colaborar em projetos incríveis e tomar café em quantidades industriais.",
    "Desde que entrei na universidade, aprendi que a vida é como um laboratório: às vezes os experimentos dão certo, às vezes explodem, mas sempre há algo novo para descobrir.",
    "Estudante de [Curso], apaixonado(a) por [Área de Interesse]. Quando não estou debruçado(a) sobre livros, estou planejando como conquistar o mundo (ou pelo menos passar nas provas).",
    "Acredito que o conhecimento é a chave para mudar o mundo. Por isso, estou sempre buscando aprender algo novo e compartilhar ideias com a comunidade acadêmica.",
    "Viciado(a) em café, livros e noites sem dormir antes das provas. Mas, no fim, tudo vale a pena quando você faz parte de uma comunidade incrível como a nossa."
  ]

  @title_placeholders [
    "Medicina",
    "Direito",
    "Engenharia Civil",
    "Administração",
    "Ciência da Computação",
    "Psicologia",
    "Enfermagem",
    "Pedagogia",
    "Economia",
    "Contabilidade",
    "Marketing",
    "Publicidade e Propaganda",
    "Jornalismo",
    "Relações Internacionais",
    "Design Gráfico",
    "Arquitetura e Urbanismo",
    "Engenharia Mecânica",
    "Engenharia Elétrica",
    "Farmácia",
    "Fisioterapia"
  ]
  def mount(_params, session, socket) do
    socket =
      is_user(session, socket)
      |> allow_upload(:photo,
        accept: ~w(.png .jpeg .jpg .gif .webp),
        max_entries: 1,
        max_file_size: 12_000_000,
        external: &presign_entry/2
      )
      |> allow_upload(:cover_photo,
        accept: ~w(.png .jpeg .jpg .gif .webp),
        max_file_size: 12_000_000,
        max_entries: 1,
        external: &presign_entry/2
      )

    profile = if is_nil(socket.assigns.profile), do: %Profile{}, else: socket.assigns.profile

    user_image = session["user_image"]
    verificado_google = session["verificado_google"]

    base_changeset = Profiles.change_profile(profile)

    changeset =
      if user_image do
        Ecto.Changeset.put_change(base_changeset, :photo_url, user_image)
      else
        base_changeset
      end

    changeset =
      if verificado_google do
        Ecto.Changeset.put_change(changeset, :verificado, true)
      else
        changeset
      end

    {:ok,
     socket
     |> assign(changeset: changeset)
     |> assign(profile: profile)
     |> assign(token: session["user_token"])
     |> assign(session: session)
     |> assign(bio_placeholder: @bio_placeholders |> Enum.random())
     |> assign(title_placeholder: @title_placeholders |> Enum.random())}
  end

  def handle_event("delete-account", _, socket) do
    {:ok, _user} = Shlinkedin.Accounts.delete_user(socket.assigns.current_user)

    Accounts.delete_session_token(socket.assigns.token)

    {:noreply,
     socket
     |> put_flash(:info, "Deletado com Sucesso")
     |> push_redirect(to: "/join")}
  end

  def handle_event("validate_photo", %{"photo" => %{}} = params, socket) do
    IO.inspect(params, label: "Parâmetros do evento de change")
    {:noreply, socket}
  end

  def handle_event("save", %{"profile" => profile_params}, socket) do
    require IEx
    IEx.pry()
    save_profile(socket, socket.assigns.live_action, profile_params)
  end

  def handle_event("cancel-entry", %{"ref" => ref, "category" => category}, socket) do
    case category do
      "profile" -> {:noreply, cancel_upload(socket, :photo, ref)}
      "cover" -> {:noreply, cancel_upload(socket, :cover_photo, ref)}
    end
  end

  def handle_event("validate", params, socket) do
    changeset =
      Profiles.change_profile(
        socket.assigns.profile,
        params["profile"]
      )
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("inspire", _params, socket) do
    persona_name = Shlinkedin.Timeline.Generators.full_name()
    photo = Shlinkedin.Timeline.Generators.profile_photo()
    username = persona_name |> Shlinkedin.Timeline.Generators.slugify()

    changeset =
      socket.assigns.changeset
      |> Ecto.Changeset.put_change(:persona_name, persona_name)
      |> Ecto.Changeset.put_change(:photo_url, photo)
      |> Ecto.Changeset.put_change(:username, username)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  defp save_profile(socket, :edit, profile_params) do
    profile_params = put_photo_urls(socket, profile_params)
    profile_params = put_photo_urls(socket, profile_params, :cover_photo, "cover_photo_url")

    if profile_params["publish_profile_picture"] == "true" do
      Shlinkedin.Timeline.create_post(
        socket.assigns.profile,
        %{body: "Nova Foto!", profile_update: true, update_type: "ShlinkPic"}
      )
    end

    case Profiles.update_profile(
           socket.assigns.profile,
           socket.assigns.current_user,
           profile_params,
           &consume_photos(socket, &1)
         ) do
      {:ok, profile} ->
        {:noreply,
         socket
         |> put_flash(:info, "Sucesso")
         |> push_redirect(to: Routes.profile_show_path(socket, :show, profile.slug))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_profile(socket, :new, profile_params) do
    profile_params = put_photo_urls(socket, profile_params)

    case(
      Profiles.create_profile(
        socket.assigns.current_user,
        profile_params,
        &consume_photos(socket, &1)
      )
    ) do
      {:ok, profile} ->
        {:noreply,
         socket
         |> assign(:profile, profile)
         |> put_flash(:info, "Bem vindo ao melivra, #{profile.persona_name}!")
         |> redirect(to: Routes.home_index_path(socket, :index, "featured"))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp put_photo_urls(socket, attrs, photo_category \\ :photo, photo_name \\ "photo_url") do
    {completed, []} = uploaded_entries(socket, photo_category)

    urls =
      for entry <- completed do
        Path.join(s3_host(), s3_key(entry))
      end

    case urls do
      [] ->
        attrs

      [url | _] ->
        Map.put(attrs, photo_name, url)
    end
  end

  @bucket "melivra"
  defp s3_host, do: "https://bucket.melivra.com/melivra"

  defp s3_key(entry) do
    "usuario/perfil/#{entry.uuid}.#{ext(entry)}"
  end

  def presign_entry(entry, socket) do
    uploads = socket.assigns.uploads

    key = s3_key(entry)

    config = %{
      scheme: "https://",
      host: "bucket.melivra.com",
      region: "us-east-1",
      access_key_id: "RH5HJljyfQhu3qlkCR9X",
      secret_access_key: "FS9FfNX04020AIvM2bECnYOpHlmtP55tKy5beGBx"
    }

    {:ok, fields} =
      Shlinkedin.SimpleS3Upload.sign_form_upload(config, @bucket,
        key: key,
        content_type: entry.client_type,
        max_file_size: uploads.photo.max_file_size,
        expires_in: :timer.minutes(2)
      )

    meta = %{uploader: "S3", key: key, url: s3_host(), fields: fields}
    {:ok, meta, socket}
  end

  def consume_photos(socket, %Profile{} = profile) do
    consume_uploaded_entries(socket, :photo, fn _meta, _entry -> :ok end)

    {:ok, profile}
  end

  def ext(entry) do
    [ext | _] = MIME.extensions(entry.client_type)
    ext
  end
end
