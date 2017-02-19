defmodule AggMqp.Mixfile do
  use Mix.Project

  def project do
    [app: :agg_mqp,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [applications: [:logger, :amqp]]
  end

  defp deps do
    [
      {:rabbit_common, git: "https://github.com/Nezteb/rabbit_common.git", override: true},
      {:amqp_client, git: "https://github.com/Nezteb/amqp_client.git", override: true},
      {:amqp, "~> 0.1.4"},
      {:poison, "~> 3.0"},
    ]
  end
end
