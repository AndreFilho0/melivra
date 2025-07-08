defmodule Shlinkedin.Levels do
  alias ShlinkedinWeb.Router.Helpers, as: Routes
  alias Shlinkedin.Profiles.Profile
  alias Shlinkedin.Profiles

  def profile_level(socket, %Profile{} = profile) do
    get_current_level(profile, socket) |> level_names()
  end

  def level_names(level) do
    case level do
      # Iniciante na rede
      0 -> "🎓 Calouro"
      # Explorando o básico
      1 -> "📚 Estudante dedicado"
      # Ganhando experiência
      2 -> "✏️ Pesquisador júnior"
      # Bem avançado nos estudos
      3 -> "🧠 Pesquisador sênior"
      # Destaque acadêmico
      4 -> "🏆 Destaque acadêmico"
      # Líder e inspiração no ambiente
      5 -> "🌟 Lenda do campus"
      # Nível padrão
      _ -> "🎓 Calouro"
    end
  end

  def checklists(profile, socket) do
    %{
      0 => [
        %{
          done: true,
          route: Routes.home_index_path(socket, :index),
          name: "Entrar no MeLivra"
        },
        %{
          name: "Adicionar uma foto de perfil",
          route: Routes.profile_edit_path(socket, :edit),
          done:
            profile.photo_url !=
              "https://upload.wikimedia.org/wikipedia/commons/thumb/9/94/George_Washington%2C_1776.jpg/1200px-George_Washington%2C_1776.jpg"
        },
        %{
          name: "Fazer seu primeiro post",
          route: Routes.home_index_path(socket, :new),
          done: Shlinkedin.Timeline.num_posts(profile) > 0
        }
      ],
      1 => [
        %{
          done: profile.has_sent_one_shlink,
          route: Routes.users_index_path(socket, :index),
          name: "Interagir com um colega"
        },
        %{
          name: "Conseguir um seguidor",
          route: Routes.profile_show_path(socket, :show_friends, profile.slug),
          done: Profiles.count_followers(profile) >= 1
        }
      ],
      2 => [
        %{
          name: "Escrever uma avaliação para um colega",
          done: Profiles.count_written_endorsements(profile) >= 1,
          route: Routes.users_index_path(socket, :index)
        },
        %{
          name: "Convidar um amigo para o MeLivra",
          done: Profiles.count_invites(profile) >= 1,
          route: Routes.home_index_path(socket, :new_invite)
        },
        %{
          name: "Participar de um grupo de estudos",
          done: length(Shlinkedin.Groups.list_profile_groups(profile)) >= 1,
          route: Routes.group_index_path(socket, :index)
        },
        %{
          name: "Conseguir 5 seguidores",
          route: Routes.profile_show_path(socket, :show_friends, profile.slug),
          done: Profiles.count_followers(profile) >= 5
        }
      ],
      3 => [
        %{
          name: "Criar um evento acadêmico",
          done: Shlinkedin.Ads.count_profile_ads(profile) >= 1,
          route: Routes.home_index_path(socket, :new_ad)
        },
        %{
          name: "Publicar um artigo acadêmico",
          done: Shlinkedin.News.count_articles(profile) >= 1,
          route: Routes.home_index_path(socket, :new_article)
        },
        %{
          name: "Receber uma avaliação positiva",
          done: length(Profiles.list_testimonials(profile.id)) >= 1,
          route: Routes.profile_show_path(socket, :show, profile.slug)
        },
        %{
          name: "Conseguir 50 seguidores",
          route: Routes.profile_show_path(socket, :show_friends, profile.slug),
          done: Profiles.count_followers(profile) >= 50
        }
      ],
      4 => [
        %{
          name: "Criar um grupo de estudos",
          done: Shlinkedin.Groups.count_profile_creator(profile) >= 1,
          route: Routes.group_index_path(socket, :index)
        },
        %{
          name: "Ganhar um troféu acadêmico",
          done: length(Profiles.list_awards(profile)) >= 1,
          route: Routes.profile_show_path(socket, :show, profile.slug)
        },
        %{
          name: "Conseguir 100 seguidores",
          route: Routes.profile_show_path(socket, :show_friends, profile.slug),
          done: Profiles.count_followers(profile) >= 100
        }
      ]
    }
  end

  def completed_level?(%Profile{} = profile, socket, level) do
    checklists(profile, socket)[level]
    |> Enum.map(& &1.done)
    |> Enum.all?()
  end

  def get_current_level(%Profile{} = profile, socket) do
    cond do
      !completed_level?(profile, socket, 0) -> 0
      !completed_level?(profile, socket, 1) -> 1
      !completed_level?(profile, socket, 2) -> 2
      !completed_level?(profile, socket, 3) -> 3
      !completed_level?(profile, socket, 4) -> 4
      true -> 5
    end
  end

  def get_current_checklist(%Profile{id: nil}, _socket) do
    level = 0

    %{
      steps: %{},
      level_number: level,
      current_level: level_names(level),
      next_level: level_names(level + 1)
    }
  end

  def get_current_checklist(%Profile{} = profile, socket) do
    level = get_current_level(profile, socket)

    %{
      steps: checklists(profile, socket)[level],
      level_number: level,
      current_level: level_names(level),
      next_level: level_names(level + 1)
    }
  end
end
