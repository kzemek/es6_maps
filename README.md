# es6_maps

[![CI](https://github.com/kzemek/es6_maps/actions/workflows/elixir.yml/badge.svg)](https://github.com/kzemek/es6_maps/actions/workflows/elixir.yml)
[![Module Version](https://img.shields.io/hexpm/v/es6_maps.svg)](https://hex.pm/packages/es6_maps)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/es6_maps/)
[![License](https://img.shields.io/hexpm/l/es6_maps.svg)](https://github.com/kzemek/es6_maps/blob/master/LICENSE)

Enables ES6-like shorthand usage of Elixir maps.

### Why?

When writing code that heavily utilizes structures and passes complex objects through multiple layers, it's common to frequently use map literals.
This often results in repetitive code patterns such as `ctx = %{variable: variable, user: user, ...}` or `%{variable: variable, user: user, ...} = ctx`.

I believe that introducing a shorthand form of object creation to Elixir enhances the language's ergonomics and is a natural extension of its existing map literals syntax.
This feature will be immediately familiar to JavaScript and Rust developers, and similar shorthands are present in other languages such as Go.

## Usage

### Creating maps

```elixir
iex> {hello, foo, bar} = {"world", 1, 2}
iex> %{hello, foo, bar: bar}
%{hello: "world", foo: 1, bar: 2}
```

### Destructuring maps

```elixir
iex> %{hello, foo} = %{hello: "world", foo: 1, bar: 2}
iex> hello
"world"
iex> foo
1
```

### Updating maps

```elixir
iex> map = %{hello: "world", foo: 1, bar: 2}
iex> foo = :baz
iex> %{map | foo, bar: :bong}
%{hello: "world", foo: :baz, bar: :bong}
```

### Structs

All of the above work for structs as well:

```elixir
defmodule MyStruct do
  defstruct [:hello, :foo, :bar]
end

iex> {foo, bar} = {1, 2}
iex> %MyStruct{foo, bar, hello: "world"}
%MyStruct{foo: 1, bar: 2, hello: "world"}

iex> struct = %MyStruct{foo: 1, bar: 2}
iex> hello = "world"
iex> %MyStruct{struct | hello}
%MyStruct{foo: 1, bar: 2, hello: "world"}

iex> %MyStruct{hello} = %MyStruct{hello: "world", foo: 1}
iex> hello
"world"
```

## How does it work?

`es6_maps` uses [`meck`](https://github.com/eproxus/meck) to replace the implementation of Elixir compiler's `elixir_map` module.
The module's `expand_map/4` function is then replaced to expand map keys `%{k}` as if they were `%{k: k}`.
After `es6_maps` runs as one of the Mix compilers, the Elixir compiler will use the replaced functions to compile the rest of the code.

> [!IMPORTANT]
> By the nature of this solution it's tightly coupled to the internal Elixir implementation.
> The current version of `es6_maps` should work for Elixir 1.15, 1.16 and the upcoming 1.17 version, but may break in the future.

## Installation

The package can be installed by adding `es6_maps` to your list of dependencies and compilers in `mix.exs`:

```elixir
def project do
  [
    app: :testme,
    version: "0.1.0",
    compilers: [:es6_maps | Mix.compilers()],
    deps: deps()
  ]
end

def deps do
  [
    {:es6_maps, "~> 0.1.0", runtime: false}
  ]
end
```
