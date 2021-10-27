# This file contains a modified implementation of Bech32/Bech32m encoder/decoder
# from https://github.com/lukaszsamson/elixir-bip0173
# Originally taken from https://github.com/stampery/elixir-bip0173

# Copyright (c) 2017 Adán Sánchez de Pedro Crespo
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

defmodule ZcashAddress.Bech32 do
  use Bitwise

  @moduledoc ~S"""
  Encode and decode the Bech32 and Bech32m format, with checksums.
  """

  # Encoding character set. Maps data value -> char
  @charset 'qpzry9x8gf2tvdw0s3jn54khce6mua7l'

  # Human-readable part and data part separator
  @separator 0x31

  # Generator coefficients
  @generator [0x3b6a57b2, 0x26508e6d, 0x1ea119fa, 0x3d4233dd, 0x2a1462b3]

  # Bech32m checksum constant
  @bech32m_const 0x2bc830a3

  @typedoc """
  Base32 code point
  """
  @type code_point_t :: 0..31

  @typedoc """
  Encoding type

  :bech32 defined in BIP0173
  :bech32m defined in BIP0350
  """
  @type encoding_t :: :bech32 | :bech32m

  @doc ~S"""
  Encode a Bech32/Bech32m string.

  ## Examples

      iex> Bech32.encode("bech32", [0, 1, 2], :bech32)
      "bech321qpz4nc4pe"

      iex> Bech32.encode("bech32", [0, 1, 2], :bech32m)
      "bech321qpzq0geym"

      iex> Bech32.encode("bc", [0, 14, 20, 15, 7, 13, 26, 0, 25, 18, 6, 11, 13,
      ...> 8, 21, 4, 20, 3, 17, 2, 29, 3, 12, 29, 3, 4, 15, 24, 20, 6, 14, 30, 22], :bech32)
      "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4"
  """
  @spec encode(String.t, list(code_point_t), encoding_t()) :: String.t
  def encode(hrp, data, encoding) when is_list(data) do
    unless byte_size(hrp) in 1..83 do
      raise ArgumentError, message: "invalid hrp length"
    end

    if hrp |> :binary.bin_to_list |> Enum.any?(& &1 < 33 || &1 > 126) do
      raise ArgumentError, message: "illegal character in hrp"
    end

    checksummed = data ++ create_checksum(hrp, data, encoding)
    dp = for (i <- checksummed), into: "", do: <<Enum.at(@charset, i)>>
    <<hrp::binary, @separator, dp::binary>>
  end

  @spec encode(String.t, String.t, encoding_t()) :: String.t
  def encode(hrp, data, encoding) when is_binary(data) do
    encode(hrp, :binary.bin_to_list(data), encoding)
  end

  @doc ~S"""
  Decode a Bech32/Bech32m string.

  ## Examples

      iex> Bech32.decode("bech321qpz4nc4pe")
      {:ok, {"bech32", [0, 1, 2], :bech32}}

      iex> Bech32.decode("bech321qpzq0geym")
      {:ok, {"bech32", [0, 1, 2], :bech32m}}

      iex> Bech32.decode("bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4")
      {:ok, {"bc", [0, 14, 20, 15, 7, 13, 26, 0, 25, 18, 6, 11, 13, 8, 21,
        4, 20, 3, 17, 2, 29, 3, 12, 29, 3, 4, 15, 24, 20, 6, 14, 30, 22], :bech32}}
  """
  @spec decode(String.t) :: {:ok, {String.t, list(code_point_t), encoding_t()}} | {:error, String.t}
  def decode(bech) do
    with  {_, false}  <- {:mixed,  String.downcase(bech) != bech &&
            String.upcase(bech) != bech},
          bech_charlist = :binary.bin_to_list(bech),
          {_, nil} <- {:oor, Enum.find(
            bech_charlist,
            fn (c) -> c < 33 || c > 126 end
          )},
          bech = String.downcase(bech),
          len = Enum.count(bech_charlist),
          pos = Enum.find_index(Enum.reverse(bech_charlist), fn (c) ->
            c == @separator
          end),
          {_, true} <- {:oor_sep, pos != nil},
          pos = len - pos - 1,
          {_, false} <- {:empty_hrp, pos < 1},
          {_, false, _} <- {:short_cs, pos + 7 > len, len},
          <<hrp::binary-size(pos), @separator, data::binary>> = bech,
          data_charlist = (for c <- :binary.bin_to_list(data) do
            Enum.find_index(@charset, fn (d) -> c == d end)
          end),
          {_, nil} <- {:oor_data, Enum.find_index(
            data_charlist,
            fn (c) -> c < 0 || c > 31 end
          )},
          {_, {:ok, encoding}} <- {:cs, verify_checksum(hrp, data_charlist)},
          data_len = Enum.count(data_charlist),
          data = Enum.slice(data_charlist, 0, data_len - 6)
          do
            {:ok, {hrp, data, encoding}}
          else
            {:mixed, _} -> {:error, "Mixed case"}
            {:oor, c} -> {:error, "Character #{inspect(<<c>>)} out of range (#{c})"}
            {:oor_sep, _} -> {:error, "No separator character"}
            {:empty_hrp, _} -> {:error, "Empty HRP"}
            {:short_cs, _, l} -> {:error, "Too short checksum (#{l})"}
            {:too_long, _, l} -> {:error, "Overall max length exceeded (#{l})"}
            {:oor_data, c} -> {:error, "Invalid data character #{inspect(<<c>>)} (#{c})}"}
            {:cs, _} -> {:error, "Invalid checksum"}
            _ -> {:error, "Unknown error"}
          end
    end

  # Create a checksum.
  defp create_checksum(hrp, data, encoding) do
    values = expand_hrp(hrp) ++ data ++ [0, 0, 0, 0, 0, 0]
    mod = Bitwise.bxor(polymod(values), get_encoding_const(encoding))
    for p <- 0..5, do: (mod >>> 5 * (5 - p)) &&& 31
  end

  # Verify a checksum.
  defp verify_checksum(hrp, data) do
    case polymod(expand_hrp(hrp) ++ data) do
      1 -> {:ok, :bech32}
      @bech32m_const -> {:ok, :bech32m}
      _ -> :error
    end
  end

  # Gets checksum constant
  defp get_encoding_const(:bech32), do: 1
  defp get_encoding_const(:bech32m), do: @bech32m_const

  # Expand a HRP for use in checksum computation.
  defp expand_hrp(hrp) do
    hrp_charlist = :binary.bin_to_list(hrp)
    a_values = for c <- hrp_charlist, do: c >>> 5
    b_values = for c <- hrp_charlist, do: c &&& 31
    a_values ++ [0] ++ b_values
  end

  # Find the polynomial with value coefficients mod the generator as 30-bit.
  defp polymod(values) do
    Enum.reduce(values, 1, fn (v, chk) ->
      top = chk >>> 25
      chk = Bitwise.bxor(((chk &&& 0x1ffffff) <<< 5), v)
      Enum.reduce((for i <- 0..4, do: i), chk, fn(i, chk) ->
        Bitwise.bxor(chk, if ((top >>> i) &&& 1) != 0 do
          Enum.at(@generator, i)
        else
          0
        end)
      end)
    end)
  end

  # General power-of-2 base conversion.
  def convert_bits(data, from, to, pad \\ true) do
    max_v = (1 <<< to) - 1
    if (Enum.find(data, fn (c) -> c < 0 || (c >>> from) != 0 end)) do
      nil
    else
      {acc, bits, ret} = Enum.reduce(
        data,
        {0, 0, []},
        fn (value, {acc, bits, ret}) ->
          acc = ((acc <<< from) ||| value)
          bits = bits + from
          {bits, ret} = convert_bits_loop(to, max_v, acc, bits, ret)
          {acc, bits, ret}
        end
      )
      if (pad && bits > 0) do
        ret ++ [(acc <<< (to - bits)) &&& max_v]
      else
        if (bits > from || ((acc <<< (to - bits)) &&& max_v) > 0) do
          nil
        else
          ret
        end
      end
    end
  end

  # Recursive version of the inner loop of the convert_bits function
  defp convert_bits_loop(to, max_v, acc, bits, ret) do
    if (bits >= to) do
      bits = bits - to
      ret = ret ++ [(acc >>> bits) &&& max_v]
      convert_bits_loop(to, max_v, acc, bits, ret)
    else
      {bits, ret}
    end
  end
end
