# es6_maps

[![Module Version](https://img.shields.io/hexpm/v/es6_maps.svg)](https://hex.pm/packages/es6_maps)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/es6_maps/)
[![License](https://img.shields.io/hexpm/l/es6_maps.svg)](https://github.com/kzemek/es6_maps/blob/master/LICENSE)

Enables ES6-like shorthand usage of Elixir maps.

### Why?

When writing code that heavily utilizes structures and passes complex objects through multiple layers, it's common to frequently use map literals.
This often results in repetitive code patterns such as `x = %{var1: var1, var2: var2, ...}` or `%{var1: var1, var2: var2, ...} = x`.

I believe that introducing a shorthand form of object creation to Elixir enhances the language's ergonomics and is a natural extension of its existing map literals syntax.
This feature will be immediately familiar to JavaScript and Rust developers, and similar shorthands are present in other languages such as Go.

## Usage

### Creating maps

```elixir
iex> {key1, key2, val3} = {1, 2, 3}
iex> %{key1, key2, key3: val3}
%{key1: 1, key2: 2, key3: 3}
```

### Destructuring maps

```elixir
iex> m = %{key1: 1, key2: 2, key3: 3}
iex> %{key1, key2} = m
iex> key1
1
iex> key2
2
```

### Updating maps

```elixir
iex> m = %{key1: 1, key2: 2, key3: 3}
iex> key2 = "new"
iex> %{m | key2, key3: 4}
%{key1: 1, key2: "new", key3: 4}
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
