defmodule ZcashAddress.MixProject do
  use Mix.Project

  def project do
    [
      app: :zcash_address,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:blake2_elixir, "~> 0.8"}
      # https://github.com/riverrun/blake2_elixir/pull/2
      {:blake2_elixir, github: "josevalim/blake2_elixir", branch: "patch-1"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
