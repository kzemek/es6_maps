defmodule Es6MapsTestTest do
  use ExUnit.Case

  defmodule MyStruct do
    @moduledoc false
    defstruct [:key1, :key2, :key3]
  end

  doctest_file("../../README.md")
end
