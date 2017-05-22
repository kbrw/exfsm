# ExFSM #

[![Build Status](https://travis-ci.org/kbrw/exfsm.svg?branch=master)](https://travis-ci.org/kbrw/exfsm)

Simple elixir library to define composable FSM as function
(not related at all with `:gen_fsm`, no state/process management).

- define FSM with handler modules defining each transition as a simple function but using a
 macro `deftrans` which creates a function `fsm` returning the fsm transition map for this handler module.
- `deftrans` has the same semantic as [erlang in memory FSM gen_fsm](http://www.erlang.org/doc/man/gen_fsm.html)
- combine together multiple fsm handlers to create a "meta" FSM.
- send event with the function `event` which simply find the right
  handler, execute the handler function.


## Usage ##

See in [in code documentation](http://hexdocs.pm/exfsm)
