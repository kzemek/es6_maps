defmodule Es6MapsTest.Support.FormattingAssertions do
  defmacro test_formatting(name, opts) do
    quote location: :keep do
      test unquote(name) do
        opts = unquote(opts)
        original = opts |> Keyword.fetch!(:original) |> String.trim()
        formatted = opts |> Keyword.get(:formatted, original) |> String.trim()
        reverted = opts |> Keyword.get(:reverted, original) |> String.trim()

        assert Es6Maps.Formatter.format(original) == formatted
        assert Es6Maps.Formatter.format(formatted, revert: true) == reverted
      end
    end
  end
end
