defmodule ZcashAddress.ZCUtils do
  @max_size 0x2000000

  def write_compact_size(n, allow_u64 \\ false) when allow_u64 or n <= @max_size do
    cond do
      n < 253 ->
        << n >>
      n <= 0xFFFF ->
        endoded = :binary.encode_unsigned(n, :little)
        pad = 2 - byte_size(endoded)
        padding = if pad > 0, do: (for _ <- 1..pad, into: <<>>, do: << 0 >>), else: <<>>
        << 253 >> <> endoded <> padding
      n <= 0xFFFFFFFF ->
        endoded = :binary.encode_unsigned(n, :little)
        pad = 4 - byte_size(endoded)
        padding = if pad > 0, do: (for _ <- 1..pad, into: <<>>, do: << 0 >>), else: <<>>
        << 254 >> <> endoded <> padding
      true ->
        endoded = :binary.encode_unsigned(n, :little)
        pad = 8 - byte_size(endoded)
        padding = if pad > 0, do: (for _ <- 1..pad, into: <<>>, do: << 0 >>), else: <<>>
        << 255 >> <> endoded <> padding
    end
  end

  def parse_compact_size(rest, allow_u64 \\ false) do
    case parse_compact_u64(rest) do
      {n, rest} when allow_u64 or n <= @max_size -> {n, rest}
    end
  end

  def parse_compact_u64(<< b, rest::binary>>) do
    cond do
      b < 253 ->
        {b, rest}
      b == 253 ->
        << encoded::size(16), other::binary >> = rest
        case :binary.decode_unsigned(<< encoded::size(16) >>, :little) do
          n when n >= 253 -> {n, other}
        end
      b == 254 ->
        << encoded::size(32), other::binary >> = rest
        case :binary.decode_unsigned(<< encoded::size(32) >>, :little) do
          n when n >= 0x10000 -> {n, other}
        end
      b == 255 ->
        << encoded::size(64), other::binary >> = rest
        case :binary.decode_unsigned(<< encoded::size(64) >>, :little) do
          n when n >= 0x100000000 -> {n, other}
        end
      end
    end
end
