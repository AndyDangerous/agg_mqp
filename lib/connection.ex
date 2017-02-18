defmodule Connection do
  defstruct chan: %AMQP.Channel{},
  exchange: "",
  listening_queue: ""
end
