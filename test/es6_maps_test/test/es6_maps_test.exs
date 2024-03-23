defmodule Es6MapsTestTest do
  use ExUnit.Case

  defmodule MyStruct do
    @moduledoc false
    defstruct [:hello, :foo, :bar]
  end

  doctest_file("../../README.md")
end
