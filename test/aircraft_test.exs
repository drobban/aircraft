defmodule AircraftTest do
  use ExUnit.Case
  doctest Aircraft

  test "greets the world" do
    assert Aircraft.hello() == :world
  end
end
