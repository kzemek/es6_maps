if match?({:module, _}, Code.ensure_compiled(Forge.Plugin.V1.Diagnostic)) do
  defmodule Es6Maps.Expert.Plugin do
    @moduledoc false
    use Forge.Plugin.V1.Diagnostic

    def init, do: Es6Maps.load()
  end
end
