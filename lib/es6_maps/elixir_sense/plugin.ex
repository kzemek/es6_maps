if match?({:module, _}, Code.ensure_compiled(ElixirLS.LanguageServer.Plugin)) do
  defmodule Es6Maps.ElixirSense.Plugin do
    @moduledoc false
    @behaviour ElixirLS.LanguageServer.Plugin

    alias ElixirLS.LanguageServer.Plugins.ModuleStore

    @impl ElixirLS.LanguageServer.Plugin
    def setup(context) do
      module_store = ModuleStore.ensure_compiled(context, Es6Maps)
      Es6Maps.load()
      module_store
    end
  end
end
