defmodule ExFSM.Machine do
  @moduledoc """
  Module to simply use FSMs defined with ExFSM : 

  - `ExFSM.Machine.fsm/1` merge fsm from multiple handlers (see `ExFSM` to see how to define one).
  - `ExFSM.Machine.event_bypasses/1` merge bypasses from multiple handlers (see `ExFSM` to see how to define one).
  - `ExFSM.Machine.event/2` allows you to execute the correct handler from a state and action

  Define a structure implementing `ExFSM.Machine.State` in order to
  define how to extract handlers and state_name from state, and how
  to apply state_name change. Then use `ExFSM.Machine.event/2` in order
  to execute transition.

      iex> defmodule Elixir.Door1 do
      ...>   use ExFSM
      ...>   deftrans closed({:open_door,_},s) do {:next_state,:opened,s} end
      ...> end
      ...> defmodule Elixir.Door2 do
      ...>   use ExFSM
      ...>   @doc "allow multiple closes"
      ...>   defbypass close_door(_,s), do: {:keep_state,Map.put(s,:doubleclosed,true)}
      ...>   @doc "standard door open"
      ...>   deftrans opened({:close_door,_},s) do {:next_state,:closed,s} end
      ...> end
      ...> ExFSM.Machine.fsm([Door1,Door2])
      %{
        {:closed,:open_door}=>{Door1,[:opened]},
        {:opened,:close_door}=>{Door2,[:closed]}
      }
      iex> ExFSM.Machine.event_bypasses([Door1,Door2])
      %{close_door: Door2}
      iex> defmodule Elixir.DoorState do defstruct(handlers: [Door1,Door2], state: nil, doubleclosed: false) end
      ...> defimpl ExFSM.Machine.State, for: DoorState do
      ...>   def handlers(d) do d.handlers end
      ...>   def state_name(d) do d.state end
      ...>   def set_state_name(d,name) do %{d|state: name} end
      ...> end
      ...> struct(DoorState, state: :closed) |> ExFSM.Machine.event({:open_door,nil})
      {:next_state,%{__struct__: DoorState, handlers: [Door1,Door2],state: :opened, doubleclosed: false}}
      ...> struct(DoorState, state: :closed) |> ExFSM.Machine.event({:close_door,nil})
      {:next_state,%{__struct__: DoorState, handlers: [Door1,Door2],state: :closed, doubleclosed: true}}
      iex> ExFSM.Machine.find_info(struct(DoorState, state: :opened),:close_door)
      {:known_transition,"standard door open"}
      iex> ExFSM.Machine.find_info(struct(DoorState, state: :closed),:close_door)
      {:bypass,"allow multiple closes"}
      iex> ExFSM.Machine.available_actions(struct(DoorState, state: :closed))
      [:open_door,:close_door]
  """

  defprotocol State do
    @doc """
    Retrieve current state handlers from state object, return [Handler1,Handler2]
    """
    def handlers(state)

    @doc """
    Retrieve current state name from state object
    """
    def state_name(state)

    @doc """
    Set new state name
    """
    def set_state_name(state, state_name)
  end

  @doc """
  Return the FSM as a map of transitions
  %{{state,action}=>{handler,[dest_states]}} based on handlers
  """
  @spec fsm([exfsm_module :: atom]) :: ExFSM.fsm_spec()
  def fsm(handlers) when is_list(handlers),
    do: handlers |> Enum.map(& &1.fsm) |> Enum.concat() |> Enum.into(%{})

  def fsm(state), do: fsm(State.handlers(state))

  def event_bypasses(handlers) when is_list(handlers),
    do: handlers |> Enum.map(& &1.event_bypasses) |> Enum.concat() |> Enum.into(%{})

  def event_bypasses(state), do: event_bypasses(State.handlers(state))

  @doc """
  Find the ExFSM Module from the list `handlers` implementing the
  event `action` from `state_name`
  """
  @spec find_handler({state_name :: atom, event_name :: atom}, [exfsm_module :: atom]) ::
          exfsm_module :: atom
  def find_handler({state_name, action}, handlers) when is_list(handlers) do
    case Map.get(fsm(handlers), {state_name, action}) do
      {handler, _} -> handler
      _ -> nil
    end
  end

  @doc """
  Same as `find_handler/2` but using a 'meta' state implementing
  `ExFSM.Machine.State`
  """
  def find_handler({state, action}),
    do: find_handler({State.state_name(state), action}, State.handlers(state))

  def find_bypass(handlers_or_state, action) do
    event_bypasses(handlers_or_state)[action]
  end

  def infos(handlers, _action) when is_list(handlers),
    do: handlers |> Enum.map(& &1.docs) |> Enum.concat() |> Enum.into(%{})

  def infos(state, action), do: infos(State.handlers(state), action)

  def find_info(state, action) do
    docs = infos(state, action)

    if doc = docs[{:transition_doc, State.state_name(state), action}] do
      {:known_transition, doc}
    else
      {:bypass, docs[{:event_doc, action}]}
    end
  end

  @doc """
  Meta application of the transition function, using `find_handler/2`
  to find the module implementing it.
  """
  @type meta_event_reply ::
          {:next_state, ExFSM.Machine.State.t()}
          | {:next_state, ExFSM.Machine.State.t(), timeout :: integer}
          | {:error, :illegal_action}
  @spec event(ExFSM.Machine.State.t(), {event_name :: atom, event_params :: any}) ::
          meta_event_reply
  def event(state, {action, params}) do
    case find_handler({state, action}) do
      nil ->
        case find_bypass(state, action) do
          nil ->
            {:error, :illegal_action}

          handler ->
            case apply(handler, action, [params, state]) do
              {:keep_state, state} ->
                {:next_state, state}

              {:next_state, state_name, state, timeout} ->
                {:next_state, State.set_state_name(state, state_name), timeout}

              {:next_state, state_name, state} ->
                {:next_state, State.set_state_name(state, state_name)}

              other ->
                other
            end
        end

      handler ->
        case apply(handler, State.state_name(state), [{action, params}, state]) do
          {:next_state, state_name, state, timeout} ->
            {:next_state, State.set_state_name(state, state_name), timeout}

          {:next_state, state_name, state} ->
            {:next_state, State.set_state_name(state, state_name)}

          other ->
            other
        end
    end
  end

  @spec available_actions(ExFSM.Machine.State.t()) :: [action_name :: atom]
  def available_actions(state) do
    fsm_actions =
      ExFSM.Machine.fsm(state)
      |> Enum.filter(fn {{from, _}, _} -> from == State.state_name(state) end)
      |> Enum.map(fn {{_, action}, _} -> action end)

    bypasses_actions = ExFSM.Machine.event_bypasses(state) |> Map.keys()
    Enum.uniq(fsm_actions ++ bypasses_actions)
  end

  @spec action_available?(ExFSM.Machine.State.t(), action_name :: atom) :: boolean
  def action_available?(state, action) do
    action in available_actions(state)
  end
end
