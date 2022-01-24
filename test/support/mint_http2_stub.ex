defmodule ArcticClientMintAdapter.MintHTTP2.Stub do
  @moduledoc false
  @behaviour ArcticClientMintAdapter.MintHTTP2

  @impl ArcticClientMintAdapter.MintHTTP2
  def connect(:http = schema, hostname, port) do
    conn = %Mint.HTTP2{
      buffer: "",
      client_settings: %{
        enable_push: true,
        max_concurrent_streams: 100,
        max_frame_size: 16384
      },
      client_settings_queue: {[[]], []},
      decode_table: %Mint.HTTP2.HPACK.Table{
        entries: [],
        length: 0,
        max_table_size: 4096,
        size: 0
      },
      encode_table: %Mint.HTTP2.HPACK.Table{
        entries: [],
        length: 0,
        max_table_size: 4096,
        size: 0
      },
      headers_being_processed: nil,
      hostname: hostname,
      mode: :active,
      next_stream_id: 3,
      open_client_stream_count: 0,
      open_server_stream_count: 0,
      ping_queue: {[], []},
      port: port,
      private: %{},
      proxy_headers: [],
      ref_to_stream_id: %{},
      scheme: Atom.to_string(schema),
      server_settings: %{
        enable_connect_protocol: false,
        enable_push: true,
        initial_window_size: 1_048_576,
        max_concurrent_streams: 100,
        max_frame_size: 16384,
        max_header_list_size: :infinity
      },
      socket: nil,
      state: :open,
      streams: %{},
      transport: Mint.Core.Transport.TCP,
      window_size: 65535
    }

    {:ok, conn}
  end

  @impl ArcticClientMintAdapter.MintHTTP2
  def request(conn, _, _, _, _) do
    {:ok, conn, make_ref()}
  end

  @impl ArcticClientMintAdapter.MintHTTP2
  def stream(conn, message) do
    ref = make_ref()

    responses = [
      {:status, ref, 200},
      {:headers, ref,
       [
         {"content-type", "application/grpc"},
         {"date", "Tue, 01 Feb 2022 20:09:31 GMT"}
       ]},
      {:data, ref,
       <<0, 0, 0, 0, 20, 10, 18, 72, 101, 108, 108, 111, 32, 103, 114, 112, 99, 45, 101, 108, 105,
         120, 105, 114, 33>>},
      {:headers, ref, [{"grpc-status", "0"}]},
      {:done, ref}
    ]

    {:ok, conn, responses}
  end
end
