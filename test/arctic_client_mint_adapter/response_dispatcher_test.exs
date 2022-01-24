defmodule ArcticClientMintAdapter.ResponseDispatcherTest do
  use ExUnit.Case
  alias ArcticClientMintAdapter.ResponseDispatcher, as: SUT
  doctest ArcticClientMintAdapter

  describe "new/1" do
    test "create struct" do
      assert %SUT{} = SUT.new()
    end
  end

  describe "put/3" do
    test "puts http reference into in_flight_requests" do
      state = SUT.new()
      ref = make_ref()
      assert {:ok, state, _} = SUT.put(state, ref, {self(), :term})
      assert Map.get(state.in_flight_requests, ref)
    end

    test "starts a GenServer based" do
      state = SUT.new()
      ref = make_ref()
      assert {:ok, _, pid} = SUT.put(state, ref, {self(), :term})
      assert Process.alive?(pid)
    end
  end

  describe "delete/2" do
    test "deletes" do
      state = SUT.new()
      ref = make_ref()
      {:ok, state, _} = SUT.put(state, ref, {self(), :term})
      {_, _, monitor_ref} = Map.get(state.in_flight_requests, ref)
      {_value, state} = SUT.delete(state, monitor_ref)
      assert state.in_flight_requests == %{}
    end
  end

  describe "send/3" do
    test "sends :done command to an in flight ResponseStream" do
      state = SUT.new()
      ref = make_ref()
      assert {:ok, state, _} = SUT.put(state, ref, {self(), :from_send_test})

      SUT.send(state, ref, :done)

      assert_receive {:from_send_test, _}
    end
  end

  describe "stop_all/1" do
    test "stops all in flight process" do
      state = SUT.new()
      ref01 = make_ref()
      ref02 = make_ref()
      {:ok, state, _} = SUT.put(state, ref01, {self(), :from_send_test01})
      {:ok, state, _} = SUT.put(state, ref02, {self(), :from_send_test02})
      SUT.stop_all(state)
      assert_receive {:DOWN, _, _, _, :normal}
      assert_receive {:DOWN, _, _, _, :normal}
    end
  end
end
