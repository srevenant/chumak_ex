# Generated by erl2ex (http://github.com/dazuma/erl2ex)
# From Erlang source: (Unknown source file)
# At: 2022-05-02 12:33:56

defmodule :chumak_pull do
  require Record

  @behaviour :chumak_pattern

  @erlrecordfields_chumak_pull [:identity, :pending_recv, :pending_recv_multipart, :recv_queue]
  Record.defrecordp(:erlrecord_chumak_pull, :chumak_pull,
    identity: :undefined,
    pending_recv: :undefined,
    pending_recv_multipart: :undefined,
    recv_queue: :undefined
  )

  def valid_peer_type(:push) do
    :valid
  end

  def valid_peer_type(_) do
    :invalid
  end

  def init(var_identity) do
    state =
      erlrecord_chumak_pull(
        identity: var_identity,
        recv_queue: :queue.new(),
        pending_recv: nil,
        pending_recv_multipart: nil
      )

    {:ok, state}
  end

  def terminate(
        _reason,
        erlrecord_chumak_pull(pending_recv: var_recv, pending_recv_multipart: recvM)
      ) do
    case(var_recv) do
      {:from, from} ->
        :gen_server.reply(from, {:error, :closed})

      _ ->
        :ok
    end

    case(recvM) do
      {:from, fromM} ->
        :gen_server.reply(fromM, {:error, :closed})

      _ ->
        :ok
    end

    :ok
  end

  def identity(erlrecord_chumak_pull(identity: var_identity)) do
    var_identity
  end

  def peer_flags(_state) do
    {:pull, [:incoming_queue]}
  end

  def accept_peer(state, peerPid) do
    {:reply, {:ok, peerPid}, state}
  end

  def peer_ready(state, _peerPid, _identity) do
    {:noreply, state}
  end

  def send(state, data, from) do
    send_multipart(state, [data], from)
  end

  def recv(erlrecord_chumak_pull(pending_recv: nil, pending_recv_multipart: nil) = state, from) do
    case(:queue.out(erlrecord_chumak_pull(state, :recv_queue))) do
      {{:value, multipart}, newRecvQueue} ->
        msg = :binary.list_to_bin(multipart)
        {:reply, {:ok, msg}, erlrecord_chumak_pull(state, recv_queue: newRecvQueue)}

      {:empty, _recvQueue} ->
        {:noreply, erlrecord_chumak_pull(state, pending_recv: {:from, from})}
    end
  end

  def recv(state, _from) do
    {:reply, {:error, :already_pending_recv}, state}
  end

  def send_multipart(state, _multipart, _from) do
    {:reply, {:error, :not_use}, state}
  end

  def recv_multipart(
        erlrecord_chumak_pull(pending_recv: nil, pending_recv_multipart: nil) = state,
        from
      ) do
    case(:queue.out(erlrecord_chumak_pull(state, :recv_queue))) do
      {{:value, multipart}, newRecvQueue} ->
        {:reply, {:ok, multipart}, erlrecord_chumak_pull(state, recv_queue: newRecvQueue)}

      {:empty, _recvQueue} ->
        {:noreply, erlrecord_chumak_pull(state, pending_recv_multipart: {:from, from})}
    end
  end

  def recv_multipart(state, _from) do
    {:reply, {:error, :already_pending_recv}, state}
  end

  def peer_recv_message(state, _message, _from) do
    {:noreply, state}
  end

  def unblock(
        erlrecord_chumak_pull(pending_recv: var_recv, pending_recv_multipart: multiRecv) = state,
        _from
      ) do
    newState =
      case(var_recv) do
        {:from, from} ->
          :gen_server.reply(from, {:error, :again})
          erlrecord_chumak_pull(state, pending_recv: nil)

        nil ->
          state
      end

    multiNewState =
      case(multiRecv) do
        {:from, multiFrom} ->
          :gen_server.reply(multiFrom, {:error, :again})
          erlrecord_chumak_pull(newState, pending_recv_multipart: nil)

        nil ->
          newState
      end

    {:reply, :ok, multiNewState}
  end

  def queue_ready(state, _identity, peerPid) do
    case(:chumak_peer.incoming_queue_out(peerPid)) do
      {:out, multipart} ->
        {:noreply, handle_queue_ready(state, multipart)}

      :empty ->
        {:noreply, state}

      {:error, info} ->
        :error_logger.info_msg('can\'t get message out in ~p with reason: ~p~n', [
          :chumak_pull,
          info
        ])

        {:noreply, state}
    end
  end

  def peer_disconected(state, _peerPid) do
    {:noreply, state}
  end

  defp handle_queue_ready(
         erlrecord_chumak_pull(pending_recv: nil, pending_recv_multipart: nil) = state,
         data
       ) do
    newRecvQueue = :queue.in(data, erlrecord_chumak_pull(state, :recv_queue))
    erlrecord_chumak_pull(state, recv_queue: newRecvQueue)
  end

  defp handle_queue_ready(
         erlrecord_chumak_pull(pending_recv: {:from, pendingRecv}, pending_recv_multipart: nil) =
           state,
         data
       ) do
    msg = :binary.list_to_bin(data)
    :gen_server.reply(pendingRecv, {:ok, msg})
    erlrecord_chumak_pull(state, pending_recv: nil)
  end

  defp handle_queue_ready(
         erlrecord_chumak_pull(pending_recv: nil, pending_recv_multipart: {:from, pendingRecv}) =
           state,
         data
       ) do
    :gen_server.reply(pendingRecv, {:ok, data})
    erlrecord_chumak_pull(state, pending_recv_multipart: nil)
  end
end