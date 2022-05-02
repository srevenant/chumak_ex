# Generated by erl2ex (http://github.com/dazuma/erl2ex)
# From Erlang source: (Unknown source file)
# At: 2022-05-02 12:33:57

defmodule :chumak_resource do
  require Record

  @behaviour :gen_server

  @spec start_link() :: {:ok, pid()} | {:error, term()}

  def start_link() do
    :gen_server.start_link(__MODULE__, {}, [])
  end

  @erlrecordfields_state [:resources, :monitors]
  Record.defrecordp(:erlrecord_state, :state, resources: :undefined, monitors: :undefined)

  def init(_args) do
    :erlang.process_flag(:trap_exit, true)
    state = erlrecord_state(resources: %{}, monitors: %{})
    {:ok, state}
  end

  def code_change(_oldVsn, state, _extra) do
    {:ok, state}
  end

  def handle_call({:accept, socketPid}, _from, state) do
    case(:chumak_peer.accept(:none, socketPid, [:multi_socket_type])) do
      {:ok, pid} ->
        {:reply, {:ok, pid}, state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:bind, :tcp, host, port}, _from, state) do
    reply = :chumak_bind.start_link(host, port)
    {:reply, reply, state}
  end

  def handle_call({:bind, protocol, _host, _port}, _from, state) do
    {:reply, {:error, {:unsupported_protocol, protocol}}, state}
  end

  def handle_call(
        {:route_resource, resource},
        _from,
        erlrecord_state(resources: resources) = state
      ) do
    case(:maps.find(resource, resources)) do
      {:ok, newSocket} ->
        flags = :gen_server.call(newSocket, :get_flags)
        {:reply, {:change_socket, newSocket, flags}, state}

      :error ->
        {:reply, :close, state}
    end
  end

  def handle_cast(
        {:attach, resource, socketPid},
        erlrecord_state(resources: resources, monitors: monitors) = state
      ) do
    newResources = Map.merge(resources, %{resource => socketPid})
    monRef = :erlang.monitor(:process, socketPid)
    newMonitors = Map.merge(monitors, %{socketPid => {resource, monRef}})
    {:noreply, erlrecord_state(state, resources: newResources, monitors: newMonitors)}
  end

  def handle_cast(
        {:detach, resource},
        erlrecord_state(resources: resources, monitors: monitors) = state
      ) do
    case(:maps.take(resource, resources)) do
      {socketPid, newResources} ->
        case(:maps.take(socketPid, monitors)) do
          {{^resource, monRef}, newMonitors} ->
            :erlang.demonitor(monRef)
            {:noreply, erlrecord_state(state, resources: newResources, monitors: newMonitors)}

          _ ->
            {:noreply, erlrecord_state(state, resources: newResources)}
        end

      _ ->
        {:noreply, state}
    end
  end

  def handle_cast(castMsg, state) do
    :error_logger.info_report([:unhandled_handle_cast, {:module, __MODULE__}, {:msg, castMsg}])
    {:noreply, state}
  end

  def handle_info(
        {:DOWN, monRef, :process, socketPid, _},
        erlrecord_state(resources: resources, monitors: monitors) = state
      ) do
    case(:maps.take(socketPid, monitors)) do
      {{resource, ^monRef}, newMonitors} ->
        newResources = :maps.remove(resource, resources)
        {:noreply, erlrecord_state(state, resources: newResources, monitors: newMonitors)}

      _ ->
        {:noreply, state}
    end
  end

  def handle_info({:EXIT, _pid, {:shutdown, :invalid_resource}}, state) do
    {:noreply, state}
  end

  def handle_info(infoMsg, state) do
    :error_logger.info_report([:unhandled_handle_info, {:module, __MODULE__}, {:msg, infoMsg}])
    {:noreply, state}
  end

  def terminate(_reason, _state) do
    :ok
  end
end
