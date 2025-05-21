# Used by "mix format"
[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  plugins: [Es6Maps.Formatter],
  locals_without_parens: [test_formatting: 2]
]
