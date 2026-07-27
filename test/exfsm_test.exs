defmodule ExFSMTest do
  use ExUnit.Case
  doctest ExFSM
  doctest ExFSM.Machine

  describe "ExFSM" do
    test "should perform transitions" do
      state = %ExFSM.Test.FSM.Light.State{max_usage: 1, usage: 0, state: :off}

      {:next_state, state} = ExFSM.Machine.event(state, {:on, nil})
      assert state.state == :on
      {:next_state, state} = ExFSM.Machine.event(state, {:off, :with_hand})
      assert state.state == :off
      {:next_state, state} = ExFSM.Machine.event(state, {:on, nil})
      assert state.state == :broken
    end

    test "should error out on an unavailable transition" do
      state = %ExFSM.Test.FSM.Light.State{max_usage: 1, usage: 0, state: :off}

      assert ExFSM.Machine.event(state, {:off, nil}) == {:error, :illegal_action}
    end

    test "should return error tuple" do
      state = %ExFSM.Test.FSM.Light.State{max_usage: 1, usage: 0, state: :on}

      assert ExFSM.Machine.event(state, {:on, nil}) == {:error, :already_on}
    end

    test "should ennumerate every possible output state for a given state and action" do
      transitions = ExFSM.Test.FSM.Light.fsm()

      assert Map.fetch!(transitions, {:off, :on}) == {ExFSM.Test.FSM.Light, [:broken, :on]}
    end

    test "shouldn't ennumerate error as a possible output state" do
      transitions = ExFSM.Test.FSM.Light.fsm()

      assert Map.fetch!(transitions, {:on, :on}) == {ExFSM.Test.FSM.Light, [:broken]}
    end
  end
end
