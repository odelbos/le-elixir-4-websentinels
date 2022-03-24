defmodule WebSentinels.Expectations do
  require Logger

  def validates(expects, duration, status, body, headers) do
    []
      |> validates_status(expects, status)
      |> validates_max_duration(expects, duration)
      |> validates_length(expects, String.length body)
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

  # ------

  defp validates_length(errors, %{length: length_rules}, body_length) do
    validates_length errors, length_rules, body_length
  end

  defp validates_length(errors, [], _body_length), do: errors

  defp validates_length(errors, [rule | rest], body_length) do
    new_errors = validates_length_rule errors, rule, body_length
    validates_length new_errors, rest, body_length
  end

  defp validates_length(errors, _rules, _body_length), do: errors

  # --

  defp validates_length_rule(errors, %{value: value, op: op}, body_length) do
    validates_length_rule errors, value, op, body_length
  end

  defp validates_length_rule(errors, value, "=", body_length) do
    if body_length == value,
      do: errors,
      else: [%{rule: :length, expect: value, got: body_length, op: "="} | errors]
  end

  defp validates_length_rule(errors, value, "<", body_length) do
    if body_length < value,
      do: errors,
      else: [%{rule: :length, expect: value, got: body_length, op: "<"} | errors]
  end

  defp validates_length_rule(errors, value, ">", body_length) do
    if body_length > value,
      do: errors,
      else: [%{rule: :length, expect: value, got: body_length, op: ">"} | errors]
  end
end
