defmodule Mix.Tasks.Compile.Es6Maps do
  @moduledoc false

  use Mix.Task.Compiler

  def run(_args) do
    {:elixir_map, elixir_map_bytecode, elixir_map_filename} = :code.get_object_code(:elixir_map)
    elixir_map_forms = abstract_code(elixir_map_bytecode)
    compile_opts = compile_opts(elixir_map_bytecode)
    injected_forms = injected_forms()

    {forms_start, [expand_map_forms | forms_end]} =
      Enum.split_while(elixir_map_forms, &(not function?(&1, expand_map: 4)))

    expand_map_orig_forms = rename_function(expand_map_forms, :es6_maps_expand_map_orig)
    forms = Enum.concat([forms_start, injected_forms, [expand_map_orig_forms], forms_end])

    {:ok, :elixir_map, binary, _warnings} =
      :compile.forms(forms, [:return_errors, :return_warnings | compile_opts])

    {:module, :elixir_map} = :code.load_binary(:elixir_map, elixir_map_filename, binary)

    :ok
  end

  defp function?({:function, _, name, arity, _}, names), do: {name, arity} in names
  defp function?(_form, _names), do: false

  defp rename_function({:function, meta, _name, arity, clauses}, new_name),
    do: {:function, meta, new_name, arity, clauses}

  defp abstract_code(bytecode) do
    {:ok, {_, abstract_code: abstract_code}} = :beam_lib.chunks(bytecode, [:abstract_code])
    {:raw_abstract_v1, abstract} = abstract_code
    abstract
  end

  defp compile_opts(bytecode) do
    {:ok, {_, compile_info: info}} = :beam_lib.chunks(bytecode, [:compile_info])
    Keyword.fetch!(info, :options)
  end

  defp injected_forms do
    {:module, _, bytecode, _} =
      defmodule Es6Map.InjectedCode do
        def expand_map(meta, args, s, e),
          do: es6_maps_expand_map_orig(meta, expand_atom_keys(args), s, e)

        defp expand_atom_keys(args) do
          Enum.map(args, fn
            {:|, meta, [map, inner_args]} -> {:|, meta, [map, expand_atom_keys(inner_args)]}
            {k, _meta, ctx} = v when is_atom(ctx) -> {k, v}
            other -> other
          end)
        end

        defp es6_maps_expand_map_orig(_meta, _args, _s, _e), do: nil
      end

    bytecode
    |> abstract_code()
    |> Enum.filter(&function?(&1, expand_map: 4, expand_atom_keys: 1))
  end
end
