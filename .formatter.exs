export_locals_without_parens = [defbypass: 2, deftrans: 2]

[
  plugins: [ExFSM.FormatterPlugin],
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  locals_without_parens: export_locals_without_parens,
  export: [locals_without_parens: export_locals_without_parens]
]
