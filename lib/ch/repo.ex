defmodule Ch.Repo do
  use Ecto.Repo,
    otp_app: :ch,
    adapter: Ecto.Adapters.Postgres
end
