defmodule ZcashAddress.UnifiedAddress do
  alias ZcashAddress.{ZCUtils, Bech32, F4Jumble, Utils}

  @receiver_lengths %{0 => 20, 1 => 20, 2 => 43, 3 => 43}
  @hrp_padded 16

  defp parse_receivers(<<>>, acc), do: acc

  defp parse_receivers(rest, acc) do
    with rest_size when rest_size > 2 <- byte_size(rest),
         {receiver_type, rest} = ZCUtils.parse_compact_size(rest),
         {receiver_len, rest} = ZCUtils.parse_compact_size(rest),
         %{^receiver_type => ^receiver_len} <- @receiver_lengths,
         rest_size when rest_size >= receiver_len <- byte_size(rest),
         receiver = :binary.part(rest, 0, receiver_len),
         rest = :binary.part(rest, receiver_len, rest_size - receiver_len),
         acc when is_map(acc) <-
           (cond do
              (receiver_type == 1 or receiver_type == 0) and not Map.has_key?(acc, :transparent) ->
                acc |> Map.put(:transparent, receiver)

              receiver_type == 2 and not Map.has_key?(acc, :sapling) ->
                acc |> Map.put(:sapling, receiver)

              receiver_type == 3 and not Map.has_key?(acc, :orchard) ->
                acc |> Map.put(:orchard, receiver)

              true ->
                :error
            end) do
      parse_receivers(rest, acc)
    else
      _ -> :error
    end
  end

  def parse(unified_addr_str) do
    with {:ok, {hrp, decoded, :bech32m}} when hrp in ["u", "utest"] <-
           Bech32.decode(unified_addr_str),
         decoded = decoded |> Bech32.convert_bits(5, 8, false) |> :binary.list_to_bin(),
         unjumbled = decoded |> F4Jumble.f4jumble_inv(),
         size when size > @hrp_padded <- byte_size(unjumbled),
         suffix = :binary.part(unjumbled, size - @hrp_padded, @hrp_padded),
         rest = :binary.part(unjumbled, 0, size - @hrp_padded),
         expected_padding = Utils.hrp_padding(hrp),
         ^expected_padding <- suffix,
         map when is_map(map) <- parse_receivers(rest, %{}),
         true <- Map.has_key?(map, :sapling) or Map.has_key?(map, :orchard) do
      {:ok, hrp, map}
    else
      _ -> :error
    end
  end
end
