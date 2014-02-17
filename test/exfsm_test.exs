defmodule T do
    require ExFSM

    ExFSM.defsfm fct1({:udateorder, _oparams}) do 
        IO.puts("\nDESC fct1 is => #{inspect @desc} ")
        "f1"
    end

    ExFSM.defsfm fct2({:callfct1, _oparams}), do: "f2"

    ExFSM.defsfm fct3({:fct3, _oparams},_other) do 
        IO.puts("\nDESC fct3 is => #{inspect @desc} ")
        "f3"
    end

end

defmodule ExFSMTest do
use ExUnit.Case

  test "check fct1" do
   assert( "f1" == T.fct1({:udateorder, "oparams"}))
  end

  test "check fct2" do
   assert( "f2" == T.fct2({:callfct1, "oparams"}))
  end

  test "check fct3" do
   assert( "f3" == T.fct3({:fct3, "oparams"},"other"))
  end

  test "check fct desc" do
   assert( "fct1({:udateorder, _oparams})" == T.fct1_desc())
  end

end
