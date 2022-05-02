defmodule ZeromqTest do
  use ExUnit.Case
  doctest Zeromq

  test "greets the world" do
    assert Zeromq.hello() == :world
  end
end
