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
		assert(%{size: 128} = tag)

		reader |> Polyvox.ID3.TagReader.close
	end

	test "can read version 2.3 tag" do
		{:ok, reader} = System.cwd |> Path.join("test/test.v2.3") |> Polyvox.ID3.get_reader

		%{v2: tag} = reader |> get_tag

		assert(%{s: 0} = tag)
		assert(%{size: 469} = tag)
		assert(%{participants: ["Bryan", "Heather", "Curtis"]} = tag)
		assert(%{podcast_url: "http://awesome.audio"} = tag)
		assert(%{podcast: "World's Best Podcast!"} = tag)
		assert(%{summary: "Inaugural Awesome Podcast!"} = tag)
 		assert(%{description: "The first episode of the world's best podcast brought to you by the letter N."} = tag)
		assert(%{url: "http://awesome.audio/1"} = tag)
		assert(%{genres: "Speech"} = tag)
		assert(%{year: 2013} = tag)
		assert(%{title: "World's Best First Podcast!"} = tag)
		assert(%{uid: "2CA119D7-1A5D-4CBE-BE5D-06A001B53B52"} = tag)
		assert(%{show_notes: "<h1>WORLD'S BEST!</h1>"} = tag)
		assert(%{date: "0603"} = tag)
		assert(%{number: 1} = tag)
		
		reader |> Polyvox.ID3.TagReader.close
	end
	
	defp get_tag(reader), do: get_tag(reader, :notready)
	defp get_tag(reader, :notready) do
		tag = reader |> Polyvox.ID3.TagReader.tag
		reader |> get_tag(tag)
	end
	defp get_tag(_, tag), do: tag
end
