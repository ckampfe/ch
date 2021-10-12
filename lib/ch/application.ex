defmodule Ch.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      # Ch.Repo,
      # Start the Telemetry supervisor
      ChWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Ch.PubSub},
      # Start the Endpoint (http/https)
      ChWeb.Endpoint
      # Start a worker by calling: Ch.Worker.start_link(arg)
      # {Ch.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Ch.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ChWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
