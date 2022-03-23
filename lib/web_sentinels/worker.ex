defmodule WebSentinels.Worker do
  require Logger
  require Timer
  use GenServer
  alias WebSentinels.Expectations

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
  def handle_info(:run, %{url: url} = state) do
    opts = [timeout: 5000, recv_timeout: 5000, follow_redirect: false]
    duration = Timer.duration :millisecond do
      response = HTTPoison.get url, [], opts
    end

    case response do
      {:ok, %HTTPoison.Response{body: body, status_code: status, headers: headers}} ->
        errors =
          Expectations.validates state[:expects], duration, status, body, headers

        if length(errors) == 0 do
          Logger.info "#{worker_name state}: ok, #{duration}ms, url: #{url}"
          #
          # TODO : log success
          #
        else
          Logger.info "#{worker_name state}: expectations failed, #{duration}ms, url: #{url}"
          IO.inspect errors
          #
          # TODO : Send Pushover alert
          #
        end
      {:error, %HTTPoison.Error{reason: reason}} ->
        # reason -> :nxdomain, :timeout
        Logger.warn "#{worker_name state}: Error, #{reason}, url: #{url}"
        #
        # TODO : Send Pushover alert
        #
      _ ->
        Logger.warn "#{worker_name state}: unknown error, url: #{url}"
        #
        # TODO : Send Pushover alert
        #
    end

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
