# AggMqp

### First Iteration

* define Aggregation/Connection
* listen for relevant messages
* aggregate them
* do something

### Second Iteration

* Publish aggregated messages to predefined routing key

### Third Iteration

* Top-level [Thing] listens for messages to kick off aggregations and then creates them
* Aggregations die after publishing
* Supervision Tree

### Fourth Iteration

* Abstract AMQP stuff?

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `agg_mqp` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:agg_mqp, "~> 0.1.0"}]
    end
    ```

  2. Ensure `agg_mqp` is started before your application:

    ```elixir
    def application do
      [applications: [:agg_mqp]]
    end
    ```

