defmodule WebSentinels.Worker do
  require Logger
  use GenServer

  def start_link(state) do
    name = worker_name state
    Logger.info "Start: #{name}, url: #{state[:url]}"
    GenServer.start_link __MODULE__, state, name: name
  end

  @impl true
  def init(state) do
    :timer.send_after state[:_delay], :start
    {:ok, state}
  end

  @doc """
  Start scheduling the worker
  """
  @impl true
  def handle_info(:start, state) do
    send self(), :run
    schedule state
    {:noreply, state}
  end

  @impl true
  def handle_info(:run, state) do
    #
    # TODO : Do the http ping
    #
    Logger.debug "Run: #{worker_name state}, url: #{state[:url]}"

    {:noreply, state}
  end

  # -----

  defp worker_name(state) do
    String.to_atom "Worker.#{state[:_idx]}"
  end

  defp schedule(%{every: every} = _state) do
    :timer.send_interval every, :run
  end
end
