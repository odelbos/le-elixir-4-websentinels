defmodule WebSentinels.Scheduler do
  require Logger
  use Supervisor

  def start_link(args) do
    Supervisor.start_link __MODULE__, args, name: __MODULE__
  end

  @impl true
  def init(_opts) do
    Logger.info "Start sentinels supervisor"
    :timer.sleep 100             # Ensure that settings are available
    sentinels = WebSentinels.Settings.get()
    children = build_children sentinels, [], 0, 0
    Supervisor.init children, strategy: :one_for_one
  end

  # -----

  defp build_children([], acc, _idx, _delay), do: Enum.reverse acc

  defp build_children([sentinel | rest], acc, idx, delay) do
    state = sentinel
      |> Map.put(:_idx, idx)
      |> Map.put(:_delay, delay)
    child = Supervisor.child_spec {WebSentinels.Worker, state}, id: "widx.#{idx}"
    build_children rest, [child | acc], idx + 1, delay + 4000
  end
end
