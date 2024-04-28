defmodule Es6Maps.MixProject do
  use Mix.Project

  def project do
    [
      app: :es6_maps,
      version: "0.2.1",
      description: "Shorthand syntax for Elixir maps: `%{foo, bar} = map; IO.puts(foo)`",
      package: [
        links: %{"GitHub" => "https://github.com/kzemek/es6_maps"},
        licenses: ["Apache-2.0"]
      ],
      source_url: "https://github.com/kzemek/es6_maps",
      docs: [main: "readme", extras: ["README.md", "LICENSE"]],
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
      {:ex_doc, "~> 0.31", only: :dev, runtime: false}
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
