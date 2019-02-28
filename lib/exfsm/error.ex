defmodule ExFSM.Error do
  @moduledoc """
  Describes ExFSM error
  """

  defexception [:handler, :statename, :action, :message]

  @doc false
  def exception(handler: handler, statename: statename, action: action)
      when is_atom(handler) and is_atom(statename) and is_atom(action) do
    message = "Exception firing #{action} on #{handler} in state #{statename}"
    %__MODULE__{handler: handler, statename: statename, action: action, message: message}
  end

  def exception(message) when is_binary(message) do
    %__MODULE__{message: message}
  end

  def exception(_) do
    %__MODULE__{message: "Error in fsm"}
  end
end
