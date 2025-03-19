defmodule ZcashAddress.SaplingAddress do
  alias ZcashAddress.Bech32

  def parse(sapling_address) do
    with {:ok, {hrp, decoded, :bech32}} when hrp in ["zs", "ztestsapling"] <-
           Bech32.decode(sapling_address),
         decoded = decoded |> Bech32.convert_bits(5, 8, false) |> :binary.list_to_bin(),
         43 <- byte_size(decoded),
         diversifier = :binary.part(decoded, 0, 11),
         diversifiedtransmissionkey = :binary.part(decoded, 11, 32) do
      {:ok, hrp, diversifier |> Base.encode16(case: :lower),
       diversifiedtransmissionkey |> Base.encode16(case: :lower)}
    end
  end
end
