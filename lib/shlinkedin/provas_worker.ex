defmodule Shlinkedin.ProvasWorker do
  use Oban.Worker, queue: :provas, max_attempts: 2

  alias Shlinkedin.Provas
  require Logger

  @bucket "melivra"

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"prova_id" => prova_id}}) do
    with {:ok, prova} <- Provas.get_prova_antiga(prova_id),
         {:ok, _result} <- Provas.processar_prova_antiga(prova, @bucket) do
      :ok
    else
      {:error, reason} ->
        Logger.error("Erro ao processar prova #{prova_id}: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
