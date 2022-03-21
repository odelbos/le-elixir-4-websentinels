defmodule WebSentinelsTest do
  use ExUnit.Case
  doctest WebSentinels

  test "greets the world" do
    assert WebSentinels.hello() == :world
  end
end
