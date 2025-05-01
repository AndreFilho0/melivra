defmodule Shlinkedin.Accounts.UserNotifier do
  # For simplicity, this module simply logs messages to the terminal.
  # You should replace it by a proper email or notification tool, such as:
  #
  #   * Swoosh - https://hexdocs.pm/swoosh
  #   * Bamboo - https://hexdocs.pm/bamboo
  #

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_confirmation_instructions(user, url) do
    body = """
    <!DOCTYPE html>
    <html lang="pt-BR">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Confirmação de E-mail</title>
      <style>
        /* Estilos globais */
        body {
          font-family: Arial, sans-serif;
          background-color: #f4f4f4;
          margin: 0;
          padding: 0;
        }
        .container {
          max-width: 600px;
          margin: 0 auto;
          padding: 20px;
          background-color: #ffffff;
          border-radius: 8px;
          box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }
        h1 {
          color: #333333;
          font-size: 24px;
          text-align: center;
          margin-bottom: 20px;
        }
        p {
          color: #555555;
          font-size: 16px;
          line-height: 1.5;
          margin-bottom: 20px;
        }
        .button {
          display: block;
          width: 200px;
          margin: 0 auto;
          padding: 12px 20px;
          font-size: 16px;
          font-weight: bold;
          color: #ffffff;
          background-color: #007BFF;
          text-align: center;
          text-decoration: none;
          border-radius: 5px;
        }
        .footer {
          text-align: center;
          margin-top: 30px;
          color: #777777;
          font-size: 14px;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <h1>Bem-vindo(a) ao MeLivra! 🚀</h1>
        <p>Olá #{user.email},</p>
        <p>Estamos muito felizes por você ter se juntado à nossa comunidade. Para começar a usar sua conta e aproveitar todos os benefícios, confirme seu e-mail clicando no botão abaixo:</p>
        <a href="#{url}" class="button">Confirmar E-mail</a>
        <p>Se o botão acima não funcionar, copie e cole o link abaixo no seu navegador:</p>
        <p style="text-align: center; word-break: break-all; color: #007BFF;">#{url}</p>
        <p>Se tiver alguma dúvida ou precisar de ajuda, nossa equipe está à disposição. Basta responder a este e-mail ou entrar em contato conosco.</p>
        <div class="footer">
          <p>Atenciosamente,</p>
          <p>Equipe MeLivra 🚀</p>
        </div>
      </div>
    </body>
    </html>
    """

    Shlinkedin.Email.user_email(user.email, "Confirme sua conta no MeLivra", body)
    |> Shlinkedin.Mailer.deliver_later()

    {:ok, %{to: user.email, body: body}}
  end

  @doc """
  Deliver instructions to reset a user password.
  """
  def deliver_reset_password_instructions(user, url) do
    body = """
    <html>
    <body style="font-family: Arial, sans-serif; padding: 20px; background-color: #f4f4f4;">
      <div style="background-color: #ffffff; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
        <h2 style="color: #333333;">Oi #{user.email},</h2>
        <p style="color: #555555;">Você pode mudar sua senha com o link abaixo:</p>
        <a href="#{url}" style="display: inline-block; background-color: #007BFF; color: #ffffff; padding: 12px 20px; text-decoration: none; border-radius: 5px; margin-top: 10px;">Mudar Senha</a>
        <p style="color: #777777; margin-top: 20px;">Se você não solicitou essa mudança, ignore este e-mail.</p>
      </div>
    </body>
    </html>

    """

    Shlinkedin.Email.user_email(user.email, "Mudar Senha :", body)
    |> Shlinkedin.Mailer.deliver_later()

    {:ok, %{to: user.email, body: body}}
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(user, url) do
    body = """


    Oi #{user.email},

    você pode mudar seu email com o link abaixo: 
    #{url}


    """

    Shlinkedin.Email.user_email(user.email, "Update Email", body)
    |> Shlinkedin.Mailer.deliver_later()

    {:ok, %{to: user.email, body: body}}
  end
end
