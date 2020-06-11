defmodule ElixirPopularity.HackernewsIdProcessor do
  use Broadway

  alias Broadway.Message
  alias ElixirPopularity.{HackernewsApi, RMQPublisher}

  def start_link(_opts) do
    # Define the broadway stage, 3 logic parts
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      # 1. Producers, RabbitMQ queue, one running instance
      producer: [
        module:
          {BroadwayRabbitMQ.Producer,
           queue: RMQPublisher.item_id_queue_name(),
           connection: [
             username: "rabbitmq",
             password: "rabbitmq"
           ]},
        concurrency: 1
      ],
      # 2. Processors, responsible for executing `handle_message/3`, 100 concurrent processes
      # fetching items from the Hackernews API (same value as the hackney pool)
      processors: [
        default: [
          concurrency: 100
        ]
      ],
      # 2. Batchers, responsible for executing `handle_batch/4`, running 2 instances
      # invokes handle_message/3 when 10 messages have been processed or timeout is reached
      batchers: [
        default: [
          batch_size: 10,
          batch_timeout: 10_000,
          concurrency: 2
        ]
      ]
    )
  end

  @impl true
  def handle_message(_processor, message, _context) do
    Message.update_data(message, fn hn_id ->
      {hn_id, HackernewsApi.get_hn_item(hn_id)}
    end)
  end

  @impl true
  def handle_batch(_batcher, messages, _batch_info, _context) do
    encoded_payload =
      messages
      |> Enum.reject(fn
        %Message{data: {_id, :error}} -> true
        _ -> false
      end)
      |> Enum.map(fn %Message{data: {id, item}} ->
        %{
          id: id,
          item: Map.from_struct(item)
        }
      end)
      |> Jason.encode!()

    RMQPublisher.publish_hn_items(encoded_payload)

    messages
  end
end
