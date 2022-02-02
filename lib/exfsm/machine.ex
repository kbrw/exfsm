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
      ...>   deftrans closed({:open_door, _}, s), do: {:next_state, :opened, s}
      ...> end
      ...>
      ...> defmodule Elixir.Door2 do
      ...>   use ExFSM
      ...>
      ...>   @doc "allow multiple closes"
      ...>   defbypass close_door(_, s), do: {:keep_state, Map.put(s, :doubleclosed, true)}
      ...>
      ...>   @doc "standard door open"
      ...>   deftrans opened({:close_door, _}, s), do: {:next_state, :closed, s}
      ...> end
      ...>
      ...> ExFSM.Machine.fsm([Door1, Door2])
      %{
        {:closed, :open_door} => {Door1, [:opened]},
        {:opened, :close_door} => {Door2, [:closed]}
      }
      iex> ExFSM.Machine.event_bypasses([Door1, Door2])
      %{close_door: Door2}
      iex> defmodule Elixir.DoorState do
      ...>   defstruct(handlers: [Door1, Door2], state: nil, doubleclosed: false)
      ...> end
      ...>
      ...> defimpl ExFSM.Machine.State, for: DoorState do
      ...>   def handlers(d), do: d.handlers
      ...>
      ...>   def state_name(d), do: d.state
      ...>
      ...>   def set_state_name(d, name), do: %{d | state: name}
      ...> end
      ...>
      ...> struct(DoorState, state: :closed) |> ExFSM.Machine.event({:open_door, nil})
      {:next_state, %{__struct__: DoorState, handlers: [Door1, Door2], state: :opened, doubleclosed: false}}
      ...> struct(DoorState, state: :closed) |> ExFSM.Machine.event({:close_door, nil})
      {:next_state, %{__struct__: DoorState, handlers: [Door1, Door2], state: :closed, doubleclosed: true}}
      iex> ExFSM.Machine.find_info(struct(DoorState, state: :opened), :close_door)
      {:known_transition, "standard door open"}
      iex> ExFSM.Machine.find_info(struct(DoorState, state: :closed), :close_door)
      {:bypass, "allow multiple closes"}
      iex> ExFSM.Machine.available_actions(struct(DoorState, state: :closed))
      [:open_door, :close_door]
  """
  alias ExFSM.Machine.State

  @type meta_event_error :: :illegal_action | term
  @type meta_event_reply ::
          {:next_state, State.t()}
          | {:next_state, State.t(), timeout :: integer}
          | {:keep_state, State.t()}
          | {:error, meta_event_error}

  @doc """
  Returns `ExFSM.specs()` built from all handlers
  """
  @spec fsm([ExFSM.handler()] | State.t()) :: ExFSM.specs()
  def fsm(handlers) when is_list(handlers) do
    handlers
    |> Enum.map(& &1.fsm)
    |> Enum.concat()
    |> Enum.into(%{})
  end

  def fsm(state), do: fsm(State.handlers(state))

  @doc """
  Returns global bypasses
  """
  @spec event_bypasses([ExFSM.handler()] | State.t()) :: ExFSM.bypasses()
  def event_bypasses(handlers) when is_list(handlers),
    do: handlers |> Enum.map(& &1.event_bypasses) |> Enum.concat() |> Enum.into(%{})

  def event_bypasses(state), do: event_bypasses(State.handlers(state))

  @doc """
  Returns handler for given action, if any
  """
  @spec find_handler(ExFSM.action(), [ExFSM.handler()]) :: ExFSM.handler() | nil
  def find_handler({state_name, trans}, handlers) when is_list(handlers) do
    handlers
    |> fsm()
    |> Map.get({state_name, trans})
    |> case do
      {handler, _} -> handler
      _ -> nil
    end
  end

  @doc """
  Same as `find_handler/2` but using a 'meta' state implementing
  `ExFSM.Machine.State`
  """
  @spec find_handler({[ExFSM.handler()], ExFSM.trans()}) :: ExFSM.handler() | nil
  def find_handler({state, trans}) do
    {State.state_name(state), trans}
    |> find_handler(State.handlers(state))
  end

  @doc """
  Find bypass
  """
  @spec find_bypass([ExFSM.handler()] | ExFSM.state(), ExFSM.trans()) :: ExFSM.handler() | nil
  def find_bypass(handlers_or_state, trans) do
    event_bypasses(handlers_or_state)[trans]
  end

  @doc """
  Returns global doc
  """
  @spec infos([ExFSM.handler()] | ExFSM.state(), ExFSM.trans()) :: ExFSM.docs()
  def infos(handlers, _trans) when is_list(handlers) do
    handlers
    |> Enum.map(& &1.docs)
    |> Enum.concat()
    |> Enum.into(%{})
  end

  def infos(state, action) do
    state
    |> State.handlers()
    |> infos(action)
  end

  @doc """
  Returns info for particular transition
  """
  @spec find_info(ExFSM.state(), ExFSM.trans()) :: ExFSM.info() | nil
  def find_info(state, trans) do
    docs = infos(state, trans)

    docs
    |> Map.get({:transition_doc, State.state_name(state), trans})
    |> case do
      nil ->
        find_bypass_info(docs, trans)

      doc ->
        {:known_transition, doc}
    end
  end

  @doc """
  Meta application of the transition function, using `find_handler/2`
  to find the module implementing it.
  """
  @spec event(State.t(), {ExFSM.trans(), term}) :: meta_event_reply
  def event(state, {trans, params}) do
    {state, trans}
    |> find_handler()
    |> case do
      nil ->
        do_find_bypass(state, trans, params)

      handler ->
        do_apply_event(handler, state, trans, params)
    end
  end

  @doc """
  Returns available actions
  """
  @spec available_actions(State.t()) :: [ExFSM.trans()]
  def available_actions(state) do
    fsm_actions =
      state
      |> ExFSM.Machine.fsm()
      |> Enum.filter(fn {{from, _}, _} -> from == State.state_name(state) end)
      |> Enum.map(fn {{_, action}, _} -> action end)

    bypasses_actions =
      state
      |> ExFSM.Machine.event_bypasses()
      |> Map.keys()

    Enum.uniq(fsm_actions ++ bypasses_actions)
  end

  @doc """
  Returns true if given action is available
  """
  @spec action_available?(State.t(), ExFSM.trans()) :: boolean
  def action_available?(state, action) do
    action in available_actions(state)
  end

  ###
  ### Priv
  ###
  defp do_find_bypass(state, action, params) do
    state
    |> find_bypass(action)
    |> case do
      nil ->
        {:error, :illegal_action}

      handler ->
        do_apply_bypass(handler, state, action, params)
    end
  end

  defp do_apply_bypass(handler, state, action, params) do
    res =
      try do
        apply(handler, action, [params, state])
      rescue
        FunctionClauseError ->
          {:error, :illegal_action}
      end

    case res do
      {:keep_state, state} ->
        {:next_state, state}

      {:next_state, state_name, state, timeout} ->
        {:next_state, State.set_state_name(state, state_name), timeout}

      {:next_state, state_name, state} ->
        {:next_state, State.set_state_name(state, state_name)}

      {:error, _} = e ->
        e

      _other ->
        orig = State.state_name(state)
        raise ExFSM.Error, handler: handler, statename: orig, action: action
    end
  end

  defp do_apply_event(handler, state, action, params) do
    orig = State.state_name(state)

    res =
      try do
        apply(handler, orig, [{action, params}, state])
      rescue
        FunctionClauseError ->
          {:error, :illegal_action}
      end

    case res do
      {:next_state, state_name, state, timeout} when is_integer(timeout) ->
        {:next_state, State.set_state_name(state, state_name), timeout}

      {:next_state, state_name, state} ->
        {:next_state, State.set_state_name(state, state_name)}

      {:error, _} = e ->
        e

      _other ->
        raise ExFSM.Error, handler: handler, statename: orig, action: action
    end
  end

  defp find_bypass_info(docs, action) do
    docs
    |> Map.get({:event_doc, action})
    |> case do
      nil ->
        nil

      doc ->
        {:bypass, doc}
    end
  end
end
