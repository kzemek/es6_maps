defmodule Es6Maps do
  @external_resource "README.md"
  @moduledoc File.read!("README.md")
             |> String.replace(~r/^.*?(?=Enables ES6-like shorthand usage of Elixir maps)/s, "")
             |> String.replace("> [!WARNING]", "> #### Warning {: .warning}")
             |> String.replace("> [!IMPORTANT]", "> #### Important {: .info}")

  use Application

  @elixir_bytecode Es6Maps.Internal.BytecodeInjector.prepare_bytecode()

  @doc """
  Callback implementation for `Application.start/2`.  Calls `load/0`.
  """
  @impl Application
  @spec start(Application.start_type(), term()) :: Supervisor.on_start()
  def start(_type, _args) do
    load()
    Supervisor.start_link([], name: __MODULE__, strategy: :one_for_one)
  end

  @doc """
  Injects the ES6 maps support into the Elixir compiler.
  """
  @spec load() :: :ok
  def load do
    if not injected?(), do: inject_es6_maps_support()
    :ok
  end

  defp injected? do
    Code.with_diagnostics(fn -> Code.compile_string("%{x} = %{x: 1}") end)
    true
  rescue
    CompileError -> false
  end

  defp inject_es6_maps_support do
    elixir_filename = :code.which(:elixir)
    {:module, :elixir} = :code.load_binary(:elixir, elixir_filename, @elixir_bytecode)
  end
end
