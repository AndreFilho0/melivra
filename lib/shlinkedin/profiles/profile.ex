defmodule Shlinkedin.Profiles.Profile do
  use Ecto.Schema
  import Ecto.Changeset

  @username_regex ~r/^(?![_.])(?!.*[_.]{2})[a-z0-9._]+(?<![_.])$/

  schema "profiles" do
    field(:username, :string)
    field(:slug, :string)
    field(:persona_name, :string)
    field(:persona_title, :string)
    field(:summary, :string)
    field :interns, :integer, default: 0
    field :intern_names, {:array, :string}, default: []

    field(:admin, :boolean)
    field(:unsubscribed, :boolean, default: false)

    field(:photo_url, :string, default: "https://www.svgrepo.com/show/496485/profile-circle.svg")

    field(:cover_photo_url, :string)

    # not used
    field(:shlinkpoints, Money.Ecto.Amount.Type)

    belongs_to(:user, Shlinkedin.Accounts.User)
    has_many(:posts, Shlinkedin.Timeline.Post, on_delete: :delete_all)
    has_many(:comments, Shlinkedin.Timeline.Comment, on_delete: :delete_all)

    has_many(:friends, Shlinkedin.Profiles.Friend,
      foreign_key: :from_profile_id,
      on_delete: :delete_all
    )

    has_many(:endorsements, Shlinkedin.Profiles.Endorsement,
      foreign_key: :from_profile_id,
      on_delete: :delete_all
    )

    field(:life_score, :string, default: "B+")
    field(:points, Money.Ecto.Amount.Type, default: Money.new(100, :SHLINK))

    field(:publish_profile_picture, :boolean, virtual: true)

    field(:last_checked_notifications, :naive_datetime)

    field(:featured, :boolean, default: false)
    field(:featured_date, :naive_datetime)

    field(:verified, :boolean, default: false)
    field(:verified_date, :naive_datetime)

    has_many(:awards, Shlinkedin.Profiles.Award, on_delete: :nilify_all)

    field(:private_mode, :boolean, default: false)
    field(:verificado, :boolean, default: false)
    field(:ad_frequency, :integer, default: 3)

    has_many(:conversation_members, Shlinkedin.Chat.ConversationMember)
    has_many(:conversations, through: [:conversation_members, :conversation])

    field(:show_levels, :boolean, default: true)
    field(:feed_type, :string, default: "featured")
    field(:feed_time, :string, default: "week")
    field(:headline_type, :string, default: "reactions")
    field(:headline_time, :string, default: "week")

    field(:joined_discord, :boolean, default: false)
    field(:show_sold_ads, :boolean, default: false)
    field(:spotify_song_url, :string)
    field :resume_link, :string
    field :confetti_emoji, :string
    field :work_streak, :integer, default: 0
    field :has_sent_one_shlink, :boolean, default: false
    timestamps()
  end

  @doc false
  def changeset(profile, attrs) do
    profile
    |> cast(attrs, [
      :admin,
      :username,
      :user_id,
      :slug,
      :verificado,
      :persona_name,
      :persona_title,
      :summary,
      :photo_url,
      :cover_photo_url,
      :life_score,
      :verified,
      :verified_date,
      :featured,
      :featured_date,
      :private_mode,
      :ad_frequency,
      :unsubscribed,
      :points,
      :show_levels,
      :feed_type,
      :feed_time,
      :headline_type,
      :headline_time,
      :joined_discord,
      :show_sold_ads,
      :spotify_song_url,
      :resume_link,
      :confetti_emoji,
      :work_streak,
      :has_sent_one_shlink,
      :interns,
      :intern_names
    ])
    |> validate_required([:persona_name, :slug, :username])
    |> downcase_username()
    |> validate_username()
    |> unique_constraint([:username])
    |> validate_length(:persona_name, min: 1, max: 80)
    |> validate_length(:persona_title, min: 3, max: 200)
    |> validate_length(:summary, max: 500)
    |> validate_length(:life_score, max: 7)
    |> validate_number(:ad_frequency, greater_than: 0)
    |> validate_length(:confetti_emoji, max: 10)
    |> validate_slug()
  end

  defp downcase_username(changeset) do
    update_change(changeset, :username, &String.downcase/1)
  end

  defp validate_username(changeset) do
    changeset
    |> validate_format(:username, @username_regex,
      message: "Nome invalido , não pode usar esses caracteres!"
    )
    |> validate_length(:username, min: 3, max: 15)
    |> unique_constraint([:username])
  end

  defp validate_slug(changeset) do
    changeset
    |> validate_format(:slug, @username_regex, message: "invalid url -- não especial characters!")
    |> validate_length(:slug, min: 3, max: 15)
    |> unique_constraint([:slug])
  end
end
