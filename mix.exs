defmodule ExFSM.Mixfile do
  use Mix.Project

  def project do
    [ app: :exfsm,
      version: "0.1.1",     
      elixir: "~> 1.2.0",     
      build_embedded: Mix.env == :prod,
      consolidate_protocols: Mix.env != :test,
      docs: [
        main: "ExFSM",
        source_url: "https://github.com/awetzel/exfsm",
        source_ref: "master"
      ],
      description: """
        Simple elixir library to define composable FSM as function
        (not related at all with `:gen_fsm`, no state/process management)
      """,
     package: [
       maintainers: ["Arnaud Wetzel"],
       licenses: ["MIT"],
       links: %{"GitHub" => "https://github.com/awetzel/exfsm", "Doc"=>"http://hexdocs.pm/exfsm"}
     ],
      deps: [{:ex_doc, ">= 0.11.0", only: :dev},{:earmark, ">= 0.0.0", only: :dev}] ]
  end
end
