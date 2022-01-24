defmodule ArcticClientMintAdapter.HTTPClientTest do
  use ExUnit.Case
  alias ArcticClientMintAdapter.HTTPClient, as: SUT

  alias ArcticClientMintAdapter.MintHTTP2.Mock, as: MintMock
  alias ArcticClientMintAdapter.MintHTTP2.Stub, as: MintStub
  import Mox

  setup :verify_on_exit!

  describe "connect/1" do
    test "connects to a http 2 server" do
      client = SUT.new("localhost", 50051, :http)

      Mox.stub_with(MintMock, MintStub)

      assert client = SUT.connect(client)
      refute client.conn_error
      assert client.conn
    end

    test "sets conn_error when connection fails" do
      client = SUT.new("localhost", 50051, :http)

      conn_fails_fn = fn _, _, _ -> {:error, %Mint.TransportError{reason: :econnrefused}} end
      expect(MintMock, :connect, 1, conn_fails_fn)
      assert client = SUT.connect(client)
      refute client.conn
      assert client.conn_error == %Mint.TransportError{reason: :econnrefused}
    end
  end

  describe "request/5" do
    setup do
      client = SUT.new("localhost", 50051, :http)
      path = "/helloworld.Greeter/SayHello"

      headers = [
        {"grpc-timeout", "10S"},
        {"content-type", "application/grpc"},
        {"user-agent", "mint-grpc-elixir/0.1.0"},
        {"te", "trailers"}
      ]

      body = <<0, 0, 0, 0, 13, 10, 11, 103, 114, 112, 99, 45, 101, 108, 105, 120, 105, 114>>
      %{client: client, path: path, headers: headers, body: body}
    end

    test "sends request", %{client: client, path: path, headers: headers, body: body} do
      Mox.stub_with(MintMock, MintStub)
      client = SUT.connect(client)
      assert {:ok, _, _} = SUT.request(client, {self(), :from_test}, path, headers, body)
    end

    test "tracks requests in response_dispatcher", %{
      client: client,
      path: path,
      headers: headers,
      body: body
    } do
      Mox.stub_with(MintMock, MintStub)
      client = SUT.connect(client)
      assert {:ok, client, _} = SUT.request(client, {self(), :from_test}, path, headers, body)
      refute client.response_dispatcher.in_flight_requests == %{}
    end
  end

  describe "stream/2" do
    setup do
      client = SUT.new("localhost", 50051, :http)
      %{client: client}
    end

    test "parse incomming message", %{client: client} do
      Mox.stub_with(MintMock, MintStub)
      message = {:tcp, :port_value, <<0>>}
      assert {:ok, _client, responses} = SUT.stream(client, message)
      assert is_list(responses)
    end
  end
end
