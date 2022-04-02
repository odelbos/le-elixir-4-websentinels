defmodule WebSentinels.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {WebSentinels.Settings, []},
      {WebSentinels.Scheduler, []},
      {WebSentinels.Pushover, []}
    ]

    opts = [strategy: :one_for_one, name: WebSentinels.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
