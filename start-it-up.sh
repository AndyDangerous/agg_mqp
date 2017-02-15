{:ok, conn} = AMQP.Connection.open
{:ok, chan} = AMQP.Channel.open(conn)
AMQP.Exchange.declare chan, "test_exchange", :topic

srk = ["route.one", "route.two"]

listconn = %Listener.Connection{chan: chan, exchange: "test_exchange", subscribe_routing_keys: srk}


Server.start_link(listconn)

AMQP.Basic.publish chan, "test_exchange", "route.one", "Hello, World!"
AMQP.Basic.publish chan, "test_exchange", "route.two", "Goodbye, World!"

AMQP.Basic.get chan, "some_queue"
