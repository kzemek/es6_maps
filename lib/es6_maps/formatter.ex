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
  Set the `es6_maps: [map_style: :vanilla]` option in `.formatter.exs`, then call `mix format` to reformat your code:

  ```elixir
  # .formatter.exs
  [
  plugins: [Es6Maps.Formatter],
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  es6_maps: [map_style: :vanilla]
  ]
  ```

  ### Formatting pragmas

  The plugin supports pragmas in the comments to control the formatting.
  The pragma must be in the form `# es6_maps: [map_style: :vanilla]` and can be placed anywhere in the file.
  The `map_style` option can be set to `:es6` to convert to shorthand form or `:vanilla` to revert to the vanilla-style maps.
  The pragma takes effect only on the line following the comment.

  For example in the code below, the first map will be formatted to the shorthand form, while the second map will be left as is:

  ```elixir
    %{foo, bar: 1} = var
    # es6_maps: [map_style: :vanilla]
    %{hello: hello, foo: foo, bar: 1} = var
  ```

  `es6_maps: [map_style: :vanilla]` option in `.formatter.exs` can be combined with `# es6_maps: [map_style: :es6]` comment pragmas.

  ## Options
    * `es6_maps`:
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

    pragmas = comments_to_pragmas(comments)

    quoted
    |> Macro.postwalk(&format_map(&1, pragmas, opts))
    |> Code.Formatter.to_algebra(Keyword.merge([comments: comments], opts))
    |> Inspect.Algebra.format(line_length)
    |> case do
      [] -> ""
      text -> IO.iodata_to_binary([text, ?\n])
    end
  end

  defp comments_to_pragmas(comments) do
    comments
    |> Enum.filter(&String.starts_with?(&1.text, "# es6_maps: "))
    |> Map.new(fn comment ->
      {settings, _} =
        comment.text
        |> String.replace_prefix("# ", "[")
        |> String.replace_suffix("", "]")
        |> Code.eval_string()

      {comment.line + 1, settings}
    end)
  end

  defp format_map({:%{}, meta, [{:|, pipemeta, [lhs, elements]}]}, pragmas, opts) do
    {_, _, mapped_elements} = format_map({:%{}, meta, elements}, pragmas, opts)
    {:%{}, meta, [{:|, pipemeta, [lhs, mapped_elements]}]}
  end

  defp format_map({:%{}, meta, _elements} = map, pragmas, opts) do
    opts = Config.Reader.merge(opts, Map.get(pragmas, meta[:line], []))

    case Kernel.get_in(opts, [:es6_maps, :map_style]) || :es6 do
      :es6 -> format_map_es6(map)
      :vanilla -> format_map_vanilla(map)
      other -> raise ArgumentError, "invalid map_style: #{inspect(other)}"
    end
  end

  defp format_map(node, _pragmas, _opts), do: node

  defp format_map_vanilla({:%{}, meta, elements}) do
    {:%{}, meta,
     Enum.map(elements, fn
       {key, meta, context} = var when is_atom(context) ->
         {{:__block__, [format: :keyword] ++ meta, [key]}, var}

       elem ->
         elem
     end)}
  end

  defp format_map_es6({:%{}, meta, elements}) do
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
