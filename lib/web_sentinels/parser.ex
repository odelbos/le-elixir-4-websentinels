defmodule WebSentinels.Parser do
  @moduledoc """
  Parse the 'sentinels.yml' yaml file.
  """

  @doc """
  Parse the yaml file

  ## Parameters

    - file : The file path of the yaml file.
  """
  def parse(file) do
    case YamlElixir.read_from_file file do
      {:ok, sentinels} -> parse_yaml sentinels
      _ -> halt_with_cannot_parse()
    end
  end

  defp parse_yaml(sentinels), do: parse_sentinels sentinels, []

  # -----

  defp parse_sentinels([], acc), do: Enum.reverse acc

  defp parse_sentinels([sentinel | rest], acc) do
    parse_sentinels rest, [parse_sentinel(sentinel) | acc]
  end

  # -----

  defp parse_sentinel(%{"url"=>url, "every"=>every, "expects"=>expects}) do
    %{
      url: url,
      every: parse_every(every),
      expects: parse_expects(expects)
    }
  end

  defp parse_sentinel(_data), do: halt_with_sentinel_info()

  # -----

  defp parse_every(every) do
    try do
      cond do
        String.contains? every, "mn" ->
          every
            |> String.replace("mn", "")
            |> String.trim()
            |> String.to_integer()
            |> Kernel.*(1000 * 60)           # Convert to milliseconds
        String.contains? every, "h" ->
          every
            |> String.replace("h", "")
            |> String.trim()
            |> String.to_integer()
            |> Kernel.*(1000 * 60 * 60)      # Convert to milliseconds
        true ->
          halt_with_every_info()
      end
    rescue
      _ -> halt_with_every_info()
    end
  end

  # -----

  defp parse_expects(%{"status"=>status, "max_duration"=>duration} = expects)
            when is_integer(status) and is_integer(duration) do
    %{status: status, max_duration: duration}
      |> parse_expects_length(expects)
  end

  defp parse_expects(%{"max_duration"=>duration} = _expects)
            when not is_integer(duration) do
    halt_with_must_be_integer_info "max_duration"
  end

  defp parse_expects(%{"status"=>status} = expects) when is_integer(status) do
    %{status: status}
      |> parse_expects_length(expects)
  end

  defp parse_expects(%{"status"=>status} = _expects)
            when not is_integer(status) do
    halt_with_must_be_integer_info "status"
  end

  defp parse_expects(_expects), do: halt_with_expects_info()

  # -----

  defp parse_expects_length(config, %{"length" => rules}) do
    length_rules = parse_length_rules [], rules
    Map.put config, :length, length_rules
  end

  defp parse_expects_length(config, _expects), do: config

  # --

  defp parse_length_rules(acc, []), do: Enum.reverse acc

  defp parse_length_rules(acc, [rule | rest]) do
    case rule do
      %{"value"=>value, "op"=>op} ->
        validates_integer value, "length.value"
        validates_in op, ["<", ">", "="], "length.op"
        parse_length_rules [%{value: value, op: op} | acc], rest
      _ ->
        halt_with_length_info()
    end
  end

  # ------------------------------------------------------------
  # Helpers : validates functions
  # ------------------------------------------------------------
  defp validates_integer(value, name) do
    unless is_integer(value), do: halt_with_must_be_integer_info name
  end

  defp validates_in(op, values, name) do
    unless op in values do
      msg = Enum.join values, ", "
      header "Error, bad '#{name}' values", :red
      nl()
      IO.puts "> authorized values for '#{name}' are : #{msg}"
      nl()
      System.halt 1
    end
  end

  # ------------------------------------------------------------
  # Helpers : error messages functions
  # ------------------------------------------------------------
  defp halt_with_cannot_parse() do
    header "Error, cannot parse 'sentinels.yml' file", :red
    nl()
    System.halt 1
  end

  defp halt_with_every_info() do
    header "Error, cannot parse 'every'", :red
    nl()
    IO.puts "> 'every' accept minutes or hours with format : 3mn, 2h"
    nl()
    System.halt 1
  end

  defp halt_with_sentinel_info() do
    header "Error, required settings are missing", :red
    nl()
    IO.puts "> 'url', 'every' and 'expects' are required"
    nl()
    System.halt 1
  end

  defp halt_with_expects_info() do
    header "Error, missing or bad 'status'", :red
    nl()
    IO.puts "> 'status' is required and must be an integer"
    nl()
    System.halt 1
  end

  defp halt_with_must_be_integer_info(name) do
    header "Error, bad '#{name}' type", :red
    nl()
    IO.puts "> '#{name}' must be an integer"
    nl()
    System.halt 1
  end

  defp halt_with_length_info() do
    header "Error, bad length rule", :red
    nl()
    IO.puts "> length rule must have a 'value' and 'op' attributes"
    IO.puts "> 'value' must be an integer"
    IO.puts "> 'op' must be one of : <, >, ="
    nl()
    System.halt 1
  end

  # -----

  defp nl(), do: IO.puts ""

  defp header(txt, color) do
    if color == :red, do: IO.write IO.ANSI.red()
    IO.puts "----------------------------------------------------------"
    IO.puts txt
    IO.puts "----------------------------------------------------------"
    unless color == :normal, do: IO.write IO.ANSI.reset()
  end
end
