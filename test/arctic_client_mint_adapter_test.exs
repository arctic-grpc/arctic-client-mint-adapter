defmodule ArcticClientMintAdapterTest do
  use ExUnit.Case
  alias ArcticClientMintAdapter, as: SUT
  doctest ArcticClientMintAdapter

  describe "connect/1" do
    test "connects to server" do
      channel = %Arctic.Channel{
        host: "localhost",
        port: 50001,
        adapter: %Arctic.StubAdapter{module: ArcticClientMintAdapter},
        stub_module: nil
      }

      assert {:ok, channel} = SUT.connect(channel)
    end
  end
end
