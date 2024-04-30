defmodule Es6Maps.Formatter do
  @moduledoc """
  Replaces all map keys with their shorthand form.

  Add the plugin to `.formatter.exs`, then call `mix format` to reformat your code:

  ```elixir
  # .formatter.exs
  [
  plugins: [Es6Maps.Formatter],
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"]
  ]
  ```

  The plugin manipulates the AST, not raw strings, so it's precise and will only change your code by:

  1. changing map keys into the shorthand form;
  2. reordering map keys so the shorthand form comes first;
  3. formatting the results like `mix format` would.

  ### Reverting to the vanilla-style maps

  The formatting plugin can also be used to revert all of the ES6-style map shorthand uses back to the "vanilla" style.
  Set the `map_style: :vanilla` option in `.formatter.exs`, then call `mix format` to reformat your code:

  ```elixir
  # .formatter.exs
  [
  plugins: [Es6Maps.Formatter],
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  map_style: :vanilla
  ]
  ```

  ## Options
    * `map_style` - `:es6` to convert to shorthand form, `:vanilla` to revert to the vanilla-style maps.
    * all other options of mix format, such as `line_length`, are supported and passed down to formatting functions.
  """

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
    |> Macro.postwalk(&format_map(&1, opts))
    |> Code.Formatter.to_algebra(Keyword.merge([comments: comments], opts))
    |> Inspect.Algebra.format(line_length)
    |> case do
      [] -> ""
      text -> IO.iodata_to_binary([text, ?\n])
    end
  end

  defp format_map({:%{}, meta, [{:|, pipemeta, [lhs, elements]}]}, opts) do
    {_, _, mapped_elements} = format_map({:%{}, pipemeta, elements}, opts)
    {:%{}, meta, [{:|, pipemeta, [lhs, mapped_elements]}]}
  end

  defp format_map({:%{}, _meta, _elements} = map, opts) do
    case Keyword.get(opts, :map_style, :es6) do
      :es6 -> format_map_es6(map, opts)
      :vanilla -> format_map_vanilla(map, opts)
      other -> raise ArgumentError, "invalid map_style: #{inspect(other)}"
    end
  end

  defp format_map(node, _opts), do: node

  defp format_map_vanilla({:%{}, meta, elements}, _opts) do
    {:%{}, meta,
     Enum.map(elements, fn
       {key, meta, context} = var when is_atom(context) ->
         {{:__block__, [format: :keyword] ++ meta, [key]}, var}

       elem ->
         elem
     end)}
  end

  defp format_map_es6({:%{}, meta, elements}, _opts) do
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
end
