# Generated by erl2ex (http://github.com/dazuma/erl2ex)
# From Erlang source: (Unknown source file)
# At: 2022-05-02 12:33:59

defmodule :chumak_sup do
  @behaviour :supervisor

  # Begin included file: chumak.hrl

  @type transport() :: :tcp

  @type socket_type() ::
          :req | :rep | :dealer | :router | :pub | :xpub | :sub | :xsub | :push | :pull | :pair

  @typep z85_key() :: char_list()

  @typep socket_option() ::
           :curve_server
           | :curve_publickey
           | :curve_secretkey
           | :curve_serverkey
           | :curve_clientkeys

  @typep security_mechanism() :: :null | :curve

  defmacrop erlmacro_SOCKET_OPTS(opts) do
    quote do
      :lists.append([:binary, {:active, false}, {:reuseaddr, true}], unquote(opts))
    end
  end

  defmacrop erlconst_GREETINGS_TIMEOUT() do
    quote do
      1000
    end
  end

  defmacrop erlconst_RECONNECT_TIMEOUT() do
    quote do
      2000
    end
  end

  # End included file: chumak.hrl

  defmacrop erlconst_SUPERVISOR_FLAGS() do
    quote do
      %{strategy: :one_for_one}
    end
  end

  defmacrop erlconst_CHILD_PROCESS_PREFIX() do
    quote do
      'chumak_socket_'
    end
  end

  defmacrop erlconst_SOCKET() do
    quote do
      :chumak_socket
    end
  end

  defmacrop erlconst_RESOURCE() do
    quote do
      :chumak_resource
    end
  end

  def start_link() do
    :supervisor.start_link({:local, __MODULE__}, __MODULE__, [])
  end

  def init(_args) do
    {:ok, {erlconst_SUPERVISOR_FLAGS(), []}}
  end

  @spec start_socket(socket_type(), char_list()) :: {:ok, pid()} | {:error, atom()}

  def start_socket(type, identity) do
    processId = get_child_id(identity)

    case(
      :supervisor.start_child(__MODULE__, %{
        id: processId,
        restart: :transient,
        start: {erlconst_SOCKET(), :start_link, [type, identity]}
      })
    ) do
      {:error, :already_present} ->
        :supervisor.restart_child(__MODULE__, processId)

      res ->
        res
    end
  end

  def start_socket(type) do
    erlconst_SOCKET().start_link(type, [])
  end

  def start_resource() do
    erlconst_RESOURCE().start_link()
  end

  def get_child_id(identity) do
    :erlang.list_to_atom(:string.concat(erlconst_CHILD_PROCESS_PREFIX(), identity))
  end
end
