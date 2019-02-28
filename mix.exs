defmodule ExFSM.Mixfile do
  use Mix.Project

  def project do
    [
      app: :exfsm,
      version: "0.1.5",
      elixir: ">= 1.2.0",
      build_embedded: Mix.env() == :prod,
      consolidate_protocols: Mix.env() != :test,
      docs: docs(),
      description: description(),
      package: package(),
      deps: deps(),
      dialyzer: [plt_add_deps: :project]
    ]
  end

  defp docs,
    do: [
      main: "ExFSM",
      source_url: "https://github.com/kbrw/exfsm",
      source_ref: "master"
    ]

  defp description,
    do: """
    Simple elixir library to define composable FSM as function
    (not related at all with `:gen_fsm`, no state/process management)
    """

  defp package,
    do: [
      maintainers: ["Arnaud Wetzel"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/kbrw/exfsm",
        "Doc" => "http://hexdocs.pm/exfsm"
      }
    ]

  defp deps,
    do: [
      # Dev only
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:credo, ">= 0.0.0", only: :dev},
      {:dialyxir, ">= 0.0.0", only: :dev}
    ]
end
