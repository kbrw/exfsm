defmodule ExFSM.Mixfile do
  use Mix.Project

  def project do
    [ app: :exfsm,
      version: "0.0.3",     
      elixir: "~> 1.0.0",     
      docs: [
        main: "ExFSM",
        source_url: "https://github.com/awetzel/exfsm",
        source_ref: "master"
      ],
      description: """
        Simple elixir library to define composable FSM as function
        (not related at all with `:gen_fsm`, no state/process management)
      """,
      package: [links: %{"Source"=>"http://github.com/awetzel/exfsm",
                         "Doc"=>"http://hexdocs.pm/exfsm"},
                contributors: ["Arnaud Wetzel"],
                licenses: ["MIT"]],
      deps: [{:ex_doc, only: :dev}] ]
  end
end
