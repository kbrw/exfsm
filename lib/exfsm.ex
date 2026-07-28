defmodule ExFSM do
  @moduledoc """
  Module to define an FSM.

  After `use ExFSM`: define FSM transition handler with `deftrans
  fromstate({action_name,params},state)`. A function `fsm/0` will be created
  returning a map of the `t:fsm_spec/0` describing the FSM.

  Destination states are found with AST introspection, if the
  `{:next_state,xxx,xxx}` is defined outside the `deftrans/2` function, you
  have to define them manually via a `@to` attribute.

  For instance:

      iex> defmodule Elixir.Door do
      ...>   use ExFSM
      ...>
      ...>   @transition_doc "Close to open"
      ...>   @to [:opened]
      ...>   deftrans closed({:open, _}, s) do
      ...>     {:next_state, :opened, s}
      ...>   end
      ...>
      ...>   @transition_doc "Close to close"
      ...>   deftrans closed({:close, _}, s) do
      ...>     {:next_state, :closed, s}
      ...>   end
      ...>
      ...>   @transition_doc "Close to close"
      ...>   deftrans closed({:else, _}, s) do
      ...>     {:next_state, :closed, s}
      ...>   end
      ...>
      ...>   @transition_doc "Open to open"
      ...>   deftrans opened({:open, _}, s) do
      ...>     {:next_state, :opened, s}
      ...>   end
      ...>
      ...>   @transition_doc "Open to close"
      ...>   @to [:closed]
      ...>   deftrans opened({:close, _}, s) do
      ...>     {:next_state, :closed, s}
      ...>   end
      ...>
      ...>   @transition_doc "Open to open"
      ...>   deftrans opened({:else, _}, s) do
      ...>     {:next_state, :opened, s}
      ...>   end
      ...> end
      ...> Door.fsm()
      %{{:closed, :close} => {Door, [:closed]}, {:closed, :else} => {Door, [:closed]},
        {:closed, :open} => {Door, [:opened]}, {:opened, :close} => {Door, [:closed]},
        {:opened, :else} => {Door, [:opened]}, {:opened, :open} => {Door, [:opened]}}
      iex> Door.docs()
      %{
        {:transition_doc, :closed, :close} => "Close to close",
        {:transition_doc, :closed, :else} => "Close to close",
        {:transition_doc, :closed, :open} => "Close to open",
        {:transition_doc, :opened, :close} => "Open to close",
        {:transition_doc, :opened, :else} => "Open to open",
        {:transition_doc, :opened, :open} => "Open to open"
      }
  """

  @typedoc "A module which `use ExFSM` and defines an FSM."
  @type handler :: module()
  @type state_name :: atom()

  @type event :: {action_name, event_payload}
  @type action_name :: atom()
  @type event_payload :: term()

  @type fsm_spec :: %{
          {state_name(), event_name :: action_name()} =>
            {exfsm_module :: handler(), [dest_statename :: state_name()]}
        }

  defmacro __using__(_opts) do
    quote do
      import ExFSM
      @fsm %{}
      @bypasses %{}
      @docs %{}
      @to nil
      @before_compile ExFSM
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def fsm, do: @fsm
      def event_bypasses, do: @bypasses
      def docs, do: @docs
    end
  end

  @doc """
  Defines a transition function.

  The function name is the state name, the transition is the first argument. A
  state object can be modified and is the second argument.

      deftrans opened({:close_door,_params},state) do
        {:next_state,:closed,state}
      end

  The transition function has the following signature:
  ```elixir
    (event, state ->
        {:next_state, state_name, state}
        | {:next_state, state_name, state, timeout}
        | term()
    when event: ExFSM.event(),
         state_name: ExFSM.state_name(),
         state: ExFSM.Machine.State.t(),
         timeout: non_neg_integer() | :infinity
  ```
  """
  defmacro deftrans(signature, body_block) do
    {state, transition} =
      case signature do
        {:when, _, _} ->
          {:when, _, [{state, _, [{transition, _} | _]} | _]} = signature

          {state, transition}

        _ ->
          {state, _, [{transition, _} | _]} = signature

          {state, transition}
      end

    quote do
      output_states =
        if is_list(@to),
          do: @to,
          else: unquote(Enum.uniq(find_nextstates(body_block[:do])))

      @fsm Map.update(
             @fsm,
             {unquote(state), unquote(transition)},
             {__MODULE__, output_states},
             fn {module, prev_output_state} ->
               {module, Enum.uniq(prev_output_state ++ output_states)}
             end
           )
      doc = Module.get_attribute(__MODULE__, :transition_doc)
      @docs Map.put(@docs, {:transition_doc, unquote(state), unquote(transition)}, doc)
      def unquote(signature), do: unquote(body_block[:do])
      @transition_doc nil
      @to nil
    end
  end

  defp find_nextstates({:{}, _, [:next_state, state | _]}) when is_atom(state), do: [state]
  defp find_nextstates({_, _, asts}), do: find_nextstates(asts)
  defp find_nextstates({_, asts}), do: find_nextstates(asts)
  defp find_nextstates(asts) when is_list(asts), do: Enum.flat_map(asts, &find_nextstates/1)
  defp find_nextstates(_), do: []

  defmacro defbypass(signature, body_block) do
    event =
      case signature do
        {:when, _, _} ->
          {:when, _, [{event, _, _} | _]} = signature

          event

        _ ->
          {event, _, _} = signature

          event
      end

    quote do
      @bypasses Map.put(@bypasses, unquote(event), __MODULE__)
      doc = Module.get_attribute(__MODULE__, :bypass_doc)
      @docs Map.put(@docs, {:event_doc, unquote(event)}, doc)
      def unquote(signature), do: unquote(body_block[:do])
      @bypass_doc nil
    end
  end
end

defmodule ExFSM.Machine do
  @moduledoc """
  Module to simply use FSMs defined with `ExFSM`:

  - `ExFSM.Machine.fsm/1` merges FSMs from multiple handlers.
  - `ExFSM.Machine.event_bypasses/1` merges bypasses from multiple handlers.
  - `ExFSM.Machine.event/2` allows you to execute the correct handler from a
  state and action

  Defines a structure implementing `ExFSM.Machine.State` in order to define how
  to extract handlers and state_name from state, and how to apply state_name
  change. Then use `ExFSM.Machine.event/2` in order to execute transition.

      iex> defmodule Elixir.Door1 do
      ...>   use ExFSM
      ...>   deftrans closed({:open_door,_},s) do {:next_state,:opened,s} end
      ...> end
      ...> defmodule Elixir.Door2 do
      ...>   use ExFSM
      ...>   @bypass_doc "allow multiple closes"
      ...>   defbypass close_door(_,s), do: {:keep_state,Map.put(s,:doubleclosed,true)}
      ...>   @transition_doc "standard door open"
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
    @typedoc "All types that implement this protocol."
    @type t :: term()

    @doc "Gets `state`'s FSM handler modules."
    @spec handlers(t()) :: [ExFSM.handler()]
    def handlers(state)
    @doc "Gets `state`'s state_name."
    @spec state_name(t()) :: ExFSM.state_name()
    def state_name(state)
    @doc "Sets `state`'s state_name with `state_name`."
    @spec set_state_name(t(), ExFSM.state_name()) :: t()
    def set_state_name(state, state_name)
  end

  @doc "Returns the FSM as a map of transitions `%{{state_name, action} => {handler, [dest_states]}}` based on handlers"
  @spec fsm([exfsm_module :: ExFSM.handler()]) :: ExFSM.fsm_spec()
  def fsm(handlers) when is_list(handlers),
    do: handlers |> Enum.map(& &1.fsm()) |> Enum.concat() |> Enum.into(%{})

  def fsm(state), do: fsm(State.handlers(state))

  def event_bypasses(handlers) when is_list(handlers),
    do: handlers |> Enum.map(& &1.event_bypasses()) |> Enum.concat() |> Enum.into(%{})

  def event_bypasses(state), do: event_bypasses(State.handlers(state))

  @doc "Finds the ExFSM module from the list `handlers` implementing the event `action` from `state_name`"
  @spec find_handler({ExFSM.state_name(), ExFSM.action_name()}, [ExFSM.handler()]) ::
          ExFSM.handler()
  def find_handler({state_name, action}, handlers) when is_list(handlers) do
    case Map.get(fsm(handlers), {state_name, action}) do
      {handler, _} -> handler
      _ -> nil
    end
  end

  @doc "Same as `find_handler/2` but uses a `t:ExFSM.Machine.State.t/0` from which state_name and handlers are retrieved."
  @spec find_handler({ExFSM.Machine.State.t(), ExFSM.action_name()}) :: ExFSM.handler()
  def find_handler({state, action}),
    do: find_handler({State.state_name(state), action}, State.handlers(state))

  def find_bypass(handlers_or_state, action) do
    event_bypasses(handlers_or_state)[action]
  end

  def infos(handlers, _action) when is_list(handlers) do
    handlers |> Enum.map(& &1.docs()) |> Enum.concat() |> Enum.into(%{})
  end

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
  Executes a transition from `state`'s state_name with the given `event`.

  If no handler module can handle the transition, the event function attempt to
  retrieve an handler which can handle a bypass with the given action. If no
  handler module can handle the bypass, `{:error, :illegal_action}` is
  returned.
  """
  @spec event(ExFSM.Machine.State.t(), ExFSM.event()) ::
          {:next_state, ExFSM.Machine.State.t()}
          | {:next_state, ExFSM.Machine.State.t(), timeout :: non_neg_integer() | :infinity}
          | {:error, :illegal_action}
          | term()
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

  @spec available_actions(ExFSM.Machine.State.t()) :: [ExFSM.action_name()]
  def available_actions(state) do
    fsm_actions =
      ExFSM.Machine.fsm(state)
      |> Enum.filter(fn {{from, _}, _} -> from == State.state_name(state) end)
      |> Enum.map(fn {{_, action}, _} -> action end)

    bypasses_actions = ExFSM.Machine.event_bypasses(state) |> Map.keys()
    Enum.uniq(fsm_actions ++ bypasses_actions)
  end

  @spec action_available?(ExFSM.Machine.State.t(), ExFSM.action_name()) :: boolean()
  def action_available?(state, action) do
    action in available_actions(state)
  end
end
