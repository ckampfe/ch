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
                ""
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

    if socket.assigns.selected_position == {column, row} do
      socket =
        assign(socket,
          selected_position: nil,
          position_string: "",
          moves: []
        )

      {:noreply, socket}
    else
      if socket.assigns.selected_position do
        piece_at_position =
          Enum.find(socket.assigns.game.board.pieces, fn piece ->
            Chess.Piece.position(piece) |> Chess.Position.to_xy() == {column, row}
          end)

        possible_moves =
          if piece_at_position do
            Chess.Piece.moves(piece_at_position, socket.assigns.game.board)
            |> Enum.map(fn position ->
              Chess.Position.to_xy(position)
            end)
          else
            []
          end

        if {column, row} in possible_moves do
          # TODO actually finish the move logic in Chess.Game (game.ex)

          socket =
            assign(socket,
              selected_position: nil,
              position_string: "",
              moves: []
            )

          {:noreply, socket}
        else
          socket =
            assign(socket,
              selected_position: nil,
              position_string: "",
              moves: []
            )

          {:noreply, socket}
        end
      else
        piece_at_position =
          Enum.find(socket.assigns.game.board.pieces, fn piece ->
            Chess.Piece.position(piece) |> Chess.Position.to_xy() == {column, row}
          end)

        possible_moves =
          if piece_at_position do
            Chess.Piece.moves(piece_at_position, socket.assigns.game.board)
            |> Enum.map(fn position ->
              Chess.Position.to_xy(position)
            end)
          else
            []
          end

        socket =
          assign(socket,
            selected_position: {column, row},
            position_string: "#{column}, #{row}",
            moves: possible_moves
          )

        {:noreply, socket}
      end
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
