defmodule WebSentinels.Expectations do
  require Logger

  def validates(expects, duration, status, body, headers) do
    []
      |> validates_status(expects, status)
      |> validates_max_duration(expects, duration)
      |> validates_length(expects, String.length body)
      |> validates_body(expects, body)
      |> validates_headers(expects, headers)
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

  # ------

  defp validates_body(errors, %{body: body_rules}, body) do
    validates_body errors, body_rules, body
  end

  defp validates_body(errors, [], _body), do: errors

  defp validates_body(errors, [rule | rest], body) do
    new_errors = validates_body_rule errors, rule, body
    validates_body new_errors, rest, body
  end

  defp validates_body(errors, _rules, _body), do: errors

  # --

  defp validates_body_rule(errors, %{value: value, op: op}, body) do
    validates_body_rule errors, value, op, body
  end

  defp validates_body_rule(errors, value, "=", body) do
    if body == value,
      do: errors,
      else: [%{rule: :body, expect: value, op: "="} | errors]
  end

  defp validates_body_rule(errors, value, "c", body) do
    if String.contains?(body, value),
      do: errors,
      else: [%{rule: :body, expect: value, op: "c"} | errors]
  end

  defp validates_body_rule(errors, value, "md5", body) do
    md5 = :erlang.md5(body) |> Base.encode16(case: :lower)
    if md5 == value,
      do: errors,
      else: [%{rule: :body, expect: value, got: md5, op: "md5"} | errors]
  end

  # ------

  defp validates_headers(errors, %{headers: header_rules}, headers) do
    validates_headers errors, header_rules, headers
  end

  defp validates_headers(errors, [], _headers), do: errors

  defp validates_headers(errors, [rule | rest], headers) do
    new_errors = validates_header_rule errors, rule, headers
    validates_headers new_errors, rest, headers
  end

  defp validates_headers(errors, _rules, _headers), do: errors

  # --

  defp validates_header_rule(errors, %{name: name, value: value, op: op}, headers) do
    case get_header headers, name do
      [{_name, h_value}] ->
        validates_header_rule errors, name, value, op, h_value
      _ ->
        [%{rule: :header, name: name, expect: value, got: :missing, op: op} | errors]
    end
  end

  defp validates_header_rule(errors, %{name: name, op: "?"}, headers) do
    case get_header headers, name do
      [{_name, _h_value}] -> errors
      _ -> [%{rule: :header, name: name, got: :missing, op: "?"} | errors]
    end
  end

  # --

  defp validates_header_rule(errors, name, value, "c", h_value)
                when is_binary(value) do
    if String.contains?(h_value, value),
      do: errors,
      else: [%{rule: :header, name: name, expect: value, got: h_value, op: "c"} | errors]
  end

  defp validates_header_rule(errors, name, value, "=", h_value)
                when is_integer(value) and is_binary(h_value) do
    validates_header_rule errors, name, value, "=", String.to_integer(h_value)
  end

  defp validates_header_rule(errors, name, value, "=", h_value) do
    if h_value == value,
      do: errors,
      else: [%{rule: :header, name: name, expect: value, got: h_value, op: "="} | errors]
  end

  defp validates_header_rule(errors, name, value, ">", h_value) do
    if String.to_integer(h_value) > value,
      do: errors,
      else: [%{rule: :header, name: name, expect: value, got: h_value, op: ">"} | errors]
  end

  defp validates_header_rule(errors, name, value, "<", h_value) do
    if String.to_integer(h_value) < value,
      do: errors,
      else: [%{rule: :header, name: name, expect: value, got: h_value, op: "<"} | errors]
  end

  # -----

  defp get_header(headers, name) do
    Enum.filter headers, fn x ->
      String.downcase(elem(x, 0)) == String.downcase(name)
    end
  end
end
