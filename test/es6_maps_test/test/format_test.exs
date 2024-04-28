defmodule Es6MapsTest.Format do
  use ExUnit.Case

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
  end
end
