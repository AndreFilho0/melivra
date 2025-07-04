defmodule ShlinkedinWeb.GroupLive.Show do
  use ShlinkedinWeb, :live_view

  alias Shlinkedin.Groups
  alias Shlinkedin.Groups.Invite
  alias Shlinkedin.Timeline
  alias Shlinkedin.Timeline.Post
  alias Shlinkedin.Timeline.Comment

  @per_page 5

  @impl true
  def mount(%{"id" => id}, session, socket) do
    socket = is_user(session, socket)
    group = Groups.get_group!(id)

    if connected?(socket) do
      Timeline.subscribe()
    end

    {:ok,
     socket
     |> assign(
       show_menu: false,
       feed_options: %{type: "group", time: "all_time"},
       group: group,
       page_title: group.title,
       member_status: is_member?(socket.assigns.profile, group),
       members: members(group),
       admins: Shlinkedin.Groups.list_admins(group),
       member_ranking: Shlinkedin.Groups.get_member_ranking(socket.assigns.profile, group),
       page: 1,
       per_page: @per_page,
       like_map: Timeline.like_map(),
       comment_like_map: Timeline.comment_like_map(),
       num_show_comments: 3
     )
     |> fetch_posts(),
     temporary_assigns: [
       posts: [],
       total_pages: calc_max_pages(group, @per_page),
       group_total_posts: Groups.count_group_posts(group)
     ]}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :show, _params) do
    socket
  end

  defp apply_action(socket, :invite, %{"id" => id}) do
    socket
    |> assign(:page_title, "Convite para #{socket.assigns.group.title}")
    |> assign(:profile, socket.assigns.profile)
    |> assign(:invite, %Invite{})
    |> assign(:group, Groups.get_group!(id))
  end

  defp apply_action(socket, :edit_group, %{"id" => id}) do
    socket
    |> assign(:page_title, "Editar Grupo")
    |> assign(:group, Groups.get_group!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "Criar post  #{socket.assigns.group.title}")
    |> assign(:post, %Post{group_id: socket.assigns.group.id})
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

  defp apply_action(socket, :new_comment, %{"post_id" => id, "reply_to" => username}) do
    post = Timeline.get_post_preload_profile(id)

    socket
    |> assign(:page_title, "Reply to #{post.profile.persona_name}'s comment")
    |> assign(:reply_to, username)
    |> assign(:comments, [])
    |> assign(:comment, %Comment{})
    |> assign(:post, post)
  end

  defp apply_action(socket, :new_comment, %{"post_id" => id}) do
    post = Timeline.get_post_preload_profile(id)

    socket
    |> assign(:page_title, "Comment")
    |> assign(:reply_to, nil)
    |> assign(:comments, [])
    |> assign(:comment, %Comment{})
    |> assign(:post, post)
  end

  defp apply_action(socket, :show_members, %{"id" => id}) do
    group = Groups.get_group!(id)
    profiles = Groups.list_members_as_profile(group)

    socket
    |> assign(:page_title, "#{group.title} Membros")
    |> assign(:members, profiles)
  end

  defp fetch_posts(%{assigns: %{page: page, per_page: per, group: group}} = socket) do
    assign(socket,
      posts:
        Timeline.list_posts(
          group,
          [paginate: %{page: page, per_page: per}],
          socket.assigns.feed_options
        )
    )
  end

  def handle_event("load-more", _, %{assigns: assigns} = socket) do
    {:noreply, socket |> assign(page: assigns.page + 1) |> fetch_posts()}
  end

  def handle_event("join-group", %{"id" => id}, socket) do
    group = Groups.get_group!(id)
    Groups.join_group(socket.assigns.profile, group, %{ranking: "member"})

    {:noreply, socket |> assign(member_status: is_member?(socket.assigns.profile, group))}
  end

  def handle_event("show-menu", _, socket) do
    socket = assign(socket, show_menu: !socket.assigns.show_menu)
    {:noreply, socket}
  end

  def handle_event("hide-menu", _, socket) do
    socket = assign(socket, show_menu: false)
    {:noreply, socket}
  end

  @impl true
  def handle_event("leave-group", _, socket) do
    Groups.leave_group(socket.assigns.profile, socket.assigns.group)

    {:noreply,
     socket
     |> put_flash(:info, "Você deixou o grupo")
     |> push_redirect(to: Routes.group_index_path(socket, :index))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    post = Timeline.get_post!(id)
    {:ok, _} = Timeline.delete_post(post)

    {:noreply,
     assign(
       socket,
       :posts,
       Timeline.list_posts(
         socket.assigns.profile,
         [paginate: %{page: 1, per_page: 5}],
         socket.assigns.feed_options
       )
     )}
  end

  @impl true
  def handle_event("delete-comment", %{"id" => id}, socket) do
    comment = Timeline.get_comment!(id)
    {:ok, _} = Timeline.delete_comment(comment)

    {:noreply,
     socket
     |> put_flash(:info, "Comment deletado")
     |> push_redirect(to: Routes.group_show_path(socket, :show, socket.assigns.group.id))}
  end

  @impl true
  def handle_event("delete-group", %{"id" => id}, socket) do
    group = Groups.get_group!(id)
    {:ok, _} = Groups.delete_group(group)

    {:noreply,
     socket
     |> put_flash(:info, "Grupo foi deletado")
     |> push_redirect(to: Routes.group_index_path(socket, :index))}
  end

  defp is_member?(profile, group) do
    Shlinkedin.Groups.is_member?(profile, group)
  end

  defp members(group) do
    Shlinkedin.Groups.list_members(group)
  end

  @impl true
  def handle_info({:post_created, post}, socket) do
    if post.group_id == socket.assigns.group.id do
      {:noreply, update(socket, :posts, fn posts -> [post | posts] end)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:post_updated, post}, socket) do
    if post.group_id == socket.assigns.group.id do
      {:noreply, update(socket, :posts, fn posts -> [post | posts] end)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:post_deleted, post}, socket) do
    if post.group_id == socket.assigns.group.id do
      {:noreply, update(socket, :posts, fn posts -> [post | posts] end)}
    else
      {:noreply, socket}
    end
  end

  def calc_max_pages(group, per_page) do
    total_posts = Groups.count_group_posts(group)
    trunc(total_posts / per_page)
  end
end
