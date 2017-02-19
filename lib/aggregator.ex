defmodule Aggregator do
  @moduledoc """
  This module handles the aggregation of message payloads.
  As messages come in, it aggregates them.
  When all the messages have come in, it responds that it is done.
  """
  use GenServer
  defmodule State do
    defstruct routing_keys: [],
              payloads: [],
              finished: false
  end

  # Client API
  def start_link(routing_keys) do
    GenServer.start_link(__MODULE__, routing_keys, [name: __MODULE__])
  end

  def aggregate(pid, routing_key, payload) do
    GenServer.call(pid, {:message, {payload, routing_key}})
  end

  # Server API
  def init(keys) do
    {:ok, %Aggregator.State{routing_keys: keys}}
  end

  def handle_call({:message, {payload, routing_key}}, _from, state) do
    state = state
    |> update_payloads(payload)
    |> update_keys(routing_key)
    |> update_finished

    reply = state
    |> munge_reply

    {:reply, reply, state}
  end

  # Helpers
  defp munge_reply(%{finished: false}) do
    :ok
  end

  defp munge_reply(%{finished: true, payloads: payloads}) do
    {:publish, payloads}
  end

  defp update_payloads(state, new_payload) do
    new_payload = new_payload
    |> Poison.decode!
    %{state | payloads: [new_payload | state.payloads]}
  end

  defp update_keys(state, routing_key) do
    %{state | routing_keys: List.delete(state.routing_keys, routing_key)}
  end

  defp update_finished(%{routing_keys: []} = state) do
    %{state | finished: true}
  end

  defp update_finished(%{routing_keys: _keys} = state) do
    state
  end
end
