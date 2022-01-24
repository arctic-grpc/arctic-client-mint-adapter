defmodule ArcticClientMintAdapter.ResponseStreamTest do
  @moduledoc """
  A GenServer to hold HTTP frame data until it's done
  When it receives :done, it sends the response directly to
  the caller
  """
  use ExUnit.Case
  alias ArcticClientMintAdapter.ResponseStream, as: SUT

  describe "start/1" do
    test "starts gen server" do
      assert {:ok, _pid} = SUT.start(self(), {self(), :term})
    end
  end

  describe "handle_info/2" do
    test "stores status when receives status" do
      state = base_state_with_response()
      assert {_, state} = SUT.handle_info({:status, 200}, state)
      assert state.response.status == 200
    end

    test "stores headers when receives headers" do
      state = base_state_with_response()
      assert {_, state} = SUT.handle_info({:headers, [{"header-01", "foo"}]}, state)
      assert state.response.headers == [{"header-01", "foo"}]
    end

    test "appends headers when receives headers twice" do
      state = base_state_with_response()
      assert {_, state} = SUT.handle_info({:headers, [{"header-01", "foo"}]}, state)
      assert {_, state} = SUT.handle_info({:headers, [{"header-02", "bar"}]}, state)
      assert state.response.headers == [{"header-01", "foo"}, {"header-02", "bar"}]
    end

    test "stores data when receives data" do
      state = base_state_with_response()
      assert {_, state} = SUT.handle_info({:data, <<0>>}, state)
      assert state.response.data == [<<0>>]
    end

    test "appends data when receives data twice" do
      state = base_state_with_response()
      assert {_, state} = SUT.handle_info({:data, <<0>>}, state)
      assert {_, state} = SUT.handle_info({:data, <<1>>}, state)
      assert state.response.data == [<<1>>, <<0>>]
    end

    test "terminates the server when receives done" do
      state = state_with_caller()
      assert {:stop, :normal, _state} = SUT.handle_info(:done, state)
    end

    test "sends reply to request_caller when receives done" do
      state = state_with_caller()
      assert {:stop, :normal, _state} = SUT.handle_info(:done, state)

      assert_receive {:term, %ArcticClient.UnaryResponse{done: true}}
    end

    test "sends the data in the correct order when sending it back to caller" do
      state = state_with_caller()
      assert {_, state} = SUT.handle_info({:data, <<1>>}, state)
      assert {_, state} = SUT.handle_info({:data, <<2>>}, state)
      assert {:stop, :normal, _state} = SUT.handle_info(:done, state)

      assert_receive {:term, %ArcticClient.UnaryResponse{data: <<1, 2>>, done: true}}
    end

    test "terminates the server when receives stop" do
      state = state_with_caller()
      assert {:stop, :normal, _state} = SUT.handle_info(:done, state)
    end
  end

  defp base_state_with_response do
    %SUT{response: %ArcticClient.UnaryResponse{data: [], headers: []}}
  end

  defp state_with_caller do
    %{base_state_with_response() | request_caller: {self(), :term}}
  end
end
