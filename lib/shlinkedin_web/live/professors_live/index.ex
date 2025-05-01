defmodule ShlinkedinWeb.ProfessorsLive.Index do
alias Shlinkedin.Professors
  use ShlinkedinWeb, :live_view
  alias Shlinkedin.Professors

  def mount(_arga, session, socket) do
    institutos = [
      "CEPAE",
      "EA",
      "EECA",
      "EMC",
      "EMAC",
      "EVZ",
      "FACE",
      "FIC",
      "FAFIL",
      "FANUT",
      "FAV",
      "FCS",
      "FD",
      "FE",
      "FEFD",
      "FEN",
      "FF",
      "FH",
      "FL",
      "FM",
      "FO",
      "ICB",
      "IESA",
      "IF",
      "IME",
      "INF",
      "IPTSP",
      "IQ",
      "FCT"
    ]

    {:ok,
     socket
     |> assign(:institutos, institutos)
     |> assign(:professores_instituto, [])
    }
  end


  @impl Phoenix.LiveView
  def handle_event("institute_selected", unsigned_params, socket) do
    institute = Map.get(unsigned_params, "institute")
    professores_instituto = Professors.search_professors_instituto(institute)


    {:noreply,
     socket
     |> assign(:professores_instituto, professores_instituto)}

  end

  @impl Phoenix.LiveView
def handle_event("search", %{"institute" => instituto, "professor" => professor}, socket) do
  if instituto == "" or professor == "" do
    

    {:noreply,
      push_redirect(socket,
        to: Routes.professors_index_path(socket, :index)
      )}
  else
    {:noreply,
      push_redirect(socket,
        to: Routes.professors_show_path(socket, :show, professor, instituto)
      )}
  end
end



end
