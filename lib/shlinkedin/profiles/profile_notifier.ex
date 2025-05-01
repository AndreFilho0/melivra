defmodule Shlinkedin.Profiles.ProfileNotifier do
  alias Shlinkedin.Profiles.{Profile, Endorsement, Testimonial, Notification}
  alias Shlinkedin.Profiles
  alias Shlinkedin.Timeline.{Like, Comment, Post, CommentLike}
  alias Shlinkedin.Timeline
  alias Shlinkedin.News.Vote
  alias Shlinkedin.News.Article
  alias Shlinkedin.Groups
  alias Shlinkedin.Groups.Invite
  alias Shlinkedin.Points.Transaction
  alias Shlinkedin.Points
  alias Shlinkedin.Ads.{AdLike, Ad}
  alias Shlinkedin.Ads
  alias Shlinkedin.Interns.Intern

  @doc """
  Deliver instructions to confirm account.
  """
  def observer(input, type, from \\ %Profile{}, to \\ %Profile{})
  def observer({:error, changeset}, _type, _from, _to), do: {:error, changeset}

  def observer({:ok, res}, type, %Profile{} = from, %Profile{} = to) do
    from_profile = Shlinkedin.Profiles.get_profile_by_profile_id_preload_user(from.id)
    to_profile = Shlinkedin.Profiles.get_profile_by_profile_id_preload_user(to.id)

    handle_txn(from, to, type, res)

    case(type) do
      :post ->
        notify_comment(from_profile, to_profile, res, type)

      :comment ->
        notify_comment(from_profile, to_profile, res, type)

      :like ->
        notify_like(from_profile, to_profile, res, type)

      :comment_like ->
        notify_comment_like(from_profile, to_profile, res, type)

      :vote ->
        notify_vote(from_profile, to_profile, res, type)

      :endorsement ->
        notify_endorsement(from_profile, to_profile, res, type)

      :testimonial ->
        notify_testimonial(from_profile, to_profile, res, type)

      :sent_friend_request ->
        notify_sent_friend_request(from_profile, to_profile, type)

      :accepted_friend_request ->
        notify_accepted_friend_request(from_profile, to_profile, type)

      :featured_post ->
        notify_post_featured(to_profile, res, type)

      :new_badge ->
        notify_profile_badge(to_profile, res, type)

      :jab ->
        notify_jab(from_profile, to_profile, type)

      :ad_like ->
        notify_ad_like(from_profile, to_profile, res, type)

      :sent_group_invite ->
        notify_group_invite(from_profile, to_profile, res, type)

      :sent_transaction ->
        notify_sent_points(from_profile, to_profile, res, type)

      :ad_buy ->
        notify_ad_buy(from_profile, to_profile, res, type)

      :new_follower ->
        notify_new_follower(from_profile, to_profile, type)

      :devoured_intern ->
        notify_devoured_intern(from_profile, to_profile, res, type)
    end

    {:ok, res}
  end

  def notify_devoured_intern(
        %Profile{} = from_profile,
        %Profile{} = to_profile,
        %Intern{name: name},
        _type
      ) do
    Shlinkedin.Profiles.create_notification(%Notification{
      from_profile_id: from_profile.id,
      to_profile_id: to_profile.id,
      type: "devoured_intern",
      action: "devoured your intern, #{name}. We're sorry for your loss.",
      body: ""
    })
  end

  def notify({:error, changeset}, _type, _from, _to), do: {:error, changeset}
  def notify({:ok, result}, type, from, to), do: _notify(type, from, to, result)

  defp _notify(:moderated_ad, from, to, action) do
    %Notification{
      from_profile_id: from.id,
      to_profile_id: to.id,
      type: "ad_click",
      ad_id: action.ad_id,
      action: "has decided to issue you a #{action.action} on your ad. ",
      body:
        "Reason: #{action.reason}. Don't feel bad! Humor sometimes requires taking some risks :)"
    }
    |> Profiles.create_notification()
  end

  defp _notify(:moderated_post, from, to, action) do
    %Notification{
      from_profile_id: from.id,
      to_profile_id: to.id,
      type: "like",
      post_id: action.post_id,
      action: "has decided to issue you a #{action.action} on your post. ",
      body:
        "Reason: #{action.reason}. Don't feel bad! Humor sometimes requires taking some risks :)"
    }
    |> Profiles.create_notification()
  end

  defp _notify(:moderated_commment, from, to, action) do
    %Notification{
      from_profile_id: from.id,
      to_profile_id: to.id,
      type: "like",
      post_id: action.post_id,
      action: "has decided to issue you a #{action.action} on your comment. ",
      body:
        "Reason: #{action.reason}. Don't feel bad! Humor sometimes requires taking some risks :)"
    }
    |> Profiles.create_notification()
  end

  defp _notify(:moderated_article, from, to, action) do
    %Notification{
      from_profile_id: from.id,
      to_profile_id: to.id,
      type: "vote",
      post_id: action.post_id,
      action: "has decided to issue you a #{action.action} on your headline. ",
      body:
        "Reason: #{action.reason}. Don't feel bad! Humor sometimes requires taking some risks :)"
    }
    |> Profiles.create_notification()
  end

  defp handle_txn(from, to, type, res) do
    if Map.has_key?(Points.rules(), type) do
      # can be nil
      {:ok, _txn} = Points.point_observer(from, to, type, res)
    end
  end

  def notify_ad_buy(
        %Profile{} = from_profile,
        %Profile{} = to_profile,
        %Ad{} = ad,
        _type
      ) do
    owner_record = Ads.get_owner_record(ad, from_profile)
    transaction = Points.get_transaction!(owner_record.transaction_id)

    Shlinkedin.Profiles.create_notification(%Notification{
      from_profile_id: from_profile.id,
      to_profile_id: to_profile.id,
      type: "ad_buy",
      ad_id: ad.id,
      action:
        "#{from_profile.persona_name} bought your ad for '#{ad.product}' for #{transaction.amount}"
    })

    if to_profile.unsubscribed == false and from_profile.id != to_profile.id do
      ranking = Shlinkedin.Profiles.get_ranking(to_profile, 100_000, "Wealth")

      body = """


      """

      Shlinkedin.Email.new_email(
        to_profile.user.email,
        "You made a sale!",
        body
      )
      |> Shlinkedin.Mailer.deliver_later()
    end

    {:ok, ad}
  end

  def notify_group_invite(
        %Profile{} = from_profile,
        %Profile{} = to_profile,
        %Invite{} = invite,
        _type
      ) do
    group = Groups.get_group!(invite.group_id)

    body = """

    OI #{to_profile.persona_name},

    <br/>
    <br/>

    #{from_profile.persona_name} Convidou para o #{group.privacy_type} , "#{group.title}." Para aceitar o convite você pode clicar aqui :
    <a href="https://melivra.com/groups/#{group.id}">click aqui</a>

    <br/>
    <br/>
    Obrigado , <br/> Melivra team

    """

    Shlinkedin.Profiles.create_notification(%Notification{
      from_profile_id: from_profile.id,
      to_profile_id: to_profile.id,
      group_id: group.id,
      type: "group_invite",
      action: "Convidou você para :  #{group.title}",
      body: ""
    })

    if to_profile.unsubscribed == false do
      Shlinkedin.Email.new_email(
        to_profile.user.email,
        "#{from_profile.persona_name} Convidou você para #{group.title}",
        body
      )
      |> Shlinkedin.Mailer.deliver_later()
    end
  end

  def notify_jab(
        %Profile{} = from_profile,
        %Profile{} = to_profile,
        _type
      ) do
    body = """

    Oi #{to_profile.persona_name},

    <br/>
    <br/>

    #{from_profile.persona_name}
    :  <a href="https://melivra.com/sh/#{from_profile.slug}">jab</a>

    <br/>
    <br/>
    Obrigado , <br/> Melivra team

    """

    Shlinkedin.Profiles.create_notification(%Notification{
      from_profile_id: from_profile.id,
      to_profile_id: to_profile.id,
      type: "jab",
      action: "business jabbed you!",
      body: "Obtenha alguma vingança corporativa e ataque-os de volta"
    })

    if to_profile.unsubscribed == false do
      Shlinkedin.Email.new_email(
        to_profile.user.email,
        "#{from_profile.persona_name} !",
        body
      )
      |> Shlinkedin.Mailer.deliver_later()
    end
  end

  def notify_sent_points(
        %Profile{} = from_profile,
        %Profile{} = to_profile,
        %Transaction{} = transaction,
        _type
      ) do
    body = """

    OI #{to_profile.persona_name},

    <br/>
    <br/>

    <a href="https://melivra.com/sh/#{from_profile.slug}">#{from_profile.persona_name}</a>
    mandou #{transaction.amount}! Agora você tem um novo valor de : #{to_profile.points}.

    <br/>
    <br/>
     #{transaction.note}

    <br/>
    <br/>
    Obrigado , <br/> Melivra team

    """

    Shlinkedin.Profiles.create_notification(%Notification{
      from_profile_id: from_profile.id,
      to_profile_id: to_profile.id,
      type: "sent_points",
      action: "sent you #{transaction.amount}.",
      body: "Memo: #{transaction.note}"
    })

    if to_profile.unsubscribed == false do
      Shlinkedin.Email.new_email(
        to_profile.user.email,
        "#{from_profile.persona_name} mandou pontos para você",
        body
      )
      |> Shlinkedin.Mailer.deliver_later()
    end
  end

  def notify_new_follower(
        %Profile{} = from_profile,
        %Profile{} = to_profile,
        _type
      ) do
    Shlinkedin.Profiles.create_notification(%Notification{
      from_profile_id: from_profile.id,
      to_profile_id: to_profile.id,
      type: "new_follower",
      action: "segiu você",
      body: ""
    })

    body = """

    Oi #{to_profile.persona_name},

    <br/>
    <br/>

    <p>seu relacionamento está crescendo</p>

    <p><a href="https://melivra.com/sh/#{from_profile.slug}">#{from_profile.persona_name}</a> seguiu você.

    </p>




    <br/>
    <br/>
    Obrigado , <br/> Melivra team

    """

    if to_profile.unsubscribed == false do
      Shlinkedin.Email.new_email(
        to_profile.user.email,
        "#{from_profile.persona_name} seguiu você !",
        body
      )
      |> Shlinkedin.Mailer.deliver_later()
    end
  end

  def notify_sent_friend_request(
        %Profile{} = from_profile,
        %Profile{} = to_profile,
        _type
      ) do
    Shlinkedin.Profiles.create_notification(%Notification{
      from_profile_id: from_profile.id,
      to_profile_id: to_profile.id,
      type: "pending_shlink",
      action: "has sent you a Shlink request!",
      body: ""
    })

    body = """

    Oi #{to_profile.persona_name},

    <br/>
    <br/>

    <p> #{from_profile.persona_name}
    <a href="https://melivra.com/shlinks">here.</a>

    </p>

    <ul>
    #{for line <- friend_request_text(), do: "<li>#{line}</li>"}
    </ul>



    <br/>
    <br/>
    Obrigado , <br/> Melivra team

    """

    if to_profile.unsubscribed == false do
      Shlinkedin.Email.new_email(
        to_profile.user.email,
        "#{from_profile.persona_name} has sent you a shlink request!",
        body
      )
      |> Shlinkedin.Mailer.deliver_later()
    end
  end

  defp friend_request_text() do
    [
      [
        "Qual é o segredo do seu sucesso?",
        "Quais são seus interesses acadêmicos?",
        "De quem foi a culpa?",
        "Você ainda pensa nisso?"
      ],
      [
        "Onde você se vê daqui a 100 anos?",
      ],
    ]
    |> Enum.random()
  end

  def notify_accepted_friend_request(
        %Profile{} = from_profile,
        %Profile{} = to_profile,
        type
      ) do
    body = """

    oi #{from_profile.persona_name},

    <br/>
    <br/>

    <p>Congratulations! #{to_profile.persona_name} #{Points.get_rule_amount(type)}. :</p>

    <ul>
    #{for line <- friend_request_text(), do: "<li>#{line}</li>"}
    </ul>

    <p></p>

    <br/>
    <br/>
    Obrigado , <br/> Melivra team

    """

    Shlinkedin.Profiles.create_notification(%Notification{
      from_profile_id: to_profile.id,
      to_profile_id: from_profile.id,
      type: "accepted_shlink",
      action: "has accepted your Shlink request! +#{Points.get_rule_amount(type)}",
      body: ""
    })

    if from_profile.unsubscribed == false do
      Shlinkedin.Email.new_email(
        from_profile.user.email,
        "#{to_profile.persona_name} has accepted your Shlink request!",
        body
      )
      |> Shlinkedin.Mailer.deliver_later()
    end
  end

  def notify_endorsement(
        %Profile{} = from_profile,
        %Profile{} = to_profile,
        %Endorsement{} = endorsement,
        type
      ) do
    body = """

    Congratulations #{to_profile.persona_name},

    <br/>
    <br/>

    <a href="https://melivra.com/sh/#{from_profile.slug}">#{from_profile.persona_name}</a> has endorsed you for "#{endorsement.body}"! Your reward is +#{Points.get_rule_amount(type)}.

    <br/>
    <br/>
    Obrigado , <br/> Melivra team

    """

    if from_profile.id != to_profile.id do
      Shlinkedin.Profiles.create_notification(%Notification{
        from_profile_id: from_profile.id,
        to_profile_id: to_profile.id,
        type: "endorsement",
        action: "endorsed you for",
        body: "#{endorsement.body}. +#{Points.get_rule_amount(type)}"
      })

      if to_profile.unsubscribed == false do
        Shlinkedin.Email.new_email(to_profile.user.email, "You've been endorsed!", body)
        |> Shlinkedin.Mailer.deliver_later()
      end
    end
  end

  def notify_testimonial(
        %Profile{} = from_profile,
        %Profile{} = to_profile,
        %Testimonial{} = testimonial,
        type
      ) do
    body = """

    Uau, #{to_profile.persona_name},

    <br/>
    <br/>

    <a href="https://melivra.com/sh/#{from_profile.slug}">#{from_profile.persona_name}</a> escreveu uma avaliação de #{testimonial.rating}/5 estrelas para você. Confira
    <a href="https://melivra.com/sh/#{to_profile.slug}">no seu perfil.</a>. Sua recompensa é de +#{Points.get_rule_amount(type)}

    <br/>
    <br/>
    Obrigado, <br/>
    Time do Melivra

    """

    if from_profile.id != to_profile.id do
      Shlinkedin.Profiles.create_notification(%Notification{
        from_profile_id: from_profile.id,
        to_profile_id: to_profile.id,
        type: "testimonial",
        action: "wrote you a review: ",
        body: "#{testimonial.body}"
      })

      if to_profile.unsubscribed == false do
        Shlinkedin.Email.new_email(
          to_profile.user.email,
          "#{from_profile.persona_name} deu a você #{testimonial.rating}/5 estrelas! +#{Points.get_rule_amount(type)}",
          body
        )
        |> Shlinkedin.Mailer.deliver_later()
      end
    end
  end

  def notify_like(
        %Profile{} = from_profile,
        %Profile{} = to_profile,
        %Like{} = like,
        type
      ) do
    # todo: get notification where to_profile is same and post id is same,
    # and then update action to "and [] also did."
    if from_profile.id != to_profile.id and
         Shlinkedin.Timeline.is_first_like_on_post?(from_profile, %Post{id: like.post_id}) do
      Shlinkedin.Profiles.create_notification(%Notification{
        from_profile_id: from_profile.id,
        to_profile_id: to_profile.id,
        type: "like",
        post_id: like.post_id,
        action: "reacted \"#{like.like_type}\" to your post. +#{Points.get_rule_amount(type)}"
      })
    end
  end

  def notify_ad_like(
        %Profile{} = from_profile,
        %Profile{} = to_profile,
        %AdLike{} = like,
        type
      ) do
    # todo: get notification where to_profile is same and post id is same,
    # and then update action to "and [] also did."
    if from_profile.id != to_profile.id do
      Shlinkedin.Profiles.create_notification(%Notification{
        from_profile_id: from_profile.id,
        to_profile_id: to_profile.id,
        type: "ad_like",
        ad_id: like.ad_id,
        action: get_ad_like_text(like) <> " +#{Points.get_rule_amount(type)}"
      })
    end

    if to_profile.unsubscribed == false and from_profile.id != to_profile.id do
      ad = Shlinkedin.Ads.get_ad!(like.ad_id)
      ranking = Shlinkedin.Profiles.get_ranking(to_profile, 100_000, "Wealth")

      body = """

      Hi #{to_profile.persona_name}.

      #{if like.like_type == "buy",
        do: "We have great news for your company, '#{ad.company}'.",
        else: "Times are tough at your shell company, '#{ad.company}'."}

      <br/>
      <br/>

      #{from_profile.persona_name} has

      <a href="https://melivra.com/ads/#{ad.id}">#{get_ad_like_text(like)}</a>. Your reward is +#{Points.get_rule_amount(type)}!

      <br/>
      <br/>
      Believe it or not, with you now are the <a href="https://melivra.com/leaders?curr_category=Wealth">#{Ordinal.ordinalize(ranking)}</a> wealthiest person on ShlinkedIn.

      <br/>
      <br/>
      Thanks, <br/>
      melivra

      """

      Shlinkedin.Email.new_email(
        to_profile.user.email,
        "#{if like.like_type == "buy",
          do: "You made a sale!",
          else: "Uh oh. You've been sued by #{from_profile.persona_name}"}",
        body
      )
      |> Shlinkedin.Mailer.deliver_later()
    end
  end

  defp get_ad_like_text(%AdLike{} = like) do
    ad = Shlinkedin.Ads.get_ad!(like.ad_id)

    case like.like_type do
      "buy" -> "bought 1 of your products: '#{ad.product}'"
      "sue" -> "sued your company, '#{ad.company}'"
      _ -> "clicked #{like.like_type} on your ad"
    end
  end

  def notify_comment_like(
        %Profile{} = from_profile,
        %Profile{} = to_profile,
        %CommentLike{} = like,
        type
      ) do
    # get notification where to_profile is same and post id is same,
    # and then update action to "and [] also did."
    # could be optimized by one query
    comment = Timeline.get_comment!(like.comment_id)
    post = Timeline.get_post!(comment.post_id)

    if from_profile.id != to_profile.id and
         Shlinkedin.Timeline.is_first_like_on_comment?(from_profile, %Comment{id: like.comment_id}) do
      Shlinkedin.Profiles.create_notification(%Notification{
        from_profile_id: from_profile.id,
        to_profile_id: to_profile.id,
        type: "like",
        post_id: post.id,
        action: "reacted \"#{like.like_type}\" to your comment. +#{Points.get_rule_amount(type)}"
      })
    end
  end

  def notify_vote(
        %Profile{} = from_profile,
        %Profile{} = to_profile,
        %Vote{} = vote,
        type
      ) do
    # get notification where to_profile is same and post id is same,
    # and then update action to "and [] also did."
    if from_profile.id != to_profile.id and
         Shlinkedin.News.is_first_vote_on_article?(from_profile, %Article{id: vote.article_id}) do
      article = Shlinkedin.News.get_article!(vote.article_id)

      Shlinkedin.Profiles.create_notification(%Notification{
        from_profile_id: from_profile.id,
        to_profile_id: to_profile.id,
        type: "vote",
        article_id: vote.article_id,
        action: "clapped your headline, \"#{article.headline}\" +#{Points.get_rule_amount(type)}"
      })
    end
  end

  def notify_post_featured(%Profile{} = to_profile, %Post{} = post, type) do
    body = """



    """

    Shlinkedin.Profiles.create_notification(%Notification{
      from_profile_id: 3,
      to_profile_id: to_profile.id,
      type: "featured",
      post_id: post.id,
      action: "has decided to featured your post! +#{Points.get_rule_amount(type)}."
    })

    if to_profile.unsubscribed == false do
      Shlinkedin.Email.new_email(
        to_profile.user.email,
        "Your post was featured!",
        body
      )
      |> Shlinkedin.Mailer.deliver_later()
    end
  end

  def notify_profile_badge(%Profile{} = to_profile, %Profiles.Award{award_id: award_id}, _type) do
    award_type = Shlinkedin.Awards.get_award_type!(award_id)

    body = """

    Oi #{to_profile.persona_name},

    <br/>
    <br/>

    Você foi premiado com o #{award_type.name}

    <br/>
    <br/>
    Congrats! <br/>
    melivra

    """

    Shlinkedin.Profiles.create_notification(%Notification{
      from_profile_id: Profiles.get_god().id,
      to_profile_id: to_profile.id,
      type: "new_badge",
      action: "has awarded you the #{award_type.name} badge! It's been added to your trophy case."
    })

    if to_profile.unsubscribed == false do
      Shlinkedin.Email.new_email(
        to_profile.user.email,
        "You got an award!",
        body
      )
      |> Shlinkedin.Mailer.deliver_later()
    end
  end

  defp tag_email_body(to_name, from_name, id, tag_parent) do
    """
    OI #{to_name},
    <br/>
    <br/>
    #{from_name} has tagged you in a
     <a href="https://melivra.com/posts/#{id}">#{tag_parent}.</a>
     Check it out, and keep our engagement metrics high!
    <br/>
    <br/>
    Obrigado , <br/> Melivra team
    """
  end

  def notify_post(
        %Profile{} = from_profile,
        %Profile{} = _to_profile,
        %Post{} = post,
        _type
      ) do
    for username <- post.profile_tags do
      to_profile = Shlinkedin.Profiles.get_profile_by_username(username)

      Shlinkedin.Profiles.create_notification(%Notification{
        from_profile_id: from_profile.id,
        to_profile_id: to_profile.id,
        type: "post_tag",
        post_id: post.id,
        action: "tagged you: ",
        body: "#{post.body}"
      })

      if to_profile.unsubscribed == false do
        Shlinkedin.Email.new_email(
          to_profile.user.email,
          "#{from_profile.persona_name} tagged you in a comment",
          tag_email_body(
            to_profile.persona_name,
            from_profile.persona_name,
            post.id,
            "post"
          )
        )
        |> Shlinkedin.Mailer.deliver_later()
      end
    end
  end

  def notify_comment(
        %Profile{} = from_profile,
        %Profile{} = to_profile,
        %Comment{} = comment,
        _type
      ) do
    for username <- comment.profile_tags do
      to_profile = Shlinkedin.Profiles.get_profile_by_username(username)

      Shlinkedin.Profiles.create_notification(%Notification{
        from_profile_id: from_profile.id,
        to_profile_id: to_profile.id,
        type: "comment",
        post_id: comment.post_id,
        action: "tagged you in a comment: ",
        body: "#{comment.body}"
      })
    end

    if from_profile.id != to_profile.id do
      Shlinkedin.Profiles.create_notification(%Notification{
        from_profile_id: from_profile.id,
        to_profile_id: to_profile.id,
        type: "comment",
        post_id: comment.post_id,
        action: "commented on your post: ",
        body: "#{comment.body}"
      })
    end
  end
end
