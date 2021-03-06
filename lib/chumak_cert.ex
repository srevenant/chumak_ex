# Generated by erl2ex (http://github.com/dazuma/erl2ex)
# From Erlang source: (Unknown source file)
# At: 2022-05-02 12:33:51

defmodule :chumak_cert do
  @spec read(char_list()) :: list({:public_key | :private_key, binary()}) | {:error, term()}

  def read(fileName) do
    {:ok, file} = :file.open(fileName, [:read])
    find_curve_section(file)
  end

  defp find_curve_section(file) do
    case(:file.read_line(file)) do
      {:ok, string} ->
        case(:re.run(string, '^curve *\\n')) do
          {:match, _} ->
            find_keys(file, [])

          :nomatch ->
            find_curve_section(file)
        end

      :eof ->
        {:error, :no_curve_section}
    end
  end

  defp find_keys(file, acc) do
    case(:file.read_line(file)) do
      :eof ->
        {:ok, :lists.reverse(acc)}

      {:ok, string} ->
        case(parse_key(string)) do
          {:ok, key} ->
            find_keys(file, [key | acc])

          :continue ->
            find_keys(file, acc)

          :end_of_section ->
            {:ok, :lists.reverse(acc)}

          error ->
            error
        end
    end
  end

  defmacrop erlconst_VALUE_SPEC() do
    quote do
      '^ *= *"(.*)" *$'
    end
  end

  defp parse_key('    public-key' ++ value) do
    case(:re.run(value, erlconst_VALUE_SPEC())) do
      {:match, [_, {start, var_length}]} ->
        keyEncoded = :string.substr(value, start + 1, var_length)
        {:ok, {:public_key, :chumak_z85.decode(keyEncoded)}}

      _ ->
        {:error, :invalid_public_key_spec}
    end
  end

  defp parse_key('    secret-key' ++ value) do
    case(:re.run(value, erlconst_VALUE_SPEC())) do
      {:match, [_, {start, var_length}]} ->
        keyEncoded = :string.substr(value, start + 1, var_length)
        {:ok, {:secret_key, :chumak_z85.decode(keyEncoded)}}

      _ ->
        {:error, :invalid_secret_key_spec}
    end
  end

  defp parse_key('    ' ++ _) do
    :continue
  end

  defp parse_key(other) do
    case(:re.run(other, '^ *#')) do
      {:match, _} ->
        :continue

      _ ->
        :end_of_section
    end
  end
end
