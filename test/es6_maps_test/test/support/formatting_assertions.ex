defmodule Es6MapsTest.Support.FormattingAssertions do
  defmacro test_formatting(name, opts) do
    original = Keyword.fetch!(opts, :original)
    formatted = Keyword.get(opts, :formatted, original)
    reverted = Keyword.get(opts, :reverted, original)

    quote location: :keep do
      test unquote(name) do
        {:ok, path} = Briefly.create()
        File.write!(path, unquote(original))

        Mix.Tasks.Es6Maps.Format.run([path])
        assert File.read!(path) == String.trim(unquote(formatted))

        Mix.Tasks.Es6Maps.Format.run([path, "--revert"])
        assert File.read!(path) == String.trim(unquote(reverted || original))
      end
    end
  end
end
