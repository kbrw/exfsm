defmodule ExFSM.Test.FSM.Light.State do
  @type t :: %__MODULE__{
          usage: non_neg_integer(),
          state: atom()
        }

  @enforced_keys [:state, :usage]
  defstruct @enforced_keys
end

defimpl ExFSM.Machine.State, for: ExFSM.Test.FSM.Light.State do
  def state_name(instance), do: instance.state
  def set_state_name(instance, state_name), do: struct(instance, state: state_name)
  def handlers(_state), do: [ExFSM.Test.FSM.Light]
end

defmodule ExFSM.Test.FSM.Light do
  use ExFSM

  deftrans on({:off, _}, state) do
    {:next_state, :off, state}
  end

  deftrans off({:on, _}, state) when state.usage > 0 do
    {:next_state, :broken, state}
  end

  deftrans off({:on, _}, state) do
    state = Map.update!(state, :usage, &Kernel.+(&1, 1))
    {:next_state, :on, state}
  end
end
