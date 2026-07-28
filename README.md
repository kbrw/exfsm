# ExFSM #

[![Build Status](https://github.com/kbrw/exfsm/actions/workflows/.github/workflows/ci.yml/badge.svg)](https://github.com/kbrw/exfsm/actions/workflows/ci.yml)

Simple Elixir library to define composable [mealy
FSM](https://en.wikipedia.org/wiki/Mealy_machine) as function
(not related at all with `:gen_fsm`, no state/process management).

```elixir
defmodule Light do
  use ExFSM

  deftrans on({:off, _}, state), do: {:next_state, :off, state}
  deftrans off({:on, _}, state), do: {:next_state, :on, state}
end

defmodule Light.State do
  @enforced_keys [:state]
  defstruct  @enforced_keys
end

defimpl ExFSM.Machine.State, for: Light.State do
  def state_name(state), do: state.state
  def set_state_name(state, state_name), do: struct(state, state: state_name)
  def handlers(_state), do: [Light]
end

{:next_state, %_{state: :off} = state} = ExFSM.Machine.event({:on, nil},  %Light{state: :off})
{:next_state, %_{state: :on} = state} =  ExFSM.Machine.event({:off, nil}, %Light{state: :on})
{:error, :illegal_action} =              ExFSM.Machine.event({:on, nil},  %Light{state: :on})
```

- define an FSM with handler modules defining each transition as a simple function but using a
 macro `deftrans` which creates a function `fsm` returning the fsm transition map for this handler module.
- `deftrans` has the same semantic as [erlang in memory FSM gen_fsm](http://www.erlang.org/doc/man/gen_fsm.html)
- combine together multiple FSM handlers to create a "meta" FSM.
- send event with the function `event` which simply find the right
  handler, execute the handler function.

## Usage ##

See in [in code documentation](http://hexdocs.pm/exfsm)

# CONTRIBUTING

Hi, and thank you for wanting to contribute.
Please refer to the centralized informations available at: https://github.com/kbrw\#contributing

