defmodule Es6Maps do
  use Application

  def start(_type, _args) do
    load()
    Supervisor.start_link([], name: __MODULE__, strategy: :one_for_one)
  end

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
    {:elixir, elixir_bytecode, elixir_filename} = :code.get_object_code(:elixir)
    elixir_forms = abstract_code(elixir_bytecode)
    compile_opts = compile_opts(elixir_bytecode)
    injected_forms = injected_forms()

    {forms_start, forms_end} =
      Enum.split_while(elixir_forms, &(not function?(&1, string_to_tokens: 5)))

    {string_to_tokens_forms, forms_end} =
      Enum.split_while(forms_end, &function?(&1, string_to_tokens: 5))

    string_to_tokens_orig_forms =
      Enum.map(string_to_tokens_forms, &rename_function(&1, :string_to_tokens_orig))

    forms = Enum.concat([forms_start, injected_forms, string_to_tokens_orig_forms, forms_end])

    {:ok, :elixir, binary, _warnings} =
      :compile.forms(forms, [:return_errors, :return_warnings | compile_opts])

    {:module, :elixir} = :code.load_binary(:elixir, elixir_filename, binary)
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
        def string_to_tokens(string, line, column, file, opts) do
          {enabled?, opts} = Keyword.pop(opts, :es6_maps, true)

          with {:ok, tokens} <- string_to_tokens_orig(string, line, column, file, opts) do
            with true <- enabled?,
                 opts = Keyword.put(opts, :columns, true),
                 {:ok, quoted} <- :elixir.tokens_to_quoted(tokens, file, opts),
                 do: {:ok, es6_maps_expand_identifiers(tokens, quoted)},
                 else: (_ -> {:ok, tokens})
          end
        end

        defp es6_maps_expand_identifiers(tokens, quoted) do
          # A map of {line, column} -> [tokens]
          mapped_tokens =
            Enum.group_by(tokens, fn token ->
              meta = elem(token, 1)
              line = elem(meta, 0)
              column = elem(meta, 1)
              {line, column}
            end)

          # Expands a given identifier in the mapped_tokens, returning updated mapped_tokens
          expand_identifier = fn mapped_tokens, {identifier, meta, _ctx} ->
            Map.update!(mapped_tokens, {meta[:line], meta[:column]}, fn tokens ->
              Enum.flat_map(tokens, fn token ->
                with {:identifier, _, ^identifier} <- token do
                  kw_token = put_elem(token, 0, :kw_identifier)
                  [kw_token, token]
                end
              end)
            end)
          end

          {_, mapped_tokens} =
            Macro.prewalk(quoted, mapped_tokens, fn
              {:%{}, _meta, args} = node, mapped_tokens ->
                kvs = with [{:|, _meta, [_map, inner_kvs]}] <- args, do: inner_kvs

                mapped_tokens =
                  for {_name, _meta, ctx} = node <- kvs, is_atom(ctx), reduce: mapped_tokens do
                    mapped_tokens -> expand_identifier.(mapped_tokens, node)
                  end

                {node, mapped_tokens}

              node, mapped_tokens ->
                {node, mapped_tokens}
            end)

          mapped_tokens
          |> Enum.sort_by(fn {location, _tokens} -> location end)
          |> Enum.flat_map(fn {_location, tokens} -> tokens end)
        end

        defp string_to_tokens_orig(_string, _line, _column, _file, _opts), do: []
      end

    bytecode
    |> abstract_code()
    |> Enum.filter(&function?(&1, string_to_tokens: 5, es6_maps_expand_identifiers: 2))
  end
end
