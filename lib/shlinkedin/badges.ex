defmodule Shlinkedin.Badges do
  alias Shlinkedin.Profiles.Profile
  alias Shlinkedin.Profiles.Award
  alias Shlinkedin.Profiles
  import Phoenix.LiveView.Helpers

  def profile_badges(socket, %Profile{} = profile, size \\ 4) do
    show_profile_badges(socket, Profiles.list_awards(profile), size)
  end

  defp profile_badge_active(%Award{} = award) do
    NaiveDateTime.compare(
      NaiveDateTime.utc_now(),
      NaiveDateTime.add(
        award.inserted_at,
        award.award_type.profile_badge_days * 86400,
        :second
      )
    ) == :lt
  end

  defp show_profile_badges(assigns, awards, size) do
    ~L"""
    <div class="inline-flex">

    <%= for award <- awards do %>
    <%= if award.award_type.profile_badge and profile_badge_active(award) do %>
    <div class="inline-flex align-baseline <%= award.award_type.color %>">

    <%= cond do %>
    <% award.award_type.name == "Platinum" or award.award_type.name == "Shplatinum" -> %>
    <div class="tooltip leading-8 text-sm">
      <span style="padding: 1px; --tw-gradient-to: #19f2a3" class="rounded text-white font-medium bg-gradient-to-tr from-blue-400 to-green-400 ">
      sh
      </span>
      <span class="tooltip-text">
        Me Livra + 
      </span>
    </div>

    <% award.award_type.image_format == "svg" ->  %>
        <svg class="w-<%= size %> h-<%= size %>" fill="currentColor" viewBox="0 0 20 20"
            xmlns="http://www.w3.org/2000/svg">
            <path fill-rule="<%= award.award_type.fill%>" d="<%= award.award_type.svg_path %>"
                clip-rule="<%= award.award_type.fill%>">
            </path>
        </svg>
    <% true ->  %>
    <span class="text-sm leading-8">
    <%= award.award_type.emoji %>
    </span>
    <% end %>
    </div>

    <% end %>
    <% end %>

    </div>

    """
  end
end
