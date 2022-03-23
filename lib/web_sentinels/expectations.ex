defmodule WebSentinels.Expectations do
  require Logger

  def validates(expects, status, body, headers) do
    []
      |> validates_status(expects, status)
  end

  # ------

  defp validates_status(errors, %{status: e_status}, status) do
    if e_status == status,
      do: errors,
      else: [%{rule: :status, expect: status, got: e_status} | errors]
  end
end
