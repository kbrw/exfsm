# defmodule ExFSMdef do
#   def on_def(_env, _kind, _name, _args, _guards, _body) do
#      IO.inspect args
#   end
# end 

defmodule ExFSM do
  # @on_definition { ExFSMdef, :on_def }

  defmacro __before_compile__(_env) do
    quote do
      def desc, do: @desc |> Enum.reverse
    end
  end
  defmacro __using__(_opts) do
    quote do
      import eXFSM
      @before_compile eXFSM
      @desc []
    end
  end

  defmacro defsfm(head, body) do
    str   = Macro.to_string(head)
    fname = List.first(String.split str, "\(" )
    quote do
        # Module.register_attribute __MODULE__, :desc, accumulate: true 
        descval = if @desc, do: [unquote(str)|@desc], else: [unquote(str)]       
        Module.put_attribute __MODULE__, :desc, descval
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
