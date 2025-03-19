defmodule ZcashAddress.UtilsTest do
  use ExUnit.Case
  import ZcashAddress.Utils

  test "i2leosp" do
    assert i2leosp(5, 7) == <<0x07>>
    assert i2leosp(32, 1_234_567_890) == <<0xD2, 0x02, 0x96, 0x49>>

    assert i2leosp(9, 256) == <<0x00, 0x01>>
    assert i2leosp(9, 1) == <<0x01, 0x00>>
  end
end
