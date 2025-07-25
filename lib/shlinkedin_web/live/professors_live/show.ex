defmodule ShlinkedinWeb.ProfessorsLive.Show do
  use ShlinkedinWeb, :live_view

  require IEx
  alias Code.Identifier
  alias Shlinkedin.Professors
  alias Shlinkedin.Timeline
  alias Shlinkedin.Timeline.Comment
  alias Shlinkedin.Professors.Professor
  alias Shlinkedin.Provas
  alias Shlinkedin.Provas.ProvaAntiga

  @impl true
  def mount(%{"slug" => slug, "instituto" => instituto}, session, socket) do
    professor = String.upcase(slug) |> String.trim()
    inst = String.upcase(instituto) |> String.trim()

    if is_nil(professor) || is_nil(inst) do
      {:ok, redirect(socket, to: "/404")}
    else
      socket = is_user(session, socket)
      urls = Professors.get_temporary_urls(String.downcase(inst), professor)

      turmas_urls = Enum.map(urls, fn {:ok, url} -> url end)

      dadosProfessor = Professors.search_professors(professor, inst)

      provas_antigas =
        if Map.get(socket.assigns, :profile) && socket.assigns.profile.verificado &&
             match?(%Professor{}, dadosProfessor) do
          fetch_provas_antigas_professor(%{"professor_id" => dadosProfessor.id})
        else
          []
        end

      provas_antigas =
        Provas.buscar_provas_antigas_usando_file_path_no_s3(
          "melivra",
          provas_antigas
        )

      reviews =
        case dadosProfessor do
          %Professor{} ->
            %{
              counts: [
                %{rating: 1, count: dadosProfessor.qts_n1},
                %{rating: 2, count: dadosProfessor.qts_n2},
                %{rating: 3, count: dadosProfessor.qts_n3},
                %{rating: 4, count: dadosProfessor.qts_n4},
                %{rating: 5, count: dadosProfessor.qts_n5},
                %{rating: 6, count: dadosProfessor.qts_n6},
                %{rating: 7, count: dadosProfessor.qts_n7},
                %{rating: 8, count: dadosProfessor.qts_n8},
                %{rating: 9, count: dadosProfessor.qts_n9},
                %{rating: 10, count: dadosProfessor.qts_n10}
              ],
              totalCount: dadosProfessor.qts_avaliacao
            }

          _ ->
            %{
              counts: [],
              totalCount: 0
            }
        end

      nota_profs =
        case dadosProfessor do
          %Professor{} ->
            %{
              nota: dadosProfessor.nota,
              qts_avaliacao: dadosProfessor.qts_avaliacao
            }

          _ ->
            %{
              nota: 1,
              qts_avaliacao: 1
            }
        end

      materias_unique =
        if !Enum.empty?(provas_antigas),
          do: provas_antigas |> Enum.map(& &1.materia) |> Enum.uniq(),
          else: []

      semestres_unique =
        if !Enum.empty?(provas_antigas),
          do: provas_antigas |> Enum.map(& &1.semestre) |> Enum.uniq(),
          else: []

      cursos_unique =
        if !Enum.empty?(provas_antigas),
          do: provas_antigas |> Enum.map(& &1.curso_dado) |> Enum.uniq(),
          else: []

      provas_unique =
        if !Enum.empty?(provas_antigas),
          do: provas_antigas |> Enum.map(& &1.numero_prova) |> Enum.uniq(),
          else: []

      {:ok,
       socket
       |> assign(:content_selection, "notas")
       |> assign(
         like_map: Timeline.like_map(),
         comment_like_map: Timeline.comment_like_map(),
         page: 1,
         per_page: 5,
         num_show_comments: 1
       )
       |> assign(:uploaded_files, [])
       |> allow_upload(:imagem, accept: ~w(.jpg .jpeg .png), max_entries: 1)
       |> allow_upload(:pdf,
         accept: ~w(.pdf),
         max_entries: 1,
         max_file_size: 10_000_000
       )
       |> assign(:professor, professor)
       |> assign(:dados_professor, dadosProfessor)
       |> assign(:instituto, inst)
       |> assign(:page_title, "Perfil de #{professor}")
       |> assign(:reviews, reviews)
       |> assign(:nota_profs, nota_profs)
       |> assign(:turmas_urls, turmas_urls)
       |> assign(:show_modal_upload_prova_antiga, false)
       |> assign(:provas_antigas, provas_antigas)
       |> assign(:show_modal_edit_prova_antiga, false)
       |> assign(:show_modal_confirm_delete_prova_antiga, false)
       |> assign(:prova_em_edicao, %ProvaAntiga{})
       |> assign(:prova_a_excluir, %ProvaAntiga{})
       |> assign(:filtered_provas, nil)
       |> assign(:filters, %{})
       |> assign(:materias_unique, materias_unique)
       |> assign(:semestres_unique, semestres_unique)
       |> assign(:cursos_unique, cursos_unique)
       |> assign(:provas_unique, provas_unique)
       |> assign(:current_slide_provas_antigas, 0)
       |> assign(:show_modal, false)
       |> assign(:show_modal_comentario, false)
       |> assign(:show_modal_upload_imagem, false)
       |> assign(:current_slide, 0)
       |> assign(:base_url, ShlinkedinWeb.Endpoint.url())
       |> assign(:nota, nil)
       |> assign(:return_to, Routes.professors_show_path(socket, :show, professor, inst))
       |> fetch_posts()}
    end
  end

  defp fetch_posts(
         %{assigns: %{dados_professor: dados_professor, page: page, per_page: per}} = socket
       ) do
    case dados_professor do
      nil ->
        assign(socket, posts: [])

      _ ->
        assign(socket,
          posts:
            Timeline.list_posts(dados_professor, [paginate: %{page: page, per_page: per}], %{
              type: "professor",
              time: "all_time"
            })
        )
    end
  end

  def handle_event("next_slide_provas_antigas", _, socket) do
    current = socket.assigns.current_slide_provas_antigas
    total = length(socket.assigns.provas_antigas)

    new_current =
      if current >= total - 1 do
        total - 1
      else
        current + 1
      end

    {:noreply, assign(socket, :current_slide_provas_antigas, new_current)}
  end

  def handle_event("pre_slide_provas_antigas", _, socket) do
    current = socket.assigns.current_slide_provas_antigas

    new_current =
      if current <= 0 do
        0
      else
        current - 1
      end

    {:noreply, assign(socket, :current_slide_provas_antigas, new_current)}
  end

  @allowed_keys ~w(professor_id semestre curso_dado materia data_inicio data_fim)

  defp fetch_provas_antigas_professor(params) do
    filtered_params = Map.take(params, @allowed_keys)

    case Provas.list_provas_filtradas(filtered_params) do
      provas when is_list(provas) -> provas
      _ -> []
    end
  end

  def handle_event("filtrar", %{"filtros" => filtros}, socket) do
    provas_filtradas =
      Enum.filter(socket.assigns.provas_antigas, fn prova ->
        Enum.all?(["materia", "semestre", "curso_dado"], fn campo ->
          filtro = String.downcase(filtros[campo] || "")
          valor = String.downcase(prova[campo] || "")
          filtro == "" or String.contains?(valor, filtro)
        end)
      end)

    {:noreply,
     socket
     |> assign(:filtros, filtros)
     |> assign(:provas_filtradas, provas_filtradas)}
  end

  @impl true
  def handle_event("select_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, content_selection: tab)}
  end

  def handle_event("next_slide", _, socket) do
    current_slide = socket.assigns[:current_slide]
    total_slides = length(socket.assigns[:turmas_urls]) - 1

    next_slide = if current_slide < total_slides, do: current_slide + 1, else: 0

    {:noreply, assign(socket, :current_slide, next_slide)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :show, _params) do
    socket
  end

  def handle_event("prev_slide", _, socket) do
    current_slide = socket.assigns[:current_slide]
    total_slides = length(socket.assigns[:turmas_urls]) - 1

    prev_slide = if current_slide > 0, do: current_slide - 1, else: total_slides

    {:noreply, assign(socket, :current_slide, prev_slide)}
  end

  def handle_event("open_modal", _, socket) do
    case socket.assigns.profile do
      nil ->
        socket = put_flash(socket, :info, "Você precisa criar uma conta para fazer isso :)")
        {:noreply, socket}

      _profile ->
        {:noreply, assign(socket, show_modal: true)}
    end
  end

  def handle_event("show_modal_upload_prova_antiga", _, socket) do
    case socket.assigns.profile do
      nil ->
        socket = put_flash(socket, :info, "Você precisa criar uma conta para fazer isso :)")
        {:noreply, socket}

      _profile ->
        {:noreply, assign(socket, show_modal_upload_prova_antiga: true)}
    end
  end

  def handle_event("close_modal_upload_pdf", _, socket) do
    {:noreply, assign(socket, show_modal_upload_prova_antiga: false)}
  end

  def handle_event("upload_prova_antiga_pdf", %{"prova_antiga" => params}, socket) do
    case socket.assigns.profile do
      nil ->
        {:noreply, put_flash(socket, :info, "Você precisa estar logado para fazer isso :)")}

      %{verificado: false} ->
        {:noreply, put_flash(socket, :info, "Você precisa ser verificado para fazer isso :)")}

      %{verificado: true, id: profile_id} ->
        professor_id = socket.assigns.dados_professor.id

        pdf_binary =
          consume_uploaded_entries(socket, :pdf, fn %{path: path}, _entry ->
            File.read!(path)
          end)
          |> List.first()

        attrs =
          Map.merge(params, %{
            "file_data" => pdf_binary,
            "profile_id" => profile_id,
            "professor_id" => professor_id
          })

        case Shlinkedin.Provas.create_prova_antiga(attrs) do
          {:ok, prova} ->
            %{prova_id: prova.id}
            |> Shlinkedin.ProvasWorker.new()
            |> Oban.insert()

            {:noreply,
             socket
             |> put_flash(:info, "Prova enviada com sucesso para analise !")
             |> assign(:show_modal_upload_prova_antiga, false)}

          {:validation_error, changeset} ->
            {:noreply,
             socket
             |> put_flash(:error, "Preencha os campos corretamente.")
             |> assign(:changeset, changeset)}

          {:error, _other} ->
            {:noreply,
             socket
             |> put_flash(:error, "Erro interno ao salvar a prova. Tente mais tarde.")}
        end
    end
  end

  def handle_event("show_modal_comentario", _, socket) do
    case socket.assigns.profile do
      nil ->
        socket = put_flash(socket, :info, "Você precisa criar uma conta para fazer isso :)")
        {:noreply, socket}

      _profile ->
        {:noreply, assign(socket, show_modal_comentario: true)}
    end
  end

  def handle_event("show_modal_upload_imagem", _, socket) do
    case socket.assigns.profile do
      nil ->
        socket = put_flash(socket, :info, "Você precisa criar uma conta para fazer isso :)")
        {:noreply, socket}

      _profile ->
        {:noreply, assign(socket, show_modal_upload_imagem: true)}
    end
  end

  def handle_event("close_modal", _, socket) do
    {:noreply, assign(socket, show_modal: false)}
  end

  def handle_event("close_modal_comentario", _, socket) do
    {:noreply, assign(socket, show_modal: false)}
  end

  def handle_event("close_modal_upload_imagem", _, socket) do
    {:noreply, assign(socket, show_modal_upload_imagem: false)}
  end

  @impl true
  def handle_event("update_nota", %{"nota" => nota}, socket) do
    {:noreply, assign(socket, :nota, nota)}
  end

  @impl true
  def handle_event("dar_nota", %{"rating" => %{"nota" => nota}}, socket) do
    professor = socket.assigns.professor
    instituto = socket.assigns.instituto

    Professors.update_professor_rating(professor, instituto, nota)

    socket = assign(socket, show_modal: false)

    {:noreply,
     push_redirect(socket, to: Routes.professors_show_path(socket, :show, professor, instituto))}
  end

  @impl true
  def handle_event(
        "dar_comentario",
        %{"rating" => %{"nota" => nota, "comentario" => comentario}},
        socket
      ) do
    professor = socket.assigns.professor
    instituto = socket.assigns.instituto
    perfil = socket.assigns.profile

    Professors.update_professor_rating(professor, instituto, nota)
    prof = Professors.search_professors(professor, instituto)
    Professors.create_post(perfil, prof, %{body: comentario})

    socket = assign(socket, show_modal_comentario: false)

    {:noreply,
     push_redirect(socket, to: Routes.professors_show_path(socket, :show, professor, instituto))}
  end

  def handle_event("upload_imagem", params, socket) do
    periodo = Map.get(params, "periodo", "")
    periodoFormatado = format_periodo(periodo)

    uploaded_files =
      consume_uploaded_entries(socket, :imagem, fn meta, _entry ->
        {:ok, File.read!(meta.path)}
      end)

    case uploaded_files do
      [ok: file_content] ->
        professor_name = socket.assigns.professor
        unique_filename = "#{professor_name}#{periodoFormatado}"
        institute = socket.assigns.instituto

        Professors.upload_image(String.downcase(institute), unique_filename, file_content)

        socket = assign(socket, show_modal_upload_imagem: false)

        {:noreply,
         push_redirect(socket,
           to:
             Routes.professors_show_path(
               socket,
               :show,
               socket.assigns.professor,
               socket.assigns.instituto
             )
         )}

      _ ->
        {:noreply, socket}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("delete-comment", %{"id" => id}, socket) do
    {:ok, comment} = Timeline.get_allowed_change_comment(socket.assigns.profile, id)
    {:ok, _} = Timeline.delete_comment(comment)

    {:noreply,
     socket
     |> put_flash(:info, "Comment deleted")
     |> push_redirect(
       to:
         Routes.professors_show_path(
           socket,
           :show,
           socket.assigns.professor,
           socket.assigns.instituto
         )
     )}
  end

  defp apply_action(socket, :new_comment, %{
         "slug" => slug,
         "instituto" => instituto,
         "post_id" => post_id
       }) do
    IO.inspect(%{slug: slug, instituto: instituto, post_id: post_id},
      label: "Parâmetros recebidos"
    )

    professor = slug
    instituto = instituto
    post = Timeline.get_post_preload_profile(post_id)

    socket
    |> assign(:page_title, "Comentar")
    |> assign(:reply_to, nil)
    |> assign(:comments, [])
    |> assign(:comment, %Comment{})
    |> assign(:post, post)
    |> assign(:professor, professor)
    |> assign(:instituto, instituto)
  end

  defp apply_action(socket, :show_likes, %{"post_id" => id}) do
    post = Timeline.get_post_preload_profile(id)

    socket
    |> assign(:page_title, "Reactions")
    |> assign(
      :grouped_likes,
      Timeline.list_likes(post)
      |> Enum.group_by(&%{name: &1.name, photo_url: &1.photo_url, slug: &1.slug})
    )
  end

  defp apply_action(socket, :show_comment_likes, %{"comment_id" => comment_id}) do
    comment = Timeline.get_comment!(comment_id)

    socket
    |> assign(:page_title, "Comment Reactions")
    |> assign(
      :grouped_likes,
      Timeline.list_comment_likes(comment)
      |> Enum.group_by(&%{name: &1.name, photo_url: &1.photo_url, slug: &1.slug})
    )
    |> assign(:comment, comment)
  end

  def format_periodo(periodo) do
    cond do
      periodo != "" and valid_periodo?(periodo) ->
        "_#{periodo}_#{:erlang.unique_integer([:positive])}.png"

      true ->
        "_#{:erlang.unique_integer([:positive])}.png"
    end
  end

  defp valid_periodo?(periodo) do
    regex = ~r/^\d{4}\.\d{1,2}$/
    String.match?(periodo, regex)
  end

  def handle_event(
        "filter_provas",
        %{"materia" => materia, "semestre" => semestre, "curso" => curso, "prova" => prova},
        socket
      ) do
    filters = %{
      "materia" => if(materia == "", do: nil, else: materia),
      "semestre" => if(semestre == "", do: nil, else: semestre),
      "curso" => if(curso == "", do: nil, else: curso),
      "prova" => if(prova == "", do: nil, else: prova)
    }

    filtered_provas = filter_provas(socket.assigns.provas_antigas, filters)

    socket =
      socket
      |> assign(:filtered_provas, filtered_provas)
      |> assign(:filters, filters)
      # Resetar para o primeiro item
      |> assign(:current_slide_provas_antigas, 0)

    {:noreply, socket}
  end

  def handle_event("reset_filters", _, socket) do
    socket =
      socket
      |> assign(:filtered_provas, nil)
      |> assign(:filters, %{})
      |> assign(:current_slide_provas_antigas, 0)

    {:noreply, socket}
  end

  def handle_event("editar_prova", %{"id" => id}, socket) do
    case Provas.get_prova_antiga(id) do
      {:ok, prova} ->
        socket =
          socket
          |> assign(:show_modal_edit_prova_antiga, true)
          |> assign(:prova_em_edicao, prova)

        {:noreply, socket}

      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, "Prova não encontrada.")}
    end
  end

  def handle_event("close_modal_editar", _, socket) do
    socket =
      socket
      |> assign(:show_modal_edit_prova_antiga, false)
      |> assign(:prova_em_edicao, %ProvaAntiga{})

    {:noreply, socket}
  end

  def handle_event("excluir_prova", %{"id" => id}, socket) do
    case Provas.get_prova_antiga(id) do
      {:ok, prova} ->
        socket =
          socket
          |> assign(:show_modal_confirm_delete_prova_antiga, true)
          |> assign(:prova_a_excluir, prova)

        {:noreply, socket}

      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, "Prova não encontrada.")}
    end
  end

  def handle_event("confirmar_exclusao_prova", %{"id" => id}, socket) do
    Provas.delete_prova_antiga(id, socket.assigns.profile.id)

    id = String.to_integer(id)

    provas_antigas =
      Enum.reject(socket.assigns.provas_antigas, fn prova ->
        prova.id == id
      end)

    socket =
      socket
      |> assign(:show_modal_confirm_delete_prova_antiga, false)
      |> assign(:provas_antigas, provas_antigas)
      |> assign(:prova_a_excluir, %ProvaAntiga{})

    {:noreply, socket}
  end

  def handle_event("close_modal_delete", _, socket) do
    socket =
      socket
      |> assign(:show_modal_confirm_delete_prova_antiga, false)
      |> assign(:prova_a_excluir, %ProvaAntiga{})

    {:noreply, socket}
  end

  def handle_event("validate_edicao_prova_antiga", %{"edit_prova_antiga" => params}, socket) do
    changeset =
      ProvaAntiga.changeset(socket.assigns.prova_em_edicao, params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form_changeset, changeset)}
  end

  def handle_event("submit_edicao_prova_antiga", %{"edit_prova_antiga" => params}, socket) do
    prova_antiga = socket.assigns.prova_em_edicao

    IO.inspect(prova_antiga, label: "Prova Antiga antes da edição")

    update_params =
      params
      |> Enum.filter(fn {key, value} ->
        original = Map.get(prova_antiga, String.to_existing_atom(key))
        value != nil and value != "" and value != original
      end)
      |> Enum.into(%{})

    IO.inspect(update_params, label: "Parâmetros de atualização")

    if map_size(update_params) == 0 do
      {:noreply,
       socket
       |> assign(:show_modal_edit_prova_antiga, false)
       |> assign(:prova_em_edicao, %ProvaAntiga{})}
    else
      case Provas.update_prova_antiga(prova_antiga.id, socket.assigns.profile.id, update_params) do
        {:ok, prova_atualizada} ->
          IO.inspect(prova_atualizada, label: "Prova Antiga atualizada")
          IO.inspect(socket.assigns.provas_antigas, label: "Provas Antigas antes da atualização")

          prova_atualizada = %{
            url_assinada: prova_atualizada.file_path,
            materia: prova_atualizada.materia,
            semestre: prova_atualizada.semestre,
            curso_dado: prova_atualizada.curso_dado,
            numero_prova: prova_atualizada.numero_prova,
            profile_id: prova_atualizada.profile_id,
            id: prova_atualizada.id
          }

          provas_antigas =
            Enum.map(socket.assigns.provas_antigas, fn p ->
              if p.id == prova_atualizada.id, do: prova_atualizada, else: p
            end)

          {:noreply,
           socket
           |> assign(:show_modal_edit_prova_antiga, false)
           |> assign(:prova_em_edicao, %ProvaAntiga{})
           |> assign(:provas_antigas, provas_antigas)}

        {:error, _reason} ->
          # Aqui você pode tratar melhor e exibir erro se quiser
          {:noreply, socket}
      end
    end
  end

  defp filter_provas(provas, filters) do
    provas
    |> Enum.filter(fn prova ->
      (is_nil(filters["materia"]) || prova.materia == filters["materia"]) &&
        (is_nil(filters["semestre"]) || prova.semestre == filters["semestre"]) &&
        (is_nil(filters["curso"]) || prova.curso_dado == filters["curso"]) &&
        (is_nil(filters["prova"]) || prova.numero_prova == filters["prova"])
    end)
  end
end
