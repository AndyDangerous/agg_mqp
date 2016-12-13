defmodule AggMqp do
  use GenServer

  defstruct chan: %AMQP.Channel{}, 
            exchange: "",
            subscribe_routing_keys: [],
            publish_routing_key: "",
            listening_queue: ""

  # Client
  def start_link(%AggMqp{} = aggregation) do
    GenServer.start_link(__MODULE__, aggregation, [])
  end

  # Server

  def init(aggregation) do
    aggregation = %AggMqp{aggregation | listening_queue: "some_queue"}
    AMQP.Queue.declare(aggregation.chan, aggregation.listening_queue)
    aggregation |> bind

    {:ok, _pid} = Aggregator.start_link(aggregation.subscribe_routing_keys)
    {:ok, _consumer_tag} = AMQP.Basic.consume(aggregation.chan, aggregation.listening_queue)
    {:ok, aggregation.chan}
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
    Aggregator.aggregate(routing_key, payload)
  end

  defp bind(aggregation) do
    aggregation.subscribe_routing_keys
    |> Enum.each( fn(key) -> AMQP.Queue.bind(
        aggregation.chan,
        aggregation.listening_queue,
        aggregation.exchange,
        [routing_key: key])
      end )
    aggregation
  end
end
