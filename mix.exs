defmodule Es6Maps.MixProject do
  use Mix.Project

  def project do
    [
      app: :es6_maps,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  def application do
    []
  end

  defp deps do
    [
      {:meck, "~> 0.9"}
    ]
  end

  defp test(args) do
    args = ["--cd", "test/es6_maps_test", "MIX_ENV=test", "mix", "do", "deps.get,", "test" | args]
    Mix.Task.run("cmd", args)
  end

  defp aliases do
    [
      test: &test/1
    ]
  end
end
