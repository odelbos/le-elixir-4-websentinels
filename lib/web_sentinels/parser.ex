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

  defp parse_expects(%{"status"=>status} = _expects) when is_integer(status) do
    %{status: status}
  end

  defp parse_expects(_expects), do: halt_with_expects_info()

  # ------------------------------------------------------------
  # Helpers functions for error messages
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
