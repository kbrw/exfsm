defmodule T do
    use ExFSM

    defsfm fct1({:udateorder, _oparams}) do 
        IO.puts("\nDESC fct1 is => #{inspect @desc} ")
        "f1"
    end
 Macro.expand(
    defsfm fct2({:trans2, _oparams}) do
       IO.puts("\nDESC fct2 is => #{inspect @desc} ")
       "f2"
    end )

    defsfm fct3({:trans3, _oparams},_other) do 
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
   assert( "f2" == T.fct2({:trans2, "oparams"}))
  end

  test "check fct3" do
   assert( "f3" == T.fct3({:trans3, "oparams"},"other"))
  end

  test "check fct desc" do
   assert( "fct1({:udateorder, _oparams})" == T.fct1_desc())
  end

  test "check desc" do
   dic = T.desc()
   IO.puts("\nDESC dic is => #{inspect dic} ")
   assert( Dict.has_key? dic, "fct1")
   assert( Dict.has_key? dic, "fct2")
   assert( Dict.has_key? dic, "fct3")
  end
end
