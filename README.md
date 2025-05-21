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

### Is there any runtime overhead?

No; the shorthand map keys compile down to exactly the same bytecode as the "vanilla-style" maps.

## Installation

The package can be installed by adding `es6_maps` to your list of dependencies and compilers in `mix.exs`:

```elixir
# mix.exs

def project do
  [
    compilers: [:es6_maps | Mix.compilers()],
    deps: deps()
  ]
end

def deps do
  [
    {:es6_maps, "~> 0.2.2", runtime: false}
  ]
end
```

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

## Converting existing code to use ES6-style maps

`es6_maps` includes a formatting plugin that will convert your existing map and struct literals into the shorthand style.
Add the plugin to `.formatter.exs`, then call `mix format` to reformat your code:

```elixir
# .formatter.exs
[
  plugins: [Es6Maps.Formatter],
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"]
]
```

The plugin manipulates the AST, not raw strings, so it's precise and will only change your code by:

1. changing map keys into the shorthand form;
2. reordering map keys so the shorthand form comes first;
3. formatting the results like `mix format` would.

### Reverting to the vanilla-style maps

The formatting plugin can also be used to revert all of the ES6-style map shorthand uses back to the "vanilla" style.
Set the `es6_maps: [map_style: :vanilla]` option in `.formatter.exs`, then call `mix format` to reformat your code:

```elixir
# .formatter.exs
[
  plugins: [Es6Maps.Formatter],
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  es6_maps: [map_style: :vanilla]
]
```

### Formatting pragmas

The plugin supports pragmas in the comments to control the formatting.
The pragma must be in the form `# es6_maps: [map_style: :es6]` and can be placed anywhere in the file.
The `map_style` option can be set to `:es6` to convert to shorthand form or `:vanilla` to revert to the vanilla-style maps.
The pragma takes effect only on the line following the comment.

For example in the code below, the first map will be formatted to the shorthand form, while the second map will be left as is:

```elixir
  %{foo, bar: 1} = var
  # es6_maps: [map_style: :vanilla]
  %{hello: hello, foo: foo, bar: 1} = var
```

`es6_maps: [map_style: :vanilla]` option in `.formatter.exs` can be combined with `# es6_maps: [map_style: :es6]` comment pragmas.

## How does it work?

`es6_maps` replaces in runtime the Elixir compiler's `:elixir` module.
The module's `string_to_tokens/5` function is wrapped with a function that replaces map keys `%{k}` as if they were `%{k: k}`.
After `es6_maps` runs as one of the Mix compilers, the Elixir compiler will use the replaced functions to compile the rest of the code.

> [!IMPORTANT]
>
> By the nature of this solution it's tightly coupled to the internal Elixir implementation.
> The current version of `es6_maps` should work for Elixir 1.15, 1.16, 1.17, 1.18 and the upcoming 1.19 version, but may break in the future.
