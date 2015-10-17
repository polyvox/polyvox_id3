defmodule Polyvox.Writer.VersionOne.Test do
  use ExUnit.Case
	alias Polyvox.ID3.TagWriter

	@content "Fake-o MP3"

	setup do
		s = Stream.unfold(@content, &make_stream/1)
		{:ok, stream: s}
	end

	test "version 1 writer with no values emits 125 0 bytes", meta do
		{:ok, writer} = TagWriter.start_link(meta[:stream])
		length = byte_size(@content)
		expected_length = 128 + length

		output = writer |> TagWriter.stream(v1: true) |> Enum.take(expected_length) |> to_string

		@content <> rest = output
		"TAG" <> rest = rest
		<< 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 >> <> rest = rest
		<< 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 >> <> rest = rest
		<< 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 >> <> rest = rest
		"0000" <> rest = rest
		<< 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 >> <> rest = rest
		<< 0 >> <> rest = rest
		<< 0 >> <> rest = rest
		<< 101 >> = rest
		
		TagWriter.close(writer)
	end

	test "version 1 writer with normal values emits", meta do
		{:ok, writer} = TagWriter.start_link(meta[:stream])
		length = byte_size(@content)
		expected_length = 128 + length

		output =
			writer
		|> TagWriter.podcast("polyvox")
		|> TagWriter.title("test podcast")
		|> TagWriter.number(4)
		|> TagWriter.participants(["Bryan", "Heather", "Curtis"])
		|> TagWriter.year(2013)
		|> TagWriter.summary("This is really really really great.")
		|> TagWriter.description("This is really really really really really great.")
		|> TagWriter.show_notes("Here are some show notes that you can read while making bodily waste.")
		|> TagWriter.genres([101])
		|> TagWriter.date("2801")
		|> TagWriter.url("http://polyvox.audio")
		|> TagWriter.podcast_url("http://polyvox.audio/1")
		|> TagWriter.stream(v1: true)
		|> Enum.take(expected_length + 1)
		|> to_string

		@content <> rest = output
		"TAG" <> rest = rest
		"test podcast" <> << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 >> <> rest = rest
		"Bryan, Heather, Curtis" <> << 0, 0, 0, 0, 0, 0, 0, 0 >> <> rest = rest
		"polyvox" <> << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 >> <> rest = rest
		"2013" <> rest = rest
		"This is really really really" <> rest = rest
		<< 0 >> <> rest = rest
		<< 4 >> <> rest = rest
		<< 101 >> = rest
		
		TagWriter.close(writer)
	end

	defp make_stream(<< x >> <> rest) do
		{x, rest}
	end

	defp make_stream("") do
		nil
	end
end
