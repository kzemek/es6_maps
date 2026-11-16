defmodule Es6MapsTest.Format do
  use ExUnit.Case, async: true

  import Es6MapsTest.Support.FormattingAssertions

  describe "map literal" do
    test_formatting "has its keys reformatted into shorthands",
      original: """
      def test(var) do
        %{a: a, b: b, c: 1} = var
        var
      end
      """,
      formatted: """
      def test(var) do
        %{a, b, c: 1} = var
        var
      end
      """

    test_formatting "already formatted map is not reformatted",
      original: """
      def test(var) do
        %{grepme, b, c: 1} = var
        var
      end
      """,
      formatted: """
      def test(var) do
        %{grepme, b, c: 1} = var
        var
      end
      """,
      reverted: """
      def test(var) do
        %{grepme: grepme, b: b, c: 1} = var
        var
      end
      """

    test_formatting "has its keys moved to the front when reformatting to shorthand",
      original: """
      def test(var) do
        %{a: 1, b: 2, c: c, d: d} = var
        var
      end
      """,
      formatted: """
      def test(var) do
        %{c, d, a: 1, b: 2} = var
        var
      end
      """,
      reverted: """
      def test(var) do
        %{c: c, d: d, a: 1, b: 2} = var
        var
      end
      """

    test_formatting "is not reformatted when inline-comment sets the map-style to :vanilla",
      original: """
      def test(var) do
        %{a: a, b: b} = var
        # es6_maps: [map_style: :vanilla]
        %{a: a, b: b} = var
        %{a: a, b: b} = var
        var
      end
      """,
      formatted: """
      def test(var) do
        %{a, b} = var
        # es6_maps: [map_style: :vanilla]
        %{a: a, b: b} = var
        %{a, b} = var
        var
      end
      """

    test_formatting "is reformatted when inline-comment sets the map-style to :es6 but default style is :vanilla",
      opts: [es6_maps: [map_style: :vanilla]],
      original: """
      def test(var) do
        %{a: a, b: b} = var
        # es6_maps: [map_style: :es6]
        %{a: a, b: b} = var
        %{a: a, b: b} = var
        var
      end
      """,
      formatted: """
      def test(var) do
        %{a: a, b: b} = var
        # es6_maps: [map_style: :es6]
        %{a, b} = var
        %{a: a, b: b} = var
        var
      end
      """,
      reverted: """
      def test(var) do
        %{a: a, b: b} = var
        # es6_maps: [map_style: :es6]
        %{a, b} = var
        %{a: a, b: b} = var
        var
      end
      """
  end

  describe "map update literal" do
    test_formatting "has its keys reformatted into shorthands",
      original: """
      def test(var) do
        %{var | a: a, b: b, c: 1}
      end
      """,
      formatted: """
      def test(var) do
        %{var | a, b, c: 1}
      end
      """

    test_formatting "has its keys moved to the front when reformatting to shorthand",
      original: """
      def test(var) do
        %{var | a: 1, b: 2, c: c, d: d}
      end
      """,
      formatted: """
      def test(var) do
        %{var | c, d, a: 1, b: 2}
      end
      """,
      reverted: """
      def test(var) do
        %{var | c: c, d: d, a: 1, b: 2}
      end
      """
  end

  describe "struct literals" do
    test_formatting "has its keys reformatted into shorthands",
      original: """
      def test(var) do
        %A.B.StructName{a: a, b: b, c: 1} = var
        var
      end
      """,
      formatted: """
      def test(var) do
        %A.B.StructName{a, b, c: 1} = var
        var
      end
      """

    test_formatting "has its keys moved to the front when reformatting to shorthand",
      original: """
      def test(var) do
        %A.B.StructName{a: 1, b: 2, c: c, d: d} = var
        var
      end
      """,
      formatted: """
      def test(var) do
        %A.B.StructName{c, d, a: 1, b: 2} = var
        var
      end
      """,
      reverted: """
      def test(var) do
        %A.B.StructName{c: c, d: d, a: 1, b: 2} = var
        var
      end
      """
  end

  describe "struct update literal" do
    test_formatting "has its keys reformatted into shorthands",
      original: """
      def test(var) do
        %A.B.StructName{var | a: a, b: b, c: 1}
      end
      """,
      formatted: """
      def test(var) do
        %A.B.StructName{var | a, b, c: 1}
      end
      """

    test_formatting "has its keys moved to the front when reformatting to shorthand",
      original: """
      def test(var) do
        %A.B.StructName{var | a: 1, b: 2, c: c, d: d}
      end
      """,
      formatted: """
      def test(var) do
        %A.B.StructName{var | c, d, a: 1, b: 2}
      end
      """,
      reverted: """
      def test(var) do
        %A.B.StructName{var | c: c, d: d, a: 1, b: 2}
      end
      """
  end

  describe "original code" do
    test_formatting "heredoc strings newlines are preserved",
      original: ~s'''
      def test(var) do
        """
          this is
          my heredoc
        """
      end
      '''

    test_formatting "comments are not moved around",
      original: """
      defmodule Test do
        use LoremIpsum,
          lorem: [LoremIpsum],
          ipsum: [
            # Lorem Ipsum Dolor
            LoremIpsumDolorSitAmetConsequaturAdipisciElit,
            LoremIpsumDolorSitAmetConsequaturAdipisciElit,
            LoremIpsumDolorSitAmetConsequaturAdipisciElit
          ]
      end
      """

    test_formatting "multiline list literals are not single-lined",
      original: """
      def test do
        [
          1,
          2,
          3
        ]
      end
      """
  end

  describe "rules option" do
    test_formatting "formats a file not matching any rule with the default options",
      opts: [file: "lib/foo.ex", es6_maps: [rules: [{["test/**/*.exs"], map_style: :vanilla}]]],
      original: """
      %{a: a, b: 1} = var
      """,
      formatted: """
      %{a, b: 1} = var
      """

    test_formatting "formats config/runtime.exs with vanilla-style maps by default",
      opts: [file: "config/runtime.exs"],
      original: """
      %{a, b: 1} = var
      """,
      formatted: """
      %{a: a, b: 1} = var
      """,
      reverted: """
      %{a: a, b: 1} = var
      """

    test_formatting "formats a file matching a rule with the rule's options",
      opts: [
        file: "lib/sub/foo.ex",
        es6_maps: [
          rules: [{["test/f[a-z]?.exs", "{lib,config}/**/*.{ex,exs}"], map_style: :vanilla}]
        ]
      ],
      original: """
      %{a, b: 1} = var
      """,
      formatted: """
      %{a: a, b: 1} = var
      """,
      reverted: """
      %{a: a, b: 1} = var
      """

    test_formatting "applies the first matching rule",
      opts: [
        file: "lib/foo.ex",
        es6_maps: [
          rules: [
            {["lib/*.exs"], map_style: :es6},
            {["lib/*.ex"], map_style: :vanilla},
            {["**/*"], map_style: :es6}
          ]
        ]
      ],
      original: """
      %{a, b: 1} = var
      """,
      formatted: """
      %{a: a, b: 1} = var
      """,
      reverted: """
      %{a: a, b: 1} = var
      """

    test_formatting "rule's options override the default options",
      opts: [
        file: "lib/foo.ex",
        es6_maps: [map_style: :vanilla, rules: [{["lib/**"], map_style: :es6}]]
      ],
      original: """
      %{a: a, b: 1} = var
      """,
      formatted: """
      %{a, b: 1} = var
      """,
      reverted: """
      %{a, b: 1} = var
      """

    test_formatting "keeps the default rules after the configured ones",
      opts: [file: "config/runtime.exs", es6_maps: [rules: [{["lib/**"], map_style: :es6}]]],
      original: """
      %{a, b: 1} = var
      """,
      formatted: """
      %{a: a, b: 1} = var
      """,
      reverted: """
      %{a: a, b: 1} = var
      """
  end
end
