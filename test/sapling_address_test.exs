defmodule ZcashAddress.SaplingAddressTest do
  use ExUnit.Case

  test "parse" do
    expected_big_endian = "34ed1f60f5db5763beee1ddbb37dd5f7e541d4d4fbdcc09fbfcc6b8e949bbe9d"
    expected_little_endian_binary = expected_big_endian |> Base.decode16!(case: :lower) |> :binary.decode_unsigned(:big) |> :binary.encode_unsigned(:little)
    expected_little_endian = expected_little_endian_binary |> Base.encode16(case: :lower)
    assert {:ok, "zs", "1787997c30e94f050c634d", ^expected_little_endian} = ZcashAddress.SaplingAddress.parse("zs1z7rejlpsa98s2rrrfkwmaxu53e4ue0ulcrw0h4x5g8jl04tak0d3mm47vdtahatqrlkngh9slya")
  end

end
