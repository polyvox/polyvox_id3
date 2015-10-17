defmodule Polyvox.Writer.Test do
  use ExUnit.Case
	alias Polyvox.ID3.TagWriter

	setup do
		content = "Fake-o MP3"
		s = Stream.unfold(content, &make_stream/1)
		{:ok, stream: s, length: byte_size(content)}
	end

	test "version 1 writer with no values emits 125 0 bytes", meta do
		{:ok, writer} = TagWriter.start_link(meta[:stream])
		length = meta[:length]
		expected_length = 128 + meta[:length]

		output = writer |> TagWriter.stream |> Enum.take(expected_length) |> to_string

		<< _ :: binary-size(length), ?T, ?A, ?G >> <> rest = output
		TagWriter.close(writer)
	end

	test "version 1 writer with normal values emits", meta do
		{:ok, writer} = TagWriter.start_link(meta[:stream])
		length = meta[:length]
		expected_length = 128 + meta[:length]

		output =
			writer
		|> TagWriter.podcast("polyvox")
		|> TagWriter.title("test podcast")
		|> TagWriter.number(4)
		|> TagWriter.participants(["Byran", "Heather", "Curtis"])
		|> TagWriter.year(2013)
		|> TagWriter.description("This is really really really really really great.")
		|> TagWriter.show_notes("Here are some show notes that you can read while making bodily waste.")
		|> TagWriter.genres([101])
		|> TagWriter.date("2801")
		|> TagWriter.url("http://polyvox.audio")
		|> TagWriter.podcast_url("http://polyvox.audio/1")
		|> TagWriter.stream
		|> Enum.take(expected_length)
		|> to_string

		<< _ :: binary-size(length), ?T, ?A, ?G >> <> rest = output
		TagWriter.close(writer)
	end

	defp make_stream(<< x >> <> rest) do
		{x, rest}
	end

	defp make_stream("") do
		nil
	end
end
