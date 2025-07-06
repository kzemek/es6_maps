defmodule Es6Maps.Internal.BytecodeInjector do
  @moduledoc false

  require BeamPatch

  @spec prepare_bytecode() :: BeamPatch.Patch.t()
  def prepare_bytecode do
    BeamPatch.patch! :elixir do
      @override original: [rename_to: :string_to_tokens_orig]
      # credo:disable-for-next-line Credo.Check.Readability.Specs
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
    end
  end
end
