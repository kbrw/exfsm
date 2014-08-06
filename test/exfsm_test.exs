defmodule T1 do
  use ExFSM
  deftrans state1({:trans1, _oparams},s) do
    case "coucou" do
      "coucou" -> {:newstate,:state2,s}
      _ -> {:newstate,:state1,s}
    end
  end 
  deftrans state2({:trans1, _oparams1},s) do 
    {:newstate,:state3,s}
  end
  deftrans state3({:trans2, _oparams2},s) do
    {:newstate,:state1,s,10}
  end
end
defmodule T2 do
  use ExFSM
  deftrans state2({:trans2, _},s) do
    {:newstate,:state2,s}
  end
end

defmodule Obj do
  defstruct handlers: []
  defimpl ExFSM.Obj, for: Obj do
    def handlers(obj), do: obj.handlers
    def save(_obj,_state,_transition), do: :ok
  end
end

defmodule ExFSMTest do
use ExUnit.Case

  test "check single fsm desc" do
    assert T1.fsm == %{
        {:state1,:trans1}=>{T1,[:state2,:state1]},
        {:state2,:trans1}=>{T1,[:state3]},
        {:state3,:trans2}=>{T1,[:state1]}
      }
  end

  test "check multiple handlers fsm" do
   assert ExFSM.fsm(%Obj{handlers: [T1,T2]}) == %{
        {:state1,:trans1}=>{T1,[:state2,:state1]},
        {:state2,:trans1}=>{T1,[:state3]},
        {:state3,:trans2}=>{T1,[:state1]},
        {:state2,:trans2}=>{T2,[:state2]},
      }
  end
end
