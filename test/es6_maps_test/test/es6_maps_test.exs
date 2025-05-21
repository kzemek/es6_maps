defmodule Es6MapsTest.Es6Maps do
  use ExUnit.Case

  defmodule MyStruct do
    @moduledoc false
    defstruct [:hello, :foo, :bar]
  end

  doctest_file("../../README.md")

  describe ":elixir.string_to_tokens/5" do
    test "map expand" do
      assert {:ok, tokens} = :elixir.string_to_tokens(~c"%{x}", 0, 0, "", [])

      assert [
               {:%{}, _},
               {:"{", _},
               {:kw_identifier, _, :x},
               {:identifier, _, :x},
               {:"}", _}
             ] = tokens
    end

    test "map failure to expand when `es6_maps: false`" do
      assert {:ok, tokens} = :elixir.string_to_tokens(~c"%{x}", 0, 0, "", es6_maps: false)

      assert [
               {:%{}, _},
               {:"{", _},
               {:identifier, _, :x},
               {:"}", _}
             ] = tokens
    end

    test "struct expand" do
      assert {:ok, tokens} = :elixir.string_to_tokens(~c"%S{x}", 0, 0, "", [])

      assert [
               {:%, _},
               {:alias, _, :S},
               {:"{", _},
               {:kw_identifier, _, :x},
               {:identifier, _, :x},
               {:"}", _}
             ] = tokens
    end

    test "struct failure to expand when `es6_maps: false`" do
      assert {:ok, tokens} = :elixir.string_to_tokens(~c"%S{x}", 0, 0, "", es6_maps: false)

      assert [
               {:%, _},
               {:alias, _, :S},
               {:"{", _},
               {:identifier, _, :x},
               {:"}", _}
             ] = tokens
    end
  end

  describe "ExUnit assertions" do
    test "assert structs" do
      foo = 1
      assert %MyStruct{hello, foo: 2} = %MyStruct{foo, bar: 3}
      _ = hello
    rescue
      e in ExUnit.AssertionError ->
        assert Macro.to_string(e.left) == "%Es6MapsTest.Es6Maps.MyStruct{hello: hello, foo: 2}"

        assert Macro.to_string(e.right) ==
                 "%Es6MapsTest.Es6Maps.MyStruct{hello: nil, foo: 1, bar: 3}"
    end

    test "assert maps" do
      foo = 1
      assert %{hello, foo: 2} = %{foo, bar: 3}
      _ = hello
    rescue
      e in ExUnit.AssertionError ->
        assert Macro.to_string(e.left) == "%{hello: hello, foo: 2}"
        assert Macro.to_string(e.right) == "%{foo: 1, bar: 3}"
    end
  end
end
