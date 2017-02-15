defmodule Server do
  @moduledoc """
  This module manages the Listener and the Aggregator.
  It requires a Connection struct
  It starts the listener and the aggregator
  When messages come in to the listener, the server sends them to the Aggergator
  If the aggregator is not finished then nothing happens. If it is finished then the server does things.
  """
  use GenServer
  defmodule State do
    defstruct listener: nil,
              aggregator: nil
  end

  # Client
  def start_link(connection) do
    GenServer.start_link(__MODULE__, connection, name: __MODULE__)
  end

  def handle_message(routing_key, payload) do
    GenServer.cast(__MODULE__, {:handle_message, routing_key, payload})
  end

  # Server Callbacks
  def init(connection) do
    {:ok, listener} = Listener.start_link(connection)
    {:ok, aggregator} = Aggregator.start_link(connection.subscribe_routing_keys)
    state = %State{listener: listener, aggregator: aggregator}
    {:ok, state}
  end

  def handle_cast({:handle_message, routing_key, payload}, %State{} = state) do
    case Aggregator.aggregate(state.aggregator, routing_key, payload) do
      {:publish, payload} -> publish(payload)
      :ok -> :ok
    end
    {:noreply, state}
  end

  # Helpers
  defp publish(payload) do
    IO.inspect(payload, label: "PUBLISH PAYLOAD")
  end
end
