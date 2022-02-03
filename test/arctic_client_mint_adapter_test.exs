defmodule ArcticClientMintAdapterTest do
  use ExUnit.Case
  alias ArcticClientMintAdapter, as: SUT
  doctest ArcticClientMintAdapter

  describe "connect/1" do
    test "connects to server" do
      channel = %ArcticDef.Channel{
        host: "localhost",
        port: 50001,
        adapter: %ArcticDef.StubAdapter{module: ArcticClientMintAdapter},
        stub_module: nil
      }

      assert {:ok, channel} = SUT.connect(channel)
    end
  end
end
