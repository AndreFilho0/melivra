defmodule ShlinkedinWeb.ProfessorsLive.ModalUploadProvaAntiga do
  use ShlinkedinWeb, :live_component

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)

    {:ok, socket}
  end
end
