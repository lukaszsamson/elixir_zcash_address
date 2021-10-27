defmodule ZcashAddress.Utils do

  def hrp_padding(hrp) do
    pad = 16 - byte_size(hrp)
    if pad < 0 do
      raise ArgumentError
    end
    hrp <> if pad != 0, do: (for _ <- 1..pad, into: <<>>, do: <<0>>), else: <<>>
  end

  def cldiv(n, divisor) do
    div((n + (divisor - 1)), divisor)
  end

  # This should be equivalent to LEBS2OSP(I2LEBSP(l, x))
  def i2leosp(l, x) do
    d = cldiv(l, 8)
    enc = :binary.encode_unsigned(x, :little)
    pad = d - byte_size(enc)
    padding = if pad != 0, do: (for _ <- 1..pad, into: <<>>, do: << 0 >>), else: <<>>
    enc <> padding
  end
end
