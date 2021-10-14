defmodule ChWeb.ChessLive do
  # If you generated an app with mix phx.new --live,
  # the line below would be: use MyAppWeb, :live_view
  use Phoenix.LiveView
  use Phoenix.Component
  require Integer

  def square(assigns) do
    style =
      cond do
        {assigns.column, assigns.row} == assigns.selected_position ->
          "background-color: cyan;"

        {assigns.column, assigns.row} in assigns.moves ->
          "background-color: orange;"

        Integer.is_even(assigns.column + assigns.row) ->
          "background-color: gray;"

        true ->
          ""
      end

    case Map.fetch(assigns.indexed, {assigns.column, assigns.row}) do
      {:ok, piece} ->
        ~H"""
        <td phx-click={"position-#{assigns.column}-#{assigns.row}"} style={ style }>
          <%= Chess.Piece.to_string(piece) %>
        </td>
        """

      :error ->
        ~H"""
        <td phx-click={"position-#{assigns.column}-#{assigns.row}"} style={ style }>
          <%= "\u3000" %>
        </td>
        """
    end
  end

  def board(assigns) do
    {row_range, column_range} =
      case assigns.player_color do
        :white -> {7..0, 0..7}
        :black -> {0..7, 7..0}
      end

    ~H"""
    <table>
    <%= for row <- row_range do %>
      <tr>
      <%= for column <- column_range do %>
        <%= square(%{
            column: column,
            row: row,
            indexed: assigns.indexed,
            moves: assigns.moves,
            selected_position: assigns.selected_position,
            player_color: assigns.player_color

          })
        %>
      <% end %>
      </tr>
    <% end %>
    </table>
    """
  end

  def render(assigns) do
    indexed =
      assigns.game.board.pieces
      |> Enum.map(fn piece ->
        xy = Chess.Position.to_xy(piece.position)
        {xy, piece}
      end)
      |> Enum.into(%{})

    ~H"""
    <div class="row">
      <div class="column">
        <div><%= "To move: #{@to_move}" %></div>
        <div><%= "Selected: #{@position_string}" %></div>
        <div><%= "Possible moves: #{inspect(@moves)}" %></div>
      </div>

      <div class="column column-60">
        <%= board(%{
            player_color: @player_color,
            indexed: indexed,
            moves: @moves,
            selected_position: @selected_position
          })
        %>
      </div>
    </div>
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
              position_string: "",
              to_move: if(socket.assigns.to_move == :white, do: :black, else: :white)
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
    game = Chess.Game.new()
    to_move = game.to_move

    {:ok,
     assign(socket,
       game: game,
       player_color: :white,
       to_move: to_move,
       moves: [],
       selected_position: nil,
       position_string: ""
     )}
  end
end
