
{:ok, conn} = AMQP.Connection.open
{:ok, chan} = AMQP.Channel.open(conn)
AMQP.Exchange.declare chan, "test_exchange", :topic
a = %AggMqp{chan: chan, exchange: "test_exchange", subscribe_routing_keys: ["route.one", "route.two"]}
AggMqp.start_link a

AMQP.Basic.publish chan, "test_exchange", "route.one", "Hello, World!"

AMQP.Basic.get chan, "some_queue"
