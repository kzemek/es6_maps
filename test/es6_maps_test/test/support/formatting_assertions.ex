defmodule Es6MapsTest.Support.FormattingAssertions do
  defmacro test_formatting(name, opts) do
    quote location: :keep do
      test unquote(name) do
        opts = unquote(opts)
        original = Keyword.fetch!(opts, :original)
        formatted = Keyword.get(opts, :formatted, original)
        reverted = Keyword.get(opts, :reverted, original)

        formatting_opts = Keyword.get(opts, :opts, [])
        vanilla_opts = Config.Reader.merge(opts, es6_maps: [map_style: :vanilla])

        assert Es6Maps.Formatter.format(original, formatting_opts) == formatted
        assert Es6Maps.Formatter.format(formatted, vanilla_opts) == reverted
      end
    end
  end
end
