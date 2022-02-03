# ArcticClientMintAdapter

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `arctic_client_mint_adapter` to your list of dependencies in `mix.exs`:

```elixir
channel = %ArcticDef.Channel{ host: "localhost", port: 50051, adapter: %ArcticDef.StubAdapter{module: ArcticClientMintAdapter}, stub_module: nil }
{:ok, channel} = ArcticClientMintAdapter.connect(channel)

path = "/helloworld.Greeter/SayHello"
headers = [{"grpc-timeout", "10S"}, {"content-type", "application/grpc+proto"}, {"user-agent", "mint-grpc-elixir/0.1.0"}, {"te", "trailers"}]

body = <<0, 0, 0, 0, 13, 10, 11, 103, 114, 112, 99, 45, 101, 108, 105, 120, 105, 114>>
ArcticClientMintAdapter.HTTPClientServer.request(channel.adapter.conn_pid, path, body, headers)




def deps do
  [
    {:arctic_client_mint_adapter, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/arctic_client_mint_adapter>.

TODO:
[ ] Error handlings
[ ] Support Extra options like timeout
[ ] allow start the channel even if it fails
[ ] Parsing the connection/request errors to a general struct
[ ] Support tls
[ ] Support Stream
