defmodule ExFSMTest do
  use ExUnit.Case
  doctest ExFSM
  doctest ExFSM.Machine

  describe "ExFSM" do
    test "should perform transitions" do
      state = %ExFSM.Test.FSM.Light.State{usage: 0, state: :off}

      {:next_state, state} = ExFSM.Machine.event(state, {:on, nil})
      assert state.state == :on
      {:next_state, state} = ExFSM.Machine.event(state, {:off, nil})
      assert state.state == :off
      {:next_state, state} = ExFSM.Machine.event(state, {:on, nil})
      assert state.state == :broken
    end
  end
end
