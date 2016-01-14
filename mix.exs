defmodule Polyvox.ID3.Mixfile do
  use Mix.Project

  def project do
    [app: :polyvox_id3,
     version: "0.2.1",
     elixir: "~> 1.1",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps,
		 docs: docs,
		 description: description,
		 package: package]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger],
     mod: {Polyvox.ID3, []}]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:earmark, "~> 0.1", only: :dev},
		 {:ex_doc, "~> 0.10", only: :dev}]
  end

	defp docs do
		[extras: ["README.md"], main: "extra-readme"]
	end

	defp description do
		"""
		A podcast-centric ID3 library for parsing and writing ID3 tags.
		"""
	end

	defp package do
		[maintainers: ["Curtis Schlak <realistschuckle@gmail.com>"],
		 licenses: ["GPL-3.0"],
		 links: %{"GitHub" => "https://github.com/polyvox/polyvox_id3",
							"Docs" => "http://polyvox.github.io/polyvox_id3",
							"Sponsor" => "http://polyvox.fm"}]
	end
end
