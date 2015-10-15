defmodule Polyvox.ID3Test do
  use ExUnit.Case
  doctest Polyvox.ID3

	test "fails on unknown file" do
		{:error, :enoent} = System.cwd |> Path.join("test/does/not/exist") |> Polyvox.ID3.get_reader
	end

	test "returns :notfound for file without tag" do
		{:ok, reader} = System.cwd |> Path.join("mix.lock") |> Polyvox.ID3.get_reader

		assert(%{v1: :notfound} = reader |> get_tag)

		reader |> Polyvox.ID3.TagReader.close
	end

	test "can read version 1 tag" do
		{:ok, reader} = System.cwd |> Path.join("test/test.v1") |> Polyvox.ID3.get_reader

		%{v1: tag} = reader |> get_tag

		assert(%{summary: "Comment"} = tag)
		assert(%{participants: "Artist"} = tag)
		assert(%{podcast: "Album"} = tag)
		assert(%{title: "Title"} = tag)
		assert(%{year: 2012} = tag)
		assert(%{genres: 101} = tag)
		assert(%{number: 112} = tag)
		assert(%{s: 325} = tag)
		assert(%{e: 453} = tag)

		reader |> Polyvox.ID3.TagReader.close
	end

	defp get_tag(reader), do: get_tag(reader, :notready)
	defp get_tag(reader, :notready) do
		tag = reader |> Polyvox.ID3.TagReader.tag
		reader |> get_tag(tag)
	end
	defp get_tag(reader, tag), do: tag
end
