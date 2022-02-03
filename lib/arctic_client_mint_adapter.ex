defmodule ArcticClientMintAdapter do
  @moduledoc """
  This module is an adapter for ArcticClient which implements the
  HTTP2 connection using `Mint` library.
  """

  @behaviour ArcticDef.StubAdapter

  alias ArcticDef.Channel

  @impl ArcticDef.StubAdapter
  @spec connect(Channel.t()) :: {:ok, Channel.t()} | {:error, any}
  def connect(channel) do
    case do_connect(channel) do
      {:ok, pid} ->
        {:ok, Channel.put_adapter_conn_pid(channel, pid)}

      {:error, _} = error ->
        IO.puts(error)
        error
    end
  end

  defp do_connect(channel) do
    opts = [schema: :http, hostname: channel.host, port: channel.port, opts: []]
    {:ok, pid} = ArcticClientMintAdapter.HTTPClientServer.start_link(opts)
    :ok = ArcticClientMintAdapter.HTTPClientServer.check_connection_status(pid)
    {:ok, pid}
  end
end
