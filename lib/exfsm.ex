defmodule ExFSM do
  @moduledoc """
  After `use ExFSM` : define FSM transition handler with `deftrans fromstate({action_name,params},state)`.
  A function `fsm` will be created returning a map of the `spec` describing the fsm. 

  Destination states are found with AST introspection, if the `{:next_state,xxx,xxx}` is defined
  outside the `deftrans/2` function, you have to define them manually defining a `@to` attribute.

  For instance : 

      iex> defmodule Elixir.Door do
      ...>   use ExFSM
      ...> 
      ...>   @doc "Close to open"
      ...>   @to [:opened]
      ...>   deftrans closed({:open, _}, s) do
      ...>     {:next_state, :opened, s}
      ...>   end
      ...> 
      ...>   @doc "Close to close"
      ...>   deftrans closed({:close, _}, s) do
      ...>     {:next_state, :closed, s}
      ...>   end
      ...> 
      ...>   deftrans closed({:else, _}, s) do
      ...>     {:next_state, :closed, s}
      ...>   end
      ...> 
      ...>   @doc "Open to open"
      ...>   deftrans opened({:open, _}, s) do
      ...>     {:next_state, :opened, s}
      ...>   end
      ...> 
      ...>   @doc "Open to close"
      ...>   @to [:closed]
      ...>   deftrans opened({:close, _}, s) do
      ...>     {:next_state, :closed, s}
      ...>   end
      ...> 
      ...>   deftrans opened({:else, _}, s) do
      ...>     {:next_state, :opened, s}
      ...>   end
      ...> end
      ...> Door.fsm
      %{
        {:closed, :close} => {Door, [:closed]}, {:closed, :else} => {Door, [:closed]},
        {:closed, :open} => {Door, [:opened]}, {:opened, :close} => {Door, [:closed]},
        {:opened, :else} => {Door, [:opened]}, {:opened, :open} => {Door, [:opened]}
      }

      iex> Door.docs
      %{
        {:transition_doc, :closed, :close} => "Close to close",
        {:transition_doc, :closed, :else} => nil,
        {:transition_doc, :closed, :open} => "Close to open",
        {:transition_doc, :opened, :close} => "Open to close",
        {:transition_doc, :opened, :else} => nil,
        {:transition_doc, :opened, :open} => "Open to open"
      }

  """
  alias ExFSM.State

  @type trans :: atom
  @type params :: term
  @type handler :: module

  @type action :: {State.name(), trans}
  @type result :: {handler, [State.name()]}
  @type specs :: %{action => result}
  @type bypasses :: %{trans => handler}

  @type doc_key :: {:transition_doc, State.name(), trans} | {:event_doc, trans}
  @type doc :: String.t()
  @type docs :: %{doc_key => doc}
  @type info :: {:known_transition, doc} | {:bypass, doc}

  @type transition :: ({trans, params}, State.t() -> {:next_state, trans, State.t()})

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
      @doc """
      Returns this handler's FSM as `spec()`
      """
      @spec fsm() :: ExFSM.specs()
      def fsm, do: @fsm

      @doc """
      Returns this handler's FSM bypasses as `spec()`
      """
      @spec event_bypasses() :: ExFSM.bypasses()
      def event_bypasses, do: @bypasses

      @doc """
      Returns this FSM's doc map
      """
      @spec docs() :: ExFSM.docs()
      def docs, do: @docs
    end
  end

  @doc """
  Define a function of type `transition` describing a state and its
  transition. The function name is the state name, the transition is the
  first argument. A state object can be modified and is the second argument.

  ```
  deftrans opened({:close_door, _params}, state) do
    {:next_state, :closed, state}
  end
  ```
  """
  defmacro deftrans({state, _meta, [{trans, _params} | _rest]} = signature, body_block) do
    quote do
      @fsm Map.put(
             @fsm,
             {unquote(state), unquote(trans)},
             {__MODULE__, @to || unquote(Enum.uniq(find_nextstates(body_block[:do])))}
           )
      doc =
        __MODULE__
        |> Module.get_attribute(:doc)
        |> case do
          nil -> nil
          {_line, doc} -> doc
          doc when is_binary(doc) -> doc
        end

      @docs Map.put(@docs, {:transition_doc, unquote(state), unquote(trans)}, doc)
      def unquote(signature), do: unquote(body_block[:do])
      @to nil
    end
  end

  @doc """
  Define a function of type `bypass`, ie which can be applied on any state
  """
  defmacro defbypass({trans, _meta, _args} = signature, body_block) do
    quote do
      @bypasses Map.put(@bypasses, unquote(trans), __MODULE__)
      doc =
        __MODULE__
        |> Module.get_attribute(:doc)
        |> case do
          nil -> nil
          {_line, doc} -> doc
          doc when is_binary(doc) -> doc
        end

      @docs Map.put(@docs, {:event_doc, unquote(trans)}, doc)
      def unquote(signature), do: unquote(body_block[:do])
    end
  end

  ###
  ### Priv
  ###
  defp find_nextstates({:{}, _, [:next_state, state | _]}) when is_atom(state), do: [state]
  defp find_nextstates({_, _, asts}), do: find_nextstates(asts)
  defp find_nextstates({_, asts}), do: find_nextstates(asts)
  defp find_nextstates(asts) when is_list(asts), do: Enum.flat_map(asts, &find_nextstates/1)
  defp find_nextstates(_), do: []
end
