defmodule GrabElixirTest do
  use ExUnit.Case
  doctest GrabElixir

  test "greets the world" do
    assert GrabElixir.hello() == :world
  end
end
