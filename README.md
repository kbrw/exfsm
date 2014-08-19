# ExFSM #

Simple elixir library to define a static FSM.

- define FSM with handler modules defining each transition as a simple function but using a
 macro `deftrans` which creates a function `fsm` returning the fsm transition map for this handler module.
- `deftrans` has the same semantic as [erlang in memory FSM gen_fsm](http://www.erlang.org/doc/man/gen_fsm.html)
- combine together multiple fsm handlers to create a "meta" FSM.
- send event with the function `send_event` which simply find the right
  handler, execute the handler function, and call callback module
  `start_transition` and `end_transition`. So you can plug this callback to
  your backend to persist the FSM state

## Usage ##

See in code documentation of ExFSM module for examples
