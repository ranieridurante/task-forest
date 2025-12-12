defmodule TaskForest.Models.OpenAiFunctionsStreamingClient do
  # NOTE: moved to modified version of ExOpenAI.StreamingClient
  # to handle streaming with partial chunks
  # TODO: investigate if OpenAI changed their streaming API
  # or if this is a bug in our implementation
  use ExOpenAI.StreamingClient

  require Logger

  @streaming_response_timeout_ms :timer.minutes(10)

  @spec set_stream_ref(atom() | pid() | {atom(), any()} | {:via, atom(), any()}, any()) :: any()
  def set_stream_ref(stream_to, hackney_stream_ref) do
    GenServer.call(stream_to, {:set_stream_ref, hackney_stream_ref})
  end

  def end_stream(stream_to) do
    GenServer.call(stream_to, :end_stream)
  end

  @impl true
  def handle_data(
        %{partial_chunk: new_partial_chunk},
        %{partial_chunk: current_partial_chunk, content: current_content} = state
      )
      when not is_nil(current_partial_chunk) do
    with combined_chunks <- "#{current_partial_chunk}#{new_partial_chunk}",
         {:ok, data} <- Jason.decode(combined_chunks) do
      next_token =
        data["choices"]
        |> List.first()
        |> get_in(["delta", "content"])

      state =
        state
        |> Map.put(:partial_chunk, nil)
        |> Map.put(:content, "#{current_content}#{next_token}")

      {:noreply, state}
    else
      {:error, error} ->
        Logger.error("Partial chunk still not a valid json: #{inspect(error)}")

        state = Map.put(state, :partial_chunk, "#{current_partial_chunk}#{new_partial_chunk}")

        {:noreply, state}
    end
  end

  def handle_data(%{partial_chunk: new_partial_chunk}, state) do
    state = Map.put(state, :partial_chunk, new_partial_chunk)

    {:noreply, state}
  end

  def handle_data(data, %{content: current_content} = state) do
    empty_message = %{delta: %{content: nil}}

    choices = get_in(data, [Access.key!(:choices)]) || []

    next_token =
      choices
      |> List.first(empty_message)
      |> get_in([:delta, :content])

    # |> get_in([:delta, :function_call, :arguments])

    state = Map.put(state, :content, "#{current_content}#{next_token || ""}")

    {:noreply, state}
  end

  def handle_data(_data, state) do
    state =
      state
      |> Map.put(:streaming_client_pid, state[:stream_to])

    {:noreply, state}
  end

  @impl true
  def handle_error(error, %{caller_pid: caller_pid} = state) do
    Logger.error("Error streaming completion from OpenAI: #{inspect(error)} - #{inspect(state)}")

    send(caller_pid, {:error, error})
    {:noreply, state}
  end

  @impl true
  def handle_finish(
        %{caller_pid: caller_pid, content: content} =
          state
      ) do
    send(caller_pid, {:streamed_response, %{content: content}})

    {:noreply, state}
  end

  def handle_call({:set_stream_ref, hackney_stream_ref}, _from, state) do
    stream_timeout_timer =
      Process.send_after(self(), :stream_timeout, @streaming_response_timeout_ms)

    {:reply, :ok,
     state
     |> Map.put(:stream_ref, hackney_stream_ref)
     |> Map.put(:stream_timeout_timer, stream_timeout_timer)}
  end

  def handle_call(
        :end_stream,
        _from,
        %{stream_ref: hackney_stream_ref} = state
      ) do
    Logger.debug("Ending stream: #{inspect(state)}")

    with {:ok, _ref} <- :hackney.stop_async(hackney_stream_ref) do
      {:stop, :normal, :ok, state}
    else
      _ ->
        {:reply, :error, %{stream_ref: hackney_stream_ref}}
    end
  end

  def handle_info(
        :stream_timeout,
        %{caller_pid: caller_pid, stream_ref: hackney_stream_ref} = state
      ) do
    Logger.debug("Stream timeout: #{inspect(state)}")

    with {:ok, _ref} <- :hackney.stop_async(hackney_stream_ref) do
      send(caller_pid, :timeout_streamed_response)
      {:stop, :normal, state}
    else
      _ ->
        {:reply, :error, %{stream_ref: hackney_stream_ref}}
    end
  end
end
