defmodule Polyvox.ID3Test do
  use ExUnit.Case
  doctest Polyvox.ID3

	test "can read version 1 tag" do
		{:ok, reader} = System.cwd |> Path.join("test/test.v1") |> Polyvox.ID3.get_reader

		%{v1: tag} = reader |> get_tag

		assert(%{comment: "Comment"} = tag)
		assert(%{artist: "Artist"} = tag)
		assert(%{album: "Album"} = tag)
		assert(%{title: "Title"} = tag)
		assert(%{year: 2012} = tag)
		assert(%{genre: 101} = tag)
		assert(%{track_num: 112} = tag)

		reader |> Polyvox.ID3.TagReader.close
	end

	defp get_tag(reader), do: get_tag(reader, :notready)
	defp get_tag(reader, :notready) do
		tag = reader |> Polyvox.ID3.TagReader.tag
		reader |> get_tag(tag)
	end
	defp get_tag(reader, tag), do: tag
end
