# Changelog

# 1.0.0 (Unreleased)

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
