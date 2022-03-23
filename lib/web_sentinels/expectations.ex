defmodule WebSentinels.Expectations do
  require Logger

  def validates(expects, duration, status, body, headers) do
    []
      |> validates_status(expects, status)
      |> validates_max_duration(expects, duration)
  end

  # ------

  defp validates_status(errors, %{status: e_status}, status) do
    if e_status == status,
      do: errors,
      else: [%{rule: :status, expect: status, got: e_status} | errors]
  end

  # ------

  defp validates_max_duration(errors, %{max_duration: max_duration}, duration) do
    if duration < max_duration,
      do: errors,
      else: [%{rule: :max_duration, expect: max_duration, got: duration} | errors]
  end

  defp validates_max_duration(errors, _expects, _duration), do: errors
end
