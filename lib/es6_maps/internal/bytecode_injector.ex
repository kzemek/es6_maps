defmodule Es6Maps.Internal.BytecodeInjector do
  @moduledoc false

  @spec prepare_bytecode() :: binary()
  def prepare_bytecode do
    {:elixir, elixir_bytecode, _elixir_filename} = :code.get_object_code(:elixir)
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

    binary
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
      defmodule Es6Maps.InjectedCode do
        @moduledoc false

        # credo:disable-for-next-line
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
          {_, idents_to_expand} =
            Macro.prewalk(quoted, MapSet.new(), fn
              {:%{}, _meta, kvs} = node, acc ->
                kvs = with([{:|, _meta, [_map, inner_kvs]}] <- kvs, do: inner_kvs)

                acc =
                  for {name, meta, ctx} when is_atom(ctx) <- kvs,
                      into: acc,
                      do: {meta[:line], meta[:column], name}

                {node, acc}

              node, acc ->
                {node, acc}
            end)

          es6_maps_do_expand_identifiers(tokens, idents_to_expand)
        end

        defp es6_maps_do_expand_identifiers(tokens, idents_to_expand) do
          tokens
          |> Enum.reduce([], fn
            {:identifier, {line, col, _} = loc, name} = token, acc ->
              if {line, col, name} in idents_to_expand,
                do: [token, {:kw_identifier, loc, name} | acc],
                else: [token | acc]

            token, acc when is_tuple(token) ->
              expanded_token =
                for idx <- 1..(tuple_size(token) - 1), elem = elem(token, idx), reduce: token do
                  token when is_list(elem) ->
                    expanded = es6_maps_do_expand_identifiers(elem, idents_to_expand)
                    put_elem(token, idx, expanded)

                  token ->
                    token
                end

              [expanded_token | acc]

            token, acc ->
              [token | acc]
          end)
          |> Enum.reverse()
        end

        defp string_to_tokens_orig(_string, _line, _column, _file, _opts),
          do: {:ok, []}
      end

    bytecode
    |> abstract_code()
    |> Enum.filter(
      &function?(&1,
        string_to_tokens: 5,
        es6_maps_expand_identifiers: 2,
        es6_maps_do_expand_identifiers: 2
      )
    )
  end
end
