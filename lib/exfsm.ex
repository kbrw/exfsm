

defmodule ExFSM do
  # @on_definition { ExFSMdef, :on_def }

  defmacro __before_compile__(_env) do
    quote do
      def desc, do: @desc 
    end
  end

  defmacro __using__(_opts) do
    quote do
      import ExFSM
      @desc HashDict.new()
      @before_compile ExFSM
    end
  end

  defmacro defsfm(head, body) do
    str   = Macro.to_string(head)
    [_,fname,fargs] =  Regex.run(%r/(.*?)\((.*?)\)/, str)
    quote do     
        @desc Dict.put(@desc,unquote(fname),unquote(fargs))
        def unquote(head), unquote(body)
        def unquote(binary_to_atom(fname<>"_desc"))(), do: unquote(str)
    end  

  end

end

# defmodule Sup do
#     use Supervisor.Behaviour
#     def start_link(), do: :supervisor.start_link(__MODULE__,[])
#     def init(_) do
#       supervise([
#         worker(__MODULE__,[], restart: :temporary, function: :set_debug)
#       ], strategy: :one_for_one)
#     end
# end
