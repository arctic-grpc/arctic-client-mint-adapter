defmodule ArcticClientMintAdapter do
  @moduledoc """
  This module is an adapter for ArcticClient which implements the
  HTTP2 connection using `Mint` library.
  """

  @behaviour Arctic.StubAdapter

  @user_agent "grpc-elixir/0.1.0 (mint/1.0; arctic-client)"

  alias Arctic.{Channel, ChannelError}

  @impl Arctic.StubAdapter
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

  @impl Arctic.StubAdapter
  def request(channel, %Arctic.UnaryRequest{} = request) do
    request = add_user_agent(request)

    ArcticClientMintAdapter.HTTPClientServer.request(
      channel.adapter.conn_pid,
      request.path,
      request.body,
      request.headers
    )
  end

  @impl Arctic.StubAdapter
  def request(channel, %Arctic.StreamRequest{} = request) do
    # headers = [{"user-agent", @user_agent} | request.headers]
    # request = %{request | headers: headers}
    request = add_user_agent(request)

    ArcticClientMintAdapter.HTTPClientServer.request_stream(
      channel.adapter.conn_pid,
      add_user_agent(request)
    )
  end

  defp add_user_agent(request) do
    headers = [{"user-agent", @user_agent} | request.headers]
    %{request | headers: headers}
  end

  defp do_connect(channel) do
    opts = [
      schema: channel.schema,
      hostname: channel.host,
      port: channel.port,
      tls_options: channel.tls_options
    ]

    with {:ok, pid} <- ArcticClientMintAdapter.HTTPClientServer.start_link(opts),
         :ok <- ArcticClientMintAdapter.HTTPClientServer.check_connection_status(pid) do
      {:ok, pid}
    end
  end
end
