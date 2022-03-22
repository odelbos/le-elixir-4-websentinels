defmodule WebSentinels.Settings do
  @moduledoc """
  Store the sentinels configuration.
  """
  require Logger
  use Agent
  alias WebSentinels.Parser

  def start_link([]) do
    Logger.info "Start settings agent"
    file = Path.join [File.cwd!, "config", "sentinels.yml"]
    Agent.start_link(fn -> Parser.parse(file) end, name: __MODULE__)
  end

  @doc """
  Get the sentinels configuration.
  """
  def get do
    Agent.get WebSentinels.Settings, & &1
  end
end
