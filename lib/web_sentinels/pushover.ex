defmodule WebSentinels.Pushover do
  require Logger
  use GenServer

  def start_link(_arg) do
    GenServer.start_link(__MODULE__, %{}, name: :pushover)
  end

  def init(_state) do
    file = Path.join [File.cwd!, "config", "pushover.yml"]
    case YamlElixir.read_from_file file do
      {:ok, data} ->
        config = data |> Map.new(fn {k, v} -> {String.to_atom(k), v} end)
        IO.inspect config
        {:ok, config}
      _ ->
        {:error, "Cannot read configuration file !"}
    end
  end

  # -----

  def push(url, errors) do
    GenServer.cast :pushover, {:push, url, errors}
  end

  # -----

  def handle_cast({:push, url, errors}, %{enable: true} = state) do
    title = "Alert : #{url}"
    msg = make_msg errors, ""
    params = %{
        user: state[:user],
        token: state[:token],
        title: title,
        html: 1,
        message: msg
      }
    payload = URI.encode_query params
    headers = [{"Content-Type", "application/x-www-form-urlencoded"}]
    _response = HTTPoison.post(state[:url], payload, headers)
    Logger.info "Pushover alert sent for: #{url}"
    {:noreply, state}
  end

  def handle_cast({:push, url, errors}, state), do: {:noreply, state}

  # -----

  defp make_msg([], msg), do: msg

  defp make_msg([error | rest], msg) do
    case error do
      %{rule: :status, expect: e, got: g} ->
        make_msg rest, msg <> "<b>Status</b>: expect #{e}, got #{g}<br/>"

      %{rule: :max_duration, expect: e, got: g} ->
        make_msg rest, msg <> "<b>Max duration</b>: expect < #{e}, got #{g}<br/>"

      %{rule: :length, expect: e, got: g, op: op} ->
        make_msg rest, msg <> "<b>Length</b>: expect #{op} #{e}, got #{g}<br/>"

      %{rule: :body, expect: e, op: "c"} ->
        make_msg rest, msg <> "<b>Body</b>: expect contains: #{e}<br/>"

      %{rule: :body, expect: e, op: "="} ->
        make_msg rest, msg <> "<b>Body</b>: expect = #{e}<br/>"

      %{rule: :body, expect: e, got: g, op: "md5"} ->
        make_msg rest, msg <> "<b>Body</b>: expect md5 #{e}, got #{g}<br/>"

      %{rule: :header, name: name, got: :missing} ->
        make_msg rest, msg <> "<b>Header missing</b>: #{name}<br/>"

      %{rule: :header, name: name, expect: e, got: g, op: "c"} ->
        new_msg = msg <> "<b>Header</b>: #{name}, expect contains: #{e}, got #{g}<br/>"
        make_msg rest, new_msg

      %{rule: :header, name: name, expect: e, got: g, op: op}
                                      when op in ["=", "<", ">"] ->
        new_msg = msg <> "<b>Header</b>: #{name}, expect #{op} #{e}, got #{g}<br/>"
        make_msg rest, new_msg
      _ ->
        make_msg rest, msg <> "Unknown alert<br/>"
    end
  end
end
