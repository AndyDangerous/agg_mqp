{:ok, conn} = AMQP.Connection.open
{:ok, chan} = AMQP.Channel.open(conn)
AMQP.Exchange.declare chan, "test_exchange", :topic

srk = ["route.one", "route.two"]

listconn = %Connection{chan: chan, exchange: "test_exchange"}
listagg = %Aggregation{subscribe_routing_keys: srk, publish_routing_key: "pub_queue"}


Server.start_link(listconn, listagg)

AMQP.Queue.declare(chan, "pub_queue")
AMQP.Queue.bind(chan, "pub_queue", "test_exchange", [routing_key: "pub_queue"])
AMQP.Basic.publish chan, "test_exchange", "route.one", "Hello, World!"
AMQP.Basic.publish chan, "test_exchange", "route.two", "Goodbye, World!"

AMQP.Basic.get chan, "pub_queue"
