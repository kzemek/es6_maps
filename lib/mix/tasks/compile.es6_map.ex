defmodule Mix.Tasks.Compile.Es6Maps do
  @moduledoc false

  use Mix.Task.Compiler

  def run(_args) do
    :ok = :meck.new(:elixir_map, [:passthrough])

    :meck.expect(:elixir_map, :expand_map, fn meta, args, s, e ->
      :meck.passthrough([meta, expand_atom_keys(args), s, e])
    end)

    :ok
  end

  defp expand_atom_keys(args) do
    Enum.map(args, fn
      {:|, meta, [map, inner_args]} -> {:|, meta, [map, expand_atom_keys(inner_args)]}
      {k, _meta, nil} = v when is_atom(k) -> {k, v}
      other -> other
    end)
  end
end
