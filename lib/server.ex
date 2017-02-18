defmodule Server do
  @moduledoc """
  This module manages the Listener, Publisher, and Aggregator.
  It requires Connection and Aggregation structs
  It starts the listener, publisher, and aggregator
  When messages come in to the listener, the server sends them to the Aggergator
  If the aggregator is not finished then nothing happens. If it is finished then the messages is sent to the publisher to be published
  """
  use GenServer
  defmodule State do
    defstruct listener: nil,
              aggregator: nil,
              publisher: nil
  end

  # Client
  def start_link(connection, aggregation) do
    GenServer.start_link(__MODULE__, {connection, aggregation}, name: __MODULE__)
  end

  def handle_message(routing_key, payload) do
    GenServer.cast(__MODULE__, {:handle_message, routing_key, payload})
  end

  # Server Callbacks
  def init({connection, aggregation}) do
    {:ok, listener} = Listener.start_link(connection, aggregation.subscribe_routing_keys)
    {:ok, publisher} = Publisher.start_link(connection, aggregation.publish_routing_key)
    {:ok, aggregator} = Aggregator.start_link(aggregation.subscribe_routing_keys)
    state = %State{listener: listener, aggregator: aggregator, publisher: publisher}
    {:ok, state}
  end

  def handle_cast({:handle_message, routing_key, payload}, %State{} = state) do
    case Aggregator.aggregate(state.aggregator, routing_key, payload) do
      {:publish, payload} -> publish(payload, state.publisher)
      :ok -> :ok
    end
    {:noreply, state}
  end

  # Helpers
  defp publish(payload, publisher) do
    Publisher.publish(publisher, payload)
  end
end
