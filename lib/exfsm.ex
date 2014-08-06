defmodule ExFSM do

  defmacro __before_compile__(_env) do
    quote do
      def fsm, do: @fsm 
    end
  end

  defmacro __using__(_opts) do
    quote do
      import ExFSM
      @fsm %{}
      @before_compile ExFSM
    end
  end

  defmacro deftrans({state,_meta,[{trans,_param}|_rest]}=head, [do: body]) do
    quote do
      @fsm Dict.put(@fsm,{unquote(state),unquote(trans)},{__MODULE__,unquote(find_newstates(body))})
      def unquote(head), do: unquote(body)
    end  
  end

  def find_newstates({:{},_,[:newstate,state|_]}), do: [state]
  def find_newstates({_,_,asts}), do: find_newstates(asts)
  def find_newstates({_,asts}), do: find_newstates(asts)
  def find_newstates(asts) when is_list(asts), do: Enum.flat_map(asts,&find_newstates/1)
  def find_newstates(_), do: []

  defprotocol Obj do
    @doc "retrieve current state handlers from state object, return [Handler1,Handler2]"
    def handlers(obj)
    @doc "save current state and transition"
    def save(obj,state,transition)
  end

  def fsm(obj), do:
    (obj |> Obj.handlers |> Enum.map(&(&1.fsm)) |> Enum.concat |> Enum.into(%{}))

  def apply(obj,{action,params}) do
    {state,trans,ts} = Obj.state_info(obj)
    case Dict.get(fsm(obj),{state,action}) do
      {handler,_deststates}->
        Obj.save(obj,state,action)
        case apply(handler,state,[{action,params},obj]) do
          {:newstate,newstate,newobj}-> 
            Obj.save(newobj,newstate,nil)
        end
      _ -> {:transition_impossible,state,action}
    end
  end
end

