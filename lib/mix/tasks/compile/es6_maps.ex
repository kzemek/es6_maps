defmodule Mix.Tasks.Compile.Es6Maps do
  @moduledoc """
  Injects the ES6 maps support into the Elixir compiler.

  This module does nothing more than calling `Es6Maps.load/0`, causing the ES6 maps support
  to be injected into the Elixir compiler from that moment on.

  It should be added as the first in the list of `:compilers` in `Mix.exs`:

      def project do
        [
          compilers: [:es6_maps | Mix.compilers()],
          deps: deps()
        ]
      end
  """

  use Mix.Task.Compiler

  @impl Mix.Task.Compiler
  def run(_args) do
    :ok = Application.ensure_loaded(:es6_maps)
    :ok = Es6Maps.load()
    :ok
  end
end
