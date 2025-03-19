defmodule ZcashAddress.ZCUtilsTest do
  use ExUnit.Case
  import ZcashAddress.ZCUtils

  @compact_vectors [
    {0, "00"},
    {1, "01"},
    {252, "FC"},
    {253, "FDFD00"},
    {254, "FDFE00"},
    {255, "FDFF00"},
    {256, "FD0001"},
    {0xFFFE, "FDFEFF"},
    {0xFFFF, "FDFFFF"},
    {0x010000, "FE00000100"},
    {0x010001, "FE01000100"},
    {0x02000000, "FE00000002"}
  ]

  @compact_vectors_long [
    {0xFFFFFFFE, "FEFEFFFFFF"},
    {0xFFFFFFFF, "FEFFFFFFFF"},
    {0x0100000000, "FF0000000001000000"},
    {0xFFFFFFFFFFFFFFFF, "FFFFFFFFFFFFFFFFFF"}
  ]

  test "write_compact" do
    for {n, encoded} <- @compact_vectors,
        allow_u64 <- [true, false] do
      assert encoded == write_compact_size(n, allow_u64) |> Base.encode16()
    end

    for {n, encoded} <- @compact_vectors_long do
      assert encoded == write_compact_size(n, true) |> Base.encode16()
    end
  end

  test "parse_compact" do
    for {n, encoded} <- @compact_vectors,
        allow_u64 <- [true, false] do
      assert {n, <<>>} == parse_compact_size(encoded |> Base.decode16!(), allow_u64)
    end

    for {n, encoded} <- @compact_vectors_long do
      assert {n, <<>>} == parse_compact_size(encoded |> Base.decode16!(), true)
    end
  end
end
