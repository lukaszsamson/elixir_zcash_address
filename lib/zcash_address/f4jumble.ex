defmodule ZcashAddress.F4Jumble do
  import ZcashAddress.Utils
  import Bitwise
  alias Blake2.Blake2b
  # Maximum output length of BLAKE2b
  @l_H 64

  unless 512 == 8 * @l_H do
    raise ArgumentError
  end

  @min_l_M 48
  @max_l_M 4_194_368

  unless @max_l_M == 65537 * @l_H do
    raise ArgumentError
  end

  def xor(a, b, acc \\ <<>>)
  def xor(<<>>, <<>>, acc), do: acc

  def xor(<<a, rest_a::binary>>, <<b, rest_b::binary>>, acc) do
    acc = acc <> <<bxor(a, b)>>
    xor(rest_a, rest_b, acc)
  end

  def instantiate(l_L, l_R) do
    h = fn i, u ->
      person = "UA_F4Jumble_H" <> <<i, 0, 0>>
      Blake2b.hash(u, <<>>, l_L, <<>>, person)
    end

    g = fn i, u ->
      inner = fn j ->
        person = "UA_F4Jumble_G" <> <<i>> <> i2leosp(16, j)
        Blake2b.hash(u, <<>>, @l_H, <<>>, person)
      end

      res = for j <- 0..ceil(l_R / @l_H), into: <<>>, do: inner.(j)

      :binary.part(res, 0, l_R)
    end

    # TODO cache in persistent term?
    {h, g}
  end

  def f4jumble(m) do
    l_M = byte_size(m)

    unless @min_l_M <= l_M and l_M <= @max_l_M do
      raise ArgumentError
    end

    l_L = min(@l_H, div(l_M, 2))
    l_R = l_M - l_L
    {h, g} = instantiate(l_L, l_R)

    a = :binary.part(m, 0, l_L)
    b = :binary.part(m, l_L, l_R)

    x = xor(b, g.(0, a))
    y = xor(a, h.(0, x))
    d = xor(x, g.(1, y))
    c = xor(y, h.(1, d))

    c <> d
  end

  def f4jumble_inv(m) do
    l_M = byte_size(m)

    unless @min_l_M <= l_M and l_M <= @max_l_M do
      raise ArgumentError
    end

    l_L = min(@l_H, div(l_M, 2))
    l_R = l_M - l_L
    {h, g} = instantiate(l_L, l_R)
    c = :binary.part(m, 0, l_L)
    d = :binary.part(m, l_L, l_R)

    y = xor(c, h.(1, d))
    x = xor(d, g.(1, y))
    a = xor(y, h.(0, x))
    b = xor(x, g.(0, a))

    a <> b
  end
end
