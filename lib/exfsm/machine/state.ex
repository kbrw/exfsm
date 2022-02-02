defprotocol ExFSM.Machine.State do
  @moduledoc """
  Describes meta FSM state types
  """
  @type name :: ExFSM.State.name()

  @doc """
  Retrieve current state handlers from state object, return [Handler1,Handler2]
  """
  @spec handlers(t) :: [ExFSM.handler()]
  def handlers(state)

  @doc """
  Retrieve current state name from state object
  """
  @spec state_name(t) :: name()
  def state_name(state)

  @doc """
  Set new state name
  """
  @spec set_state_name(t, name) :: t
  def set_state_name(state, name)
end
