defmodule Mix.Tasks.Es6Maps.Format do
  @shortdoc "Replaces all map keys with their shorthand form"
  @moduledoc """
  Replaces all map keys with their shorthand form.

  ```shell
  mix es6_maps.format 'lib/**/*.ex' 'test/**/*.exs'
  ```

  The arguments are expanded with `Path.wildcard(match_dot: true)`.

  The task manipulates the AST, not raw strings, so it's precise and will only change your code by:

  1. changing map keys into the shorthand form;
  2. reordering map keys so the shorthand form comes first;
  3. formatting the results with `mix format`.

  ### Going back to old-style maps

  You can revert all of the ES6-style shorthand uses with the `--revert` format flag:

  ```shell
  mix es6_maps.format --revert lib/myapp/myapp.ex
  ```

  ### Reordering map keys

  When applicable, the formatting will reorder the keys to shorthand them, for example:

  ```elixir
  %{hello: "world", foo: foo, bar: bar} = var
  ```

  will become:

  ```elixir
  %{foo, bar, hello: "world"} = var
  ```

  ## Options
    * `--revert` - Reverts the transformation.
    * `--locals-without-parens` - Specifies a list of locals that should not have parentheses.
      The format is `local_name/arity`, where `arity` can be an integer or `*`. This option can
      be given multiple times, and/or multiple values can be separated by commas.
  """

  use Mix.Task

  @switches [revert: :boolean, locals_without_parens: :keep]

  @impl Mix.Task
  def run(all_args) do
    {opts, args} = OptionParser.parse!(all_args, strict: @switches)

    locals_without_parens = collect_locals_without_parens(opts)
    revert = Keyword.get(opts, :revert, false)
    opts = %{locals_without_parens: locals_without_parens, revert: revert}

    Enum.each(collect_paths(args), &format_file(&1, opts))
    Mix.Tasks.Format.run(args)
  end

  defp collect_locals_without_parens(opts) do
    opts
    |> Keyword.get_values(:locals_without_parens)
    |> Enum.flat_map(&String.split(&1, ","))
    |> Enum.map(fn local_str ->
      [fname_str, arity_str] =
        case String.split(local_str, "/", parts: 2) do
          [fname_str, arity_str] -> [fname_str, arity_str]
          _ -> raise ArgumentError, "invalid local: #{local_str}"
        end

      fname = String.to_atom(fname_str)
      arity = if arity_str == "*", do: :*, else: String.to_integer(arity_str)
      {fname, arity}
    end)
  end

  defp collect_paths(paths) do
    paths |> Enum.flat_map(&Path.wildcard(&1, match_dot: true)) |> Enum.filter(&File.regular?/1)
  end

  defp format_file(filepath, opts) do
    {quoted, comments} =
      filepath
      |> File.read!()
      |> Code.string_to_quoted_with_comments!(
        emit_warnings: false,
        literal_encoder: &{:ok, {:__block__, &2, [&1]}},
        token_metadata: true,
        unescape: false,
        file: filepath
      )

    quoted
    |> Macro.postwalk(&format_map(&1, opts))
    |> Code.quoted_to_algebra(
      comments: comments,
      escape: false,
      locals_without_parens: opts.locals_without_parens
    )
    |> Inspect.Algebra.format(:infinity)
    |> then(&File.write!(filepath, &1))
  end

  defp format_map({:%{}, meta, [{:|, pipemeta, [lhs, elements]}]}, opts) do
    {_, _, mapped_elements} = format_map({:%{}, pipemeta, elements}, opts)
    {:%{}, meta, [{:|, pipemeta, [lhs, mapped_elements]}]}
  end

  defp format_map({:%{}, meta, elements}, %{revert: true}) do
    {:%{}, meta,
     Enum.map(elements, fn
       {key, _meta, context} = var when is_atom(context) -> {key, var}
       elem -> elem
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
