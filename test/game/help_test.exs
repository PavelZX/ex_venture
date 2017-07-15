defmodule Game.HelpTest do
  use ExUnit.Case

  alias Game.Help

  test "loading a help topic" do
    assert Regex.match?(~r(Example:), Help.topic("say"))
  end

  test "loading a help topic - unknown" do
    assert Help.topic("unknown") == "Unknown topic"
  end
end
