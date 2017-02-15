defmodule Listener do
  @moduledoc """
  This module handles communication with AMQP.
  It takes Connection information and a list of routing keys.
  When messages come in, it sends them to the server
  """
  use GenServer

  defmodule Connection do
    defstruct chan: %AMQP.Channel{}, 
    exchange: "",
    subscribe_routing_keys: [],
    publish_routing_key: "",
    listening_queue: ""
  end


  # Client
  def start_link(%Listener.Connection{} = connection) do
    GenServer.start_link(__MODULE__, connection, [])
  end

  # Server

  def init(connection) do
    connection = %Listener.Connection{connection | listening_queue: "some_queue"}
    AMQP.Queue.declare(connection.chan, connection.listening_queue)
    connection |> bind

    # {:ok, _pid} = Aggregator.start_link(aggregation.subscribe_routing_keys)
    {:ok, _consumer_tag} = AMQP.Basic.consume(connection.chan, connection.listening_queue)
    {:ok, connection.chan}
  end

  # Confirmation sent by the broker after registering this process as a consumer
  def handle_info({:basic_consume_ok, %{consumer_tag: _consumer_tag}}, chan) do
    {:noreply, chan}
  end

  # Sent by the broker when the consumer is unexpectedly cancelled (such as after a queue deletion)
  def handle_info({:basic_cancel, %{consumer_tag: _consumer_tag}}, chan) do
    {:stop, :normal, chan}
  end

  # Confirmation sent by the broker to the consumer process after a Basic.cancel
  def handle_info({:basic_cancel_ok, %{consumer_tag: _consumer_tag}}, chan) do
    {:noreply, chan}
  end

  def handle_info({:basic_deliver, payload, %{delivery_tag: tag, routing_key: routing_key}}, chan) do
    spawn fn -> consume(chan, tag, routing_key, payload) end
    {:noreply, chan}
  end

  defp consume(channel, tag, routing_key, payload) do
    AMQP.Basic.ack channel, tag
    Server.handle_message(routing_key, payload)
  end

  defp bind(connection) do
    connection.subscribe_routing_keys
    |> Enum.each( fn(key) -> AMQP.Queue.bind(
        connection.chan,
        connection.listening_queue,
        connection.exchange,
        [routing_key: key])
      end )
    connection
  end
end
