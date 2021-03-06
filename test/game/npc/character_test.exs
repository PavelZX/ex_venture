defmodule Game.NPC.CharacterTest do
  use ExUnit.Case

  import Test.ItemsHelper
  import Test.DamageTypesHelper
  import Test.Game.Room.Helpers

  alias Game.NPC.Character
  alias Game.NPC.State

  doctest Character

  setup do
    start_and_clear_damage_types()

    insert_damage_type(%{
      key: "slashing",
      stat_modifier: :strength,
      boost_ratio: 20,
      reverse_stat: :agility,
      reverse_boost: 20,
    })

    :ok
  end

  describe "tick - respawning the npc" do
    setup do
      npc = %{
        id: 1,
        stats: %{health_points: 10, max_health_points: 15},
        status_line: "[name] is here",
        status_listen: nil
      }
      npc_spawner = %{room_id: 1, spawn_interval: 10}

      state = %State{npc: npc, npc_spawner: npc_spawner, room_id: 2}

      %{state: state, npc: npc}
    end

    test "respawns the npc", %{state: state, npc: npc} do
      start_room(%{id: 1})

      state = %{state | npc: put_in(npc, [:stats, :health_points], 0)}

      state = Character.handle_respawn(state)

      assert state.npc.stats.health_points == 15
      assert state.room_id == 1
      assert_enter {_, {:npc, _}, :respawn}
    end
  end

  describe "tick - cleaning up conversation state" do
    setup do
      npc = %{id: 1}

      time = Timex.now()

      state = %State{
        npc: npc,
        conversations: %{
          10 => %{key: "start", started_at: time |> Timex.shift(minutes: -10)},
          11 => %{key: "start", started_at: time |> Timex.shift(minutes: -1)},
        },
      }

      %{time: time, npc: npc, state: state}
    end

    test "cleans out conversations after 5 minutes", %{state: state, time: time} do
      state = Character.clean_conversations(state, time)

      assert Map.keys(state.conversations) == [11]
    end
  end

  describe "dying" do
    setup do
      start_and_clear_items()
      insert_item(%{id: 1, name: "Sword", keywords: [], is_usable: false})
      insert_item(%{id: 2, name: "Shield", keywords: [], is_usable: false})

      npc_items = [
        %{item_id: 1, drop_rate: 50},
        %{item_id: 2, drop_rate: 50},
      ]

      npc = %{id: 1, name: "NPC", currency: 100, npc_items: npc_items}
      npc_spawner = %{id: 1, spawn_interval: 0}

      %{room_id: 1, npc: npc, npc_spawner: npc_spawner, target: nil}
    end

    test "triggers respawn", state do
      _state = Character.died(state, {:npc, state.npc})

      assert_receive :respawn
    end

    test "drops currency in the room", state do
      _state = Character.died(state, {:npc, state.npc})

      assert_drop {_, {:npc, _}, {:currency, 51}}
    end

    test "does not drop 0 currency", state do
      npc = %{state.npc | currency: 0}
      _state = Character.died(%{state | npc: npc}, {:npc, state.npc})

      refute_drop {_, {:npc, _}, {:currency, _}}
    end

    test "will drop an amount 50-100% of the total currency" do
      assert Character.currency_amount_to_drop(100, Test.DropCurrency) == 80
    end

    test "drops items in the room", state do
      _state = Character.died(state, {:npc, state.npc})

      assert_drop {_, {:npc, _}, %{id: 1}}
      assert_drop {_, {:npc, _}, %{id: 2}}
    end

    test "will drop an item if the chance is below the item's drop rate" do
      assert Character.drop_item?(%{drop_rate: 50}, Test.ChanceSuccess)
    end

    test "will not drop an item if the chance is above the item's drop rate" do
      refute Character.drop_item?(%{drop_rate: 50}, Test.ChanceFail)
    end
  end

  describe "continuous effects" do
    setup do
      effect = %{id: :id, kind: "damage/over-time", type: "slashing", every: 10, count: 3, amount: 15}
      from = {:player, %{id: 1, name: "Player"}}
      npc = %{id: 1, name: "NPC", currency: 0, npc_items: [], stats: %{health_points: 25, agility: 10}}
      npc_spawner = %{id: 1, spawn_interval: 0}

      state = %State{
        room_id: 1,
        npc: npc,
        npc_spawner: npc_spawner,
        continuous_effects: [{from, effect}],
      }

      %{state: state, effect: effect, from: from}
    end

    test "finds the matching effect and applies it as damage, then decrements the counter", %{state: state, effect: effect, from: from} do
      state = Character.handle_continuous_effect(state, :id)

      effect_id = effect.id
      assert [{^from, %{id: :id, count: 2}}] = state.continuous_effects
      assert state.npc.stats.health_points == 15
      assert_receive {:continuous_effect, ^effect_id}
    end

    test "handles death", %{state: state, effect: effect, from: from} do
      effect = %{effect | amount: 38}
      state = %{state | continuous_effects: [{from, effect}]}

      state = Character.handle_continuous_effect(state, :id)

      assert_leave {1, {:npc, _}, :death}
      assert state.continuous_effects == []
    end

    test "does not send another message if last count", %{state: state, effect: effect, from: from} do
      effect = %{effect | count: 1}
      state = %{state | continuous_effects: [{from, effect}]}

      state = Character.handle_continuous_effect(state, :id)

      effect_id = effect.id
      assert [] = state.continuous_effects
      refute_received {:continuous_effect, ^effect_id}
    end

    test "does nothing if effect is not found", %{state: state} do
      ^state = Character.handle_continuous_effect(state, :notfound)
    end
  end
end
