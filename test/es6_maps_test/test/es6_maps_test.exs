defmodule Es6MapsTest.Es6Maps do
  use ExUnit.Case

  defmodule MyStruct do
    @moduledoc false
    defstruct [:hello, :foo, :bar]
  end

  doctest_file("../../README.md")
end
