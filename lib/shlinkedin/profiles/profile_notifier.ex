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
      action:
        "devorou seu estagiário, #{name}. Sentimos muito pela sua perda (de mão de obra barata).",
      body:
        "Parece que alguém não leu o manual de sobrevivência na selva acadêmica. Fique de olho nos seus próximos estagiários!"
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
      action: "decidiu te dar um #{action.action} na sua propaganda. ",
      body:
        "Motivo: #{action.reason}. Não se sinta mal! O humor às vezes exige correr alguns riscos (e ser moderado por isso) :)"
    }
    |> Profiles.create_notification()
  end

  defp _notify(:moderated_post, from, to, action) do
    %Notification{
      from_profile_id: from.id,
      to_profile_id: to.id,
      type: "like",
      post_id: action.post_id,
      action: "decidiu te dar um #{action.action} na sua publicação. ",
      body:
        "Motivo: #{action.reason}. Não se sinta mal! O humor às vezes exige correr alguns riscos (e ser moderado por isso) :)"
    }
    |> Profiles.create_notification()
  end

  defp _notify(:moderated_commment, from, to, action) do
    %Notification{
      from_profile_id: from.id,
      to_profile_id: to.id,
      type: "like",
      post_id: action.post_id,
      action: "decidiu te dar um #{action.action} no seu comentário. ",
      body:
        "Motivo: #{action.reason}. Não se sinta mal! O humor às vezes exige correr alguns riscos (e ser moderado por isso) :)"
    }
    |> Profiles.create_notification()
  end

  defp _notify(:moderated_article, from, to, action) do
    %Notification{
      from_profile_id: from.id,
      to_profile_id: to.id,
      type: "vote",
      post_id: action.post_id,
      action: "decidiu te dar um #{action.action} na sua manchete. ",
      body:
        "Motivo: #{action.reason}. Não se sinta mal! O humor às vezes exige correr alguns riscos (e ser moderado por isso) :)"
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
      action:
        "#{from_profile.persona_name} comprou sua propaganda para '#{ad.product}' por #{transaction.amount} pontos. Que pechincha!",
      body:
        "Seu produto é tão bom que até o pessoal do Melivra quer um pedaço! Continue assim, empreendedor!"
    })

    if to_profile.unsubscribed == false and from_profile.id != to_profile.id do
      ranking = Shlinkedin.Profiles.get_ranking(to_profile, 100_000, "Wealth")

      body = """
      Olá, #{to_profile.persona_name},

      Temos uma notícia que vale ouro (ou melhor, pontos)!

      #{from_profile.persona_name} acabou de comprar sua propaganda para '#{ad.product}' por #{transaction.amount} pontos.
      Isso que é ter visão de mercado!

      Continue faturando no Melivra!

      Obrigado, <br/> Melivra team
      """

      Shlinkedin.Email.new_email(
        to_profile.user.email,
        "Você fez uma venda no Melivra!",
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
      action: "Convidou você para: #{group.title}. Prepare-se para o networking!",
      body: "Mais um grupo para chamar de seu! Quem sabe você não encontra seu próximo TCC aqui?"
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
      action: "te deu um 'jab' de negócios! Hora de revidar!",
      body:
        "Obtenha alguma vingança corporativa e ataque-os de volta (com um 'jab' ainda melhor, claro)!"
    })

    if to_profile.unsubscribed == false do
      Shlinkedin.Email.new_email(
        to_profile.user.email,
        "#{from_profile.persona_name} te deu um 'jab'!",
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
      action: "te enviou #{transaction.amount} pontos. É a sua mesada do Melivra!",
      body: "Recado: #{transaction.note}. Use com sabedoria (ou gaste tudo em café)!"
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
      action: "começou a te seguir. Mais um fã na sua lista!",
      body: "Seu relacionamento está crescendo! Prepare-se para a fama acadêmica."
    })

    body = """

    Oi #{to_profile.persona_name},

    <br/>
    <br/>

    <p>Seu relacionamento está crescendo!</p>

    <p><a href="https://melivra.com/sh/#{from_profile.slug}">#{from_profile.persona_name}</a> seguiu você.

    </p>




    <br/>
    <br/>
    Obrigado , <br/> Melivra team

    """

    if to_profile.unsubscribed == false do
      Shlinkedin.Email.new_email(
        to_profile.user.email,
        "#{from_profile.persona_name} seguiu você!",
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
      action: "te enviou um pedido de amizade! É hora de expandir sua rede (ou não).",
      body: "Alguém quer ser seu 'contato' no Melivra. O que você vai fazer?"
    })

    body = """

    Oi #{to_profile.persona_name},

    <br/>
    <br/>

    <p> #{from_profile.persona_name}
    <a href="https://melivra.com/shlinks">aqui.</a>

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
        "#{from_profile.persona_name} te enviou um pedido de amizade!",
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
        "Onde você se vê daqui a 100 anos?"
      ]
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

    <p>Parabéns! #{to_profile.persona_name} #{Points.get_rule_amount(type)}. :</p>

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
      action:
        "aceitou seu pedido de amizade! +#{Points.get_rule_amount(type)} pontos para a sua rede!",
      body:
        "Sua rede de contatos acadêmicos está crescendo! Quem diria que fazer amigos daria pontos?"
    })

    if from_profile.unsubscribed == false do
      Shlinkedin.Email.new_email(
        from_profile.user.email,
        "#{to_profile.persona_name} aceitou seu pedido de amizade!",
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

    Parabéns #{to_profile.persona_name},

    <br/>
    <br/>

    <a href="https://melivra.com/sh/#{from_profile.slug}">#{from_profile.persona_name}</a> te endossou para "#{endorsement.body}"! Sua recompensa é de +#{Points.get_rule_amount(type)} pontos.

    <br/>
    <br/>
    Obrigado , <br/> Melivra team

    """

    if from_profile.id != to_profile.id do
      Shlinkedin.Profiles.create_notification(%Notification{
        from_profile_id: from_profile.id,
        to_profile_id: to_profile.id,
        type: "endorsement",
        action: "te endossou para",
        body:
          "#{endorsement.body}. +#{Points.get_rule_amount(type)} pontos. Alguém reconhece seu talento!"
      })

      if to_profile.unsubscribed == false do
        Shlinkedin.Email.new_email(to_profile.user.email, "Você foi endossado no Melivra!", body)
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
        action: "escreveu uma avaliação para você: ",
        body: "#{testimonial.body}. Parece que você é uma estrela!"
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
        action:
          "reagiu \"#{like.like_type}\" à sua publicação. +#{Points.get_rule_amount(type)} pontos. Alguém gostou do seu post!"
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
        action:
          get_ad_like_text(like) <>
            " +#{Points.get_rule_amount(type)} pontos. Seu anúncio está bombando!"
      })
    end

    if to_profile.unsubscribed == false and from_profile.id != to_profile.id do
      ad = Shlinkedin.Ads.get_ad!(like.ad_id)
      ranking = Shlinkedin.Profiles.get_ranking(to_profile, 100_000, "Wealth")

      body = """

      Olá #{to_profile.persona_name}.

      #{if like.like_type == "buy",
        do: "Temos ótimas notícias para sua empresa, '#{ad.company}'.",
        else: "Os tempos estão difíceis para sua empresa de fachada, '#{ad.company}'."}

      <br/>
      <br/>

      #{from_profile.persona_name}

      <a href="https://melivra.com/ads/#{ad.id}">#{get_ad_like_text(like)}</a>. Sua recompensa é de +#{Points.get_rule_amount(type)} pontos!

      <br/>
      <br/>
      Acredite ou não, você agora é a <a href="https://melivra.com/leaders?curr_category=Wealth">#{Ordinal.ordinalize(ranking)}</a> pessoa mais rica no Melivra.

      <br/>
      <br/>
      Obrigado, <br/>
      Melivra

      """

      Shlinkedin.Email.new_email(
        to_profile.user.email,
        "#{if like.like_type == "buy",
          do: "Você fez uma venda!",
          else: "Ops. Você foi processado por #{from_profile.persona_name}"}",
        body
      )
      |> Shlinkedin.Mailer.deliver_later()
    end
  end

  defp get_ad_like_text(%AdLike{} = like) do
    ad = Shlinkedin.Ads.get_ad!(like.ad_id)

    case like.like_type do
      "buy" -> "comprou 1 dos seus produtos: '#{ad.product}'"
      "sue" -> "processou sua empresa, '#{ad.company}'"
      _ -> "clicou em #{like.like_type} no seu anúncio"
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
        action:
          "reagiu \"#{like.like_type}\" ao seu comentário. +#{Points.get_rule_amount(type)} pontos. Seu comentário fez sucesso!"
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
        action:
          "aplaudiu sua manchete, \"#{article.headline}\" +#{Points.get_rule_amount(type)} pontos. Sua notícia é um sucesso!"
      })
    end
  end

  def notify_post_featured(%Profile{} = to_profile, %Post{} = post, type) do
    body = """
    Olá #{to_profile.persona_name},

    Temos uma notícia de capa para você!

    Sua publicação foi destacada no Melivra. Isso significa mais visibilidade para suas ideias geniais!

    Continue compartilhando seu conhecimento e humor com a comunidade.

    Obrigado, <br/> Melivra team
    """

    Shlinkedin.Profiles.create_notification(%Notification{
      from_profile_id: 3,
      to_profile_id: to_profile.id,
      type: "featured",
      post_id: post.id,
      action:
        "decidiu destacar sua publicação! +#{Points.get_rule_amount(type)} pontos. Você está no topo!"
    })

    if to_profile.unsubscribed == false do
      Shlinkedin.Email.new_email(
        to_profile.user.email,
        "Sua publicação foi destacada no Melivra!",
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
    Parabéns! <br/>
    Melivra

    """

    Shlinkedin.Profiles.create_notification(%Notification{
      from_profile_id: Profiles.get_god().id,
      to_profile_id: to_profile.id,
      type: "new_badge",
      action:
        "te concedeu o distintivo #{award_type.name}! Ele foi adicionado à sua coleção de troféus. Que chique!"
    })

    if to_profile.unsubscribed == false do
      Shlinkedin.Email.new_email(
        to_profile.user.email,
        "Você ganhou um prêmio no Melivra!",
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
    #{from_name} te marcou em uma
     <a href="https://melivra.com/posts/#{id}">#{tag_parent}.</a>
     Confira, e vamos manter nossas métricas de engajamento lá em cima!
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
        action: "te marcou: ",
        body: "#{post.body}. Alguém quer sua atenção (ou sua opinião genial)!"
      })

      if to_profile.unsubscribed == false do
        Shlinkedin.Email.new_email(
          to_profile.user.email,
          "#{from_profile.persona_name} te marcou em um comentário",
          tag_email_body(
            to_profile.persona_name,
            from_profile.persona_name,
            post.id,
            "publicação"
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
        action: "te marcou em um comentário: ",
        body: "#{comment.body}. Sua presença é requisitada!"
      })
    end

    if from_profile.id != to_profile.id do
      Shlinkedin.Profiles.create_notification(%Notification{
        from_profile_id: from_profile.id,
        to_profile_id: to_profile.id,
        type: "comment",
        post_id: comment.post_id,
        action: "comentou na sua publicação: ",
        body: "#{comment.body}. Alguém tem algo a dizer sobre o que você postou!"
      })
    end
  end
end
