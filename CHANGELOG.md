# Changelog

# 1.0.0

## Highlights

### Changed base implementation

`es6_maps` now instruments `:elixir.string_to_tokens/5` instead of `:elixir_map.expand_map/4`.

This is a much less internal API, making it unlikely to break `es6_maps` in the future.
It also plays much better with the broader Elixir ecosystem that's likely to read Elixir code via the tokenizer.
In particular, anything that reads AST will see the "expanded"/"vanilla" map syntax.

For example, previously this wouldn't print a nice assertion diff in ExUnit tests, instead failing inside ExUnit diffing logic:

```elixir
assert %MyStruct{hello, foo: 1} = %MyStruct{foo: 10}
```

Now, it displays a proper diff as ExUnit's code sees the expanded version.

### Runtime instrumentation

`es6_maps` now includes an `Application` implementation that will enable its functionality in runtime.

Simply remove the `runtime: false` parameter from the dependency definition in `Mix.exs` to enable hot-loading es6-style maps in production:

```diff
-      {:es6_maps, "~> 0.2", runtime: false}
+      {:es6_maps, "~> 1.0"}
```

### ElixirLS plugin

`es6_maps` now includes a plugin for ElixirLS that will ensure it's loaded in the language server.

This feature builds on top of both the base implementation change & runtime instrumentation.
ElixirLS will see and analyze the expanded code.

## 1.0.2

### Features

- Split bytecode injection code to a separate package [`beam_patch`](https://github.com/kzemek/beam_patch)

  The bytecode injection functionality of `es6_maps` is useful for other projects as well.
  [`beam_patch`](https://github.com/kzemek/beam_patch) is already a more advanced and robust version than the original `es6_maps` code.

## 1.0.1

### Features

- Pre-prepare the injected `:elixir` bytecode on compile

  In releases and other environments with stripped beam files, we don't have access to `:abstract_code` chunk of the `:elixir` module.
  Pre-preparing bytecode on compile allows us to load `es6_maps` in these runtime environments.
