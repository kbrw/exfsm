defmodule ExFSM.FormatterPlugin do
  @moduledoc """
  A `mix format` plugin registering the `~FSM` sigil used to describe an FSM
  (see `ExFSM.sigil_FSM/2`).

  The formatter aligns the input states on the same column and does the same to
  the actions and the output states by adding padding to the separators `--` and
  `->`.

  Enable it in `.formatter.exs`:

      [
        plugins: [ExFSM.FormatterPlugin],
        # ...
      ]
  """

  @behaviour Mix.Tasks.Format

  @impl Mix.Tasks.Format
  def features(_opts), do: [sigils: [:FSM]]

  @impl Mix.Tasks.Format
  def format(contents, _opts) do
    rows =
      contents
      |> String.split("\n")
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))
      |> Enum.map(&parse/1)

    case rows do
      [] ->
        ""

      rows ->
        state_pad = rows |> Enum.map(&String.length(elem(&1, 0))) |> Enum.max()
        event_pad = rows |> Enum.map(&String.length(elem(&1, 1))) |> Enum.max()

        rows
        |> Enum.map_join("\n", fn {state_in, event, state_out} ->
          state_in = String.pad_trailing(state_in, state_pad)
          event = String.pad_trailing(event, event_pad)
          "#{state_in} -- #{event} -> #{state_out}"
        end)
        |> Kernel.<>("\n")
    end
  end

  defp parse(line) do
    [lhs, state_out] = String.split(line, "->", parts: 2)
    [state_in, event] = String.split(lhs, "--", parts: 2)
    {String.trim(state_in), String.trim(event), String.trim(state_out)}
  end
end
