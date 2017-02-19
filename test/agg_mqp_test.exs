defmodule AggMqpTest do
  use ExUnit.Case

  test "it can aggregate two messages" do
    #General Setup
    {:ok, conn} = AMQP.Connection.open
    {:ok, chan} = AMQP.Channel.open(conn)
    AMQP.Exchange.declare chan, "test_exchange", :topic

    #params
    route1 = "routing.key1"
    route2 = "routing.key2"
    exchange = "test_exchange"
    message1 = Poison.encode! %{message: "Hello, World!"}
    message2 = Poison.encode! %{message: "Goodbye, World!"}

    connection = %Connection{chan: chan, exchange: exchange}
    aggregation = %Aggregation{
      subscribe_routing_keys: [route1, route2],
      publish_routing_key: "publish_queue"
    }

    Server.start_link(connection, aggregation)

    # prepare publish queue
    AMQP.Queue.declare(chan, "publish_queue")
    AMQP.Queue.bind(chan, "publish_queue", "test_exchange", [routing_key: "publish_queue"])

    AMQP.Basic.publish chan, "test_exchange", route1, message1
    AMQP.Basic.publish chan, "test_exchange", route2, message2

    #Give a moment to aggregate and publish
    :timer.sleep 10

    {:ok, payload, meta}  = AMQP.Basic.get chan, "publish_queue"
    payload = Poison.decode!(payload)
    assert payload == [%{"message" => "Goodbye, World!"}, %{"message" => "Hello, World!"}]
  end
end
