defmodule ShlinkedinWeb.ProvaPdfController do
  use ShlinkedinWeb, :controller
  require IEx
  alias Shlinkedin.Provas

  def show(conn, %{"file_key" => file_key}) do
    file_key = Enum.join(file_key, "/")

    case Provas.generate_presigned_url("melivra", file_key) do
      nil ->
        send_resp(conn, 404, "PDF não encontrado")

      signed_url ->
        case HTTPoison.get(signed_url) do
          {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
            conn
            |> put_resp_header("Content-Type", "application/pdf")
            |> put_resp_header("Content-Disposition", "inline; filename=\"documento.pdf\"")
            |> send_resp(200, body)

          _ ->
            send_resp(conn, 500, "Erro ao buscar PDF")
        end
    end
  end
end
