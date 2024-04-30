defmodule Es6Maps.Formatter do
  @moduledoc false
  @behaviour Mix.Tasks.Format

  @impl Mix.Tasks.Format
  def features(_opts), do: [sigils: [], extensions: [".ex", ".exs"]]

  def format(contents), do: format(contents, [])

  @impl Mix.Tasks.Format
  def format(contents, opts) do
    line_length = Keyword.get(opts, :line_length, 98)

    {quoted, comments} =
      Code.string_to_quoted_with_comments!(
        contents,
        Keyword.merge(
          [
            unescape: false,
            literal_encoder: &{:ok, {:__block__, &2, [&1]}},
            token_metadata: true,
            emit_warnings: false
          ],
          opts
        )
      )

    quoted
    |> Macro.postwalk(&format_map(&1, Map.new(opts)))
    |> Code.Formatter.to_algebra(Keyword.merge([comments: comments], opts))
    |> Inspect.Algebra.format(line_length)
    |> IO.iodata_to_binary()
  end

  defp format_map({:%{}, meta, [{:|, pipemeta, [lhs, elements]}]}, opts) do
    {_, _, mapped_elements} = format_map({:%{}, pipemeta, elements}, opts)
    {:%{}, meta, [{:|, pipemeta, [lhs, mapped_elements]}]}
  end

  defp format_map({:%{}, meta, elements}, %{revert: true}) do
    {:%{}, meta,
     Enum.map(elements, fn
       {key, meta, context} = var when is_atom(context) ->
         {{:__block__, [format: :keyword] ++ meta, [key]}, var}

       elem ->
         elem
     end)}
  end

  defp format_map({:%{}, meta, elements}, _opts) do
    {vars, key_vals} =
      Enum.reduce(elements, {[], []}, fn
        {{:__block__, _, [key]}, {key, _, ctx} = var}, {vars, key_vals} when is_atom(ctx) ->
          {[var | vars], key_vals}

        {_, _, ctx} = var, {vars, key_vals} when is_atom(ctx) ->
          {[var | vars], key_vals}

        key_val, {vars, key_vals} ->
          {vars, [key_val | key_vals]}
      end)

    {:%{}, meta, Enum.reverse(key_vals ++ vars)}
  end

  defp format_map(node, _opts), do: node
end
