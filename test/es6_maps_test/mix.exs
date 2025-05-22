defmodule Es6MapsTest.MixProject do
  use Mix.Project

  def project do
    [
      app: :es6_maps_test,
      version: "0.1.0",
      elixir: "~> 1.16",
      elixirc_paths: ["lib", "test/support"],
      compilers: [:es6_maps | Mix.compilers()],
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:es6_maps, path: "../.."}
    ]
  end
end
