defmodule Timer do
  @moduledoc """
  Helper module to measure the execution time of an 'exp'
  """

  @doc """
  Measure the execution time of 'exp'.

  ## Parameters

    - unit: :second | :millisecond | :microsecond | :nanosecond | :native
  """
  defmacro duration(unit, do: exp) do
    quote do
      t1 = :os.system_time unquote(unit)
      unquote(exp)
      t2 = :os.system_time unquote(unit)
      t2 - t1
    end
  end
end
