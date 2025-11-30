defmodule Es6Maps.MixProject do
  use Mix.Project

  def project do
    [
      app: :es6_maps,
      version: "1.0.2",
      description: "Shorthand syntax for Elixir maps: `%{foo, bar} = map; IO.puts(foo)`",
      package: package(),
      source_url: "https://github.com/kzemek/es6_maps",
      docs: [main: "Es6Maps", extras: ["LICENSE", "NOTICE"]],
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      dialyzer: dialyzer()
    ] ++ docs()
  end

  def application do
    [mod: {Es6Maps, []}]
  end

  defp deps do
    [
      {:beam_patch, "~> 0.2.2"},
      {:ex_doc, "~> 0.39.1", only: :dev, runtime: false, optional: true},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false, optional: true},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false, optional: true}
    ]
  end

  defp docs do
    [
      source_url: "https://github.com/kzemek/es6_maps",
      homepage_url: "https://github.com/kzemek/es6_maps",
      docs: [
        main: "Es6Maps",
        extras: ["LICENSE", "NOTICE"]
      ]
    ]
  end

  defp package do
    [
      links: %{"GitHub" => "https://github.com/kzemek/es6_maps"},
      licenses: ["Apache-2.0"]
    ]
  end

  defp dialyzer do
    [
      plt_add_apps: [:mix]
    ]
  end

  defp aliases do
    [
      credo: "credo --strict",
      test: &test/1,
      lint: ["credo", "dialyzer"]
    ]
  end

  defp test(args) do
    color = if :prim_tty.isatty(:stdout), do: ["--color"], else: []
    args = ~w[do deps.get + test] ++ color ++ args
    Mix.Shell.IO.cmd({"mix", args}, cd: "test/es6_maps_test", env: %{"MIX_ENV" => "test"})
  end
end
