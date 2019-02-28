# If you find anything wrong or unclear in this file, please report an
# issue on GitHub: https://github.com/rrrene/credo/issues
#
%{
  #
  configs: [
    %{
      name: "default",
      files: %{
        included: ["lib/", "src/", "test/"],
        excluded: [~r"/_build/", ~r"/deps/"]
      },
      requires: [],
      strict: false,
      color: true
    }
  ]
}
