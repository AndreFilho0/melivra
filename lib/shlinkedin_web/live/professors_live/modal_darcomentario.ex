defmodule ShlinkedinWeb.ProfessorsLive.ModalDarcomentario do
  use ShlinkedinWeb, :live_component

  def render(assigns) do
    ~L"""
    <div id="rating-modal" class="fixed inset-0 flex items-center justify-center bg-black bg-opacity-50">
      <div class="bg-white p-6 rounded-lg shadow-lg w-96">
        <h2 class="text-xl font-bold mb-2">Deixe um comentário para <%= @professor %></h2>
        <p class="text-gray-600 mb-4">Instituição: <%= @instituto %></p>

        <%= form_for :rating, "#", [phx_submit: :dar_comentario], fn f -> %>
          <%= number_input f, :nota, min: 1, max: 10, value: @nota, class: "w-full p-2 border rounded-lg mb-4", placeholder: "Nota (1-10)"  %>
          
          <%= textarea f, :comentario, class: "w-full p-2 border rounded-lg mb-4", placeholder: "Ex: Fiz Cálculo 1A ou Química Orgânica com ele. Foi uma ótima experiência!" %>
          
          <div class="flex justify-end space-x-2">
            <button phx-click="close_modal_comentario" class="px-4 py-2 bg-gray-300 rounded-lg">Cancelar</button>
            <button type="submit" class="px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600">Enviar</button>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
