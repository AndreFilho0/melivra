defmodule ShlinkedinWeb.UserSessionController do
  use ShlinkedinWeb, :controller

  alias Shlinkedin.Accounts
  alias ShlinkedinWeb.UserAuth

  def new(conn, _params) do
    render(conn, "new.html", error_message: nil)
  end

  def create(conn, %{"user" => user_params}) do
    %{"email" => email, "password" => password} = user_params

    if user = Accounts.get_user_by_email_and_password(email, password) do
      UserAuth.log_in_user(conn, user, user_params)
    else
      render(conn, "new.html", error_message: "Senha ou Email invalido")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Sucesso")
    |> UserAuth.log_out_user()
  end
end
