defmodule Mix.Tasks.Compile.Es6Maps do
  @moduledoc false

  use Mix.Task.Compiler

  def run(_args) do
    :ok = Application.ensure_loaded(:es6_maps)
    :ok = Es6Maps.load()
    :ok
  end
end
