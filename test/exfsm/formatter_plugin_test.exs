defmodule ExFSM.FormatterPluginTest do
  use ExUnit.Case

  describe "ExFSM.FormatterPlugin" do
    test "registers the ~FSM sigil" do
      assert ExFSM.FormatterPlugin.features([]) == [sigils: [:FSM]]
    end

    test "aligns transition columns, including multi-destination states" do
      input = """
          on -- off -> [off, broken]
        on    --   on -> broken
      off -- on -> [broken, on]
      """

      assert ExFSM.FormatterPlugin.format(input, []) == """
             on  -- off -> [off, broken]
             on  -- on  -> broken
             off -- on  -> [broken, on]
             """
    end

    test "returns an empty string for blank content" do
      assert ExFSM.FormatterPlugin.format("\n   \n", []) == ""
    end
  end
end
