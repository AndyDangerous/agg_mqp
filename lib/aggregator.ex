defmodule Aggregator do
  use GenServer
  defstruct routing_keys: [],
            payloads: []

  # Server API
  def init(keys) do
    {:ok, %Aggregator{routing_keys: keys, payloads: []}}
  end

  def handle_cast({:message, {payload, routing_key}}, state) do
    state = state
    |> update_payloads(payload)
    |> update_keys(routing_key)
    |> publish
    {:noreply, state}
  end

  defp update_payloads(state, new_payload) do
    %{state | payloads: [new_payload | state.payloads]}
  end

  defp update_keys(state, routing_key) do
    %{state | routing_keys: List.delete(state.routing_keys, routing_key)}
  end

  defp publish(%{routing_keys: []}) do
    IO.puts "PUBLISHING THINGZ"
  end
  defp publish(%{routing_keys: _keys} = state) do
    state
  end

  # Client API
  def start_link(routing_keys) do
    GenServer.start_link(__MODULE__, routing_keys, [name: __MODULE__])
  end

  def aggregate(routing_key, payload) do
    GenServer.cast(__MODULE__, {:message, {payload, routing_key}}) 
  end
end
