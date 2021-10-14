defmodule ChWeb.ChessLive do
  # If you generated an app with mix phx.new --live,
  # the line below would be: use MyAppWeb, :live_view
  use Phoenix.LiveView

  def render(assigns) do
    indexed =
      assigns.game.board.pieces
      |> Enum.map(fn piece ->
        xy = Chess.Position.to_xy(piece.position)
        {xy, piece}
      end)
      |> Enum.into(%{})

    ~H"""
    <div><%= "To move: #{@to_move}" %></div>
    <div><%= "Selected: #{@position_string}" %></div>
    <div><%= "Possible moves: #{inspect(@moves)}" %></div>

    <table>
    <%= for row <- 7..0 do %>
      <tr>
      <%= for column <- 0..7 do %>
      <%
        style =
          cond do
            {column, row} in @moves -> "background-color: red;"
            Kernel.rem(column + row, 2) == 0 -> "background-color: gray;"
            true -> ""
          end
      %>

        <td phx-click={"position-#{column}-#{row}"} style={ style }>
          <%=
            case Map.fetch(indexed, {column, row}) do
              {:ok, piece} ->
                Chess.Piece.to_string(piece)

              :error ->
                # blank square unicode hack
                "\u3000"
            end
          %>
        </td>
      <% end %>
      </tr>
    <% end %>
    </table>
    """
  end

  def handle_event(
        <<"position-", column::bytes-size(1), "-", row::bytes-size(1)>>,
        _unsigned_params,
        socket
      ) do
    {column, ""} = Integer.parse(column, 10)
    {row, ""} = Integer.parse(row, 10)
    this_selection = {column, row}

    previous_selection = socket.assigns.selected_position

    if previous_selection do
      if previous_selection == this_selection || this_selection not in socket.assigns.moves do
        socket =
          assign(socket,
            moves: [],
            selected_position: nil,
            position_string: ""
          )

        {:noreply, socket}
      else
        if this_selection in socket.assigns.moves do
          game =
            Chess.Game.move(
              socket.assigns.game,
              Chess.Position.from(previous_selection),
              Chess.Position.from(this_selection)
            )

          socket =
            assign(socket,
              game: game,
              moves: [],
              selected_position: nil,
              position_string: ""
            )

          {:noreply, socket}
        else
          {:noreply, socket}
        end
      end
    else
      piece_at_position =
        Enum.find(socket.assigns.game.board.pieces, fn piece ->
          position = Chess.Piece.position(piece)
          Chess.Position.to_xy(position) == this_selection
        end)

      moves =
        if piece_at_position do
          Chess.Piece.moves(piece_at_position, socket.assigns.game.board)
          |> Enum.map(&Chess.Position.to_xy(&1))
        else
          []
        end

      selected_position = this_selection
      position_string = "#{inspect(this_selection)}"

      socket =
        assign(socket,
          moves: moves,
          selected_position: selected_position,
          position_string: position_string
        )

      {:noreply, socket}
    end
  end

  def mount(_params, %{}, socket) do
    # temperature = Thermostat.get_user_reading(user_id)
    game = Chess.Game.new()
    to_move = game.to_move

    {:ok,
     assign(socket,
       game: game,
       to_move: to_move,
       moves: [],
       selected_position: nil,
       position_string: ""
     )}
  end
end
