# Generated by erl2ex (http://github.com/dazuma/erl2ex)
# From Erlang source: (Unknown source file)
# At: 2022-05-02 12:33:58

defmodule :chumak_socket do
  require Record

  @behaviour :gen_server

  @erlrecordfields_state [:socket, :socket_state, :socket_options, :identity]
  Record.defrecordp(:erlrecord_state, :state,
    socket: :undefined,
    socket_state: :undefined,
    socket_options: %{},
    identity: :undefined
  )

  @spec start_link(term(), char_list()) :: {:ok, pid()} | {:error, term()}

  def start_link(type, identity) when is_atom(type) and is_list(identity) do
    :gen_server.start_link(__MODULE__, {type, identity}, [])
  end

  @spec stop(pid()) :: :ok

  def stop(pid) do
    :gen_server.stop(pid)
  end

  def init({type, identity}) do
    :erlang.process_flag(:trap_exit, true)

    case(:chumak_pattern.module(type)) do
      {:error, reason} ->
        {:stop, reason}

      moduleName ->
        {:ok, s} = moduleName.init(identity)
        {:ok, erlrecord_state(socket: moduleName, socket_state: s, identity: identity)}
    end
  end

  def code_change(_oldVsn, state, _extra) do
    {:ok, state}
  end

  def handle_call({:set_option, optionName, optionValue}, _from, state) do
    set_option(optionName, optionValue, state)
  end

  def handle_call({:connect, protocol, host, port, resource}, _from, state) do
    connect(protocol, host, port, resource, state)
  end

  def handle_call({:accept, socketPid}, _from, state) do
    accept(socketPid, state)
  end

  def handle_call({:send, data}, from, state) do
    func_send(data, from, state)
  end

  def handle_call(:recv, from, state) do
    recv(from, state)
  end

  def handle_call({:send_multipart, multipart}, from, state) do
    send_multipart(multipart, from, state)
  end

  def handle_call(:recv_multipart, from, state) do
    recv_multipart(from, state)
  end

  def handle_call(:unblock, from, state) do
    unblock(from, state)
  end

  def handle_call({:bind, :tcp, host, port}, _from, state) do
    reply = :chumak_bind.start_link(host, port)
    {:reply, reply, state}
  end

  def handle_call(:get_flags, _from, state) do
    get_flags(state)
  end

  def handle_call({:bind, protocol, _host, _port}, _from, state) do
    {:reply, {:error, {:unsupported_protocol, protocol}}, state}
  end

  def handle_cast({:peer_ready, from, identity}, state) do
    peer_ready(from, identity, state)
  end

  def handle_cast({:subscribe, topic}, state) do
    pattern_support(state, :subscribe, [topic])
  end

  def handle_cast({:cancel, topic}, state) do
    pattern_support(state, :cancel, [topic])
  end

  def handle_cast({:peer_subscribe, from, subscription}, state) do
    pattern_support(state, :peer_subscribe, [from, subscription])
  end

  def handle_cast({:peer_cancel_subscribe, from, subscription}, state) do
    pattern_support(state, :peer_cancel_subscribe, [from, subscription])
  end

  def handle_cast({:peer_reconnected, from}, state) do
    pattern_support(state, :peer_reconnected, [from], :nowarn)
  end

  def handle_cast(castMsg, state) do
    :error_logger.info_report([:unhandled_handle_cast, {:module, __MODULE__}, {:msg, castMsg}])
    {:noreply, state}
  end

  def handle_info({:peer_recv_message, message, from}, state) do
    peer_recv_message(message, from, state)
  end

  def handle_info({:queue_ready, identity, from}, state) do
    queue_ready(identity, from, state)
  end

  def handle_info({:EXIT, peerPid, _other}, state) do
    exit_peer(peerPid, state)
  end

  def handle_info(infoMsg, state) do
    :error_logger.info_report([:unhandled_handle_info, {:module, __MODULE__}, {:msg, infoMsg}])
    {:noreply, state}
  end

  def terminate(reason, erlrecord_state(socket: mod, socket_state: s)) do
    mod.terminate(reason, s)
    :ok
  end

  defp store({:reply, m, s}, state) do
    {:reply, m, erlrecord_state(state, socket_state: s)}
  end

  defp store({:noreply, s}, state) do
    {:noreply, erlrecord_state(state, socket_state: s)}
  end

  defp set_option(name, value, erlrecord_state(socket_options: options) = state)
       when (name === :curve_server and is_boolean(value)) or
              (name === :curve_publickey and is_binary(value)) or
              (name === :curve_secretkey and is_binary(value)) or
              (name === :curve_serverkey and is_binary(value)) do
    {:reply, :ok, erlrecord_state(state, socket_options: Map.merge(options, %{name => value}))}
  end

  defp set_option(name, value, erlrecord_state(socket_options: options) = state)
       when name === :curve_clientkeys do
    case(validate_keys(value)) do
      {:ok, binaryKeys} ->
        {:reply, :ok,
         erlrecord_state(state, socket_options: Map.merge(options, %{name => binaryKeys}))}

      {:error, _error} ->
        {:reply, {:error, :einval}, state}
    end
  end

  defp set_option(_name, _value, state) do
    {:reply, {:error, :einval}, state}
  end

  defp connect(
         protocol,
         host,
         port,
         resource,
         erlrecord_state(socket: s, socket_state: t) = state
       ) do
    {socketType, peerOpts} = peer_flags(state)

    case(:chumak_peer.connect(socketType, protocol, host, port, resource, peerOpts)) do
      {:ok, pid} ->
        reply = s.accept_peer(t, pid)
        store(reply, state)

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  defp accept(socketPid, erlrecord_state(socket: s, socket_state: t) = state) do
    {socketType, peerOpts} = peer_flags(state)

    case(:chumak_peer.accept(socketType, socketPid, peerOpts)) do
      {:ok, pid} ->
        reply = s.accept_peer(t, pid)
        store(reply, state)

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  defp func_send(data, from, erlrecord_state(socket: s, socket_state: t) = state) do
    reply = s.send(t, data, from)
    store(reply, state)
  end

  defp recv(from, erlrecord_state(socket: s, socket_state: t) = state) do
    reply = s.recv(t, from)
    store(reply, state)
  end

  defp send_multipart(multipart, from, erlrecord_state(socket: s, socket_state: t) = state) do
    reply = s.send_multipart(t, multipart, from)
    store(reply, state)
  end

  defp recv_multipart(from, erlrecord_state(socket: s, socket_state: t) = state) do
    reply = s.recv_multipart(t, from)
    store(reply, state)
  end

  defp unblock(from, erlrecord_state(socket: s, socket_state: t) = state) do
    reply = s.unblock(t, from)
    store(reply, state)
  end

  defp get_flags(state) do
    {:reply, peer_flags(state), state}
  end

  defp peer_ready(from, identity, erlrecord_state(socket: s, socket_state: t) = state) do
    reply = s.peer_ready(t, from, identity)
    store(reply, state)
  end

  defp pattern_support(state, function, args) do
    pattern_support(state, function, args, :warn)
  end

  defp pattern_support(erlrecord_state(socket: s, socket_state: t) = state, function, args, alert) do
    isExported = :erlang.function_exported(s, function, length(args) + 1)

    case({isExported, alert}) do
      {true, _} ->
        store(apply(s, function, [t] ++ args), state)

      {false, :warn} ->
        :error_logger.warning_report([
          :pattern_not_supported,
          {:module, s},
          {:method, function},
          {:args, args}
        ])

        {:noreply, state}

      {false, _} ->
        {:noreply, state}
    end
  end

  defp peer_recv_message(message, from, erlrecord_state(socket: s, socket_state: t) = state) do
    reply = s.peer_recv_message(t, message, from)
    store(reply, state)
  end

  defp queue_ready(identity, from, erlrecord_state(socket: s, socket_state: t) = state) do
    reply = s.queue_ready(t, identity, from)
    store(reply, state)
  end

  defp exit_peer(peerPid, erlrecord_state(socket: s, socket_state: t) = state) do
    reply = s.peer_disconected(t, peerPid)
    store(reply, state)
  end

  defp peer_flags(
         erlrecord_state(socket: socket, socket_state: socketState, socket_options: socketOptions)
       ) do
    {socketType, peerOpts} = socket.peer_flags(socketState)
    identity = socket.identity(socketState)
    {socketType, :lists.flatten([{:identity, identity}, :maps.to_list(socketOptions), peerOpts])}
  end

  defp validate_keys(keys) when is_list(keys) do
    validate_keys(keys, [])
  end

  defp validate_keys(:any) do
    {:ok, :any}
  end

  defp validate_keys(_other) do
    {:error, :einval}
  end

  defp validate_keys([], acc) do
    {:ok, :lists.reverse(acc)}
  end

  defp validate_keys([key | t], acc) when is_list(key) do
    try do
      :chumak_z85.decode(key)
    catch
      _, _ ->
        {:error, 'Failed to decode Z85 key'}
    else
      binary ->
        validate_keys(t, [binary | acc])
    end
  end

  defp validate_keys([key | t], acc) when is_binary(key) do
    validate_keys(t, [key | acc])
  end

  defp validate_keys(_, _) do
    {:error, 'Invalid type for key'}
  end
end
