defmodule WebSentinels.MixProject do
  use Mix.Project

  def project do
    [
      app: :web_sentinels,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {WebSentinels.Application, []}
    ]
  end

  defp deps do
    [
      {:yaml_elixir, "~> 2.8"},
      {:httpoison, "~> 1.8"}
    ]
  end
end
