defmodule ExFSM.Dummy.FSM.Instance do
  @moduledoc false

  @type t :: %__MODULE__{
          type: atom(),
          state: atom()
        }

  @behaviour Access

  defstruct type: nil, state: nil

  @impl Access
  defdelegate fetch(obj, key), to: Map

  @impl Access
  defdelegate get_and_update(data, key, function), to: Map

  @impl Access
  defdelegate pop(data, key), to: Map
end

defimpl ExFSM.Machine.State, for: ExFSM.Dummy.FSM.Instance do
  def state_name(instance), do: instance.state
  def set_state_name(instance, state_name), do: Map.put(instance, :state, state_name)
  def handlers(_state), do: [ExFSM.Dummy.FSM]
end

defmodule ExFSM.Dummy.FSM do
  @moduledoc false

  use ExFSM

  deftrans opened({:close, _}, state), do: {:next_state, :closed, state}
  deftrans closed({:open, _}, state), do: {:next_state, :opened, state}
end
