defmodule Publisher do
  @moduledoc """
  This module publishes to AMQP.
  It starts with a Connection and routing key
  it has a publish function (which takes a payload) and publishes to the connection/routing key
  """
  use GenServer

  defstruct connection: nil, routing_key: nil

  # Client
  def start_link(%Connection{} = connection, routing_key) do
    GenServer.start_link(__MODULE__, {connection, routing_key}, [])
  end

  def publish(pid, payload) do
    GenServer.call(pid, {:publish, payload})
  end

  # Server

  def init({connection, routing_key}) do
    state = %Publisher{connection: connection, routing_key: routing_key}
    {:ok, state}
  end

  def handle_call({:publish, payload}, _from, state) do
    :ok = publish_payload({payload, state})
    {:reply, :published, state}
  end

  # Helpers

  defp publish_payload({payload, %Publisher{} = state}) do
    connection = state.connection
    routing_key = state.routing_key
    payload = payload
    |> Poison.encode!(payload)

    AMQP.Basic.publish(connection.chan, connection.exchange, routing_key, payload)

  end
end
