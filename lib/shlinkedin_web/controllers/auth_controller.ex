defmodule ShlinkedinWeb.AuthController do
  use ShlinkedinWeb, :controller
  plug Ueberauth
  alias Shlinkedin.Accounts
  alias ShlinkedinWeb.UserAuth

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    email = auth.info.email
    name = auth.info.name || "Google User"

    case Accounts.get_user_by_email(email) do
      nil ->
        # Usuário ainda não existe, vamos criar via register_user/1
        user_params = %{
          "email" => email,
          # senha fake segura
          "password" => :crypto.strong_rand_bytes(16) |> Base.encode64(),
          "name" => name
        }

        case Accounts.register_user(user_params) do
          {:ok, user} ->
            # Confirmar automaticamente se desejar
            UserAuth.log_in_user(conn, user)

          {:error, changeset} ->
            conn
            |> put_flash(:error, "Não foi possível criar sua conta com o Google")
            |> redirect(to: Routes.user_registration_path(conn, :new))
        end

      user ->
        # Usuário já existe, faz login normal
        UserAuth.log_in_user(conn, user)
    end
  end

  def callback(%{assigns: %{ueberauth_failure: _fails}} = conn, _params) do
    conn
    |> put_flash(:error, "Autenticação com o Google falhou.")
    |> redirect(to: Routes.user_session_path(conn, :new))
  end
end
