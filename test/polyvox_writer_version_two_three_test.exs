defmodule Polyvox.ID3.Writers.VersionTwoThree.Test do
	use ExUnit.Case
	alias Polyvox.ID3.TagWriter

	@content "Fake-o MP3"

	setup do
		s = Stream.unfold(@content, &make_stream/1)
		{:ok, stream: s}
	end

	test "Empty version 2.3 tags has only polyvox.audio frame", meta do
		{:ok, writer} = TagWriter.start_link(meta[:stream])
		output = writer |> TagWriter.stream |> Enum.take(256_000_000) |> Enum.join("")

		### ID3 Tag Header
		assert("ID3" <> rest = output)                        # Header preamble
		assert(<< 3, 0, 0 >> <> rest = rest)                  # Version and flags
		assert(<< 51 :: integer-size(32) >> <> rest = rest)   # Size

		rest
		|> assert_text("TXXX", "Podcast platform of choice\0polyvox.audio")
		|> Kernel.===("")
		|> assert("Not what we wanted...")
		
		TagWriter.close(writer)
	end

	test "Version 2.3 tags with all settings", meta do
		{:ok, writer} = TagWriter.start_link(meta[:stream])
		output =
			writer
		|> TagWriter.summary("Our inaugural podcast")
		|> TagWriter.podcast("polyvox")
		|> TagWriter.title("Beefsteak Handshake")
		|> TagWriter.number(1)
		|> TagWriter.participants(["Bryan", "Heather", "Curtis"])
		|> TagWriter.year(2015)
		|> TagWriter.description("In our inaugural podcast, we start with the underhandedness of SourceForge and conclude with vending machines in public restrooms.")
		|> TagWriter.show_notes("What did we talk about?<ul><li>The recent underhandedness of SourceForge.net and how it relates to Pulp Fiction</li>\n<li>Bryan's new Apple Watch</li>\n<li>Starbuck's, banks, Amazon, and all of the other Big Brothers</li>\n<li>Blackpowder, gunpowder and shooting stuff</li>\n<li>Bryan's upcoming birthday</li>\n<li>Keanu Reeves and Shia LeBouf</li>\n<li>Using smartphones for their smart and not their phone</li>\n<li>Long-format writing</li>\n<li>Gonzo journalism</li>\n<li>Our first vinyl records, cassette tapes, and CDs</li>\n<li>\n<a href=\"http://www.youtube.com/watch?v=2pv4xmZF_EI\">Underdog</a></li>\n<li>The mysteries of mattresses and pillows</li>\n<li>Vending machines in public restrooms</li>\n<li>The <a href=\"https://en.wikipedia.org/wiki/Half_cent_(United_States_coin)\">Ha' penny</a></ul><p>And, a listener submitted photo!</p><p><img src=\"http://podcasts.polyvox.audio/media/0001/peccadillo.jpg\" class=\"poly-img\"></p>")
		|> TagWriter.genres([101])
		|> TagWriter.date("1706")
		|> TagWriter.url("http://polyvox.audio/podcasts/1.html")
		|> TagWriter.podcast_url("http://polyvox.audio")
		|> TagWriter.uid("2CA119D7-1A5D-4CBE-BE5D-06A001B53B52")
		|> TagWriter.stream
		|> Enum.take(256_000_000)
		|> Enum.join("")

		### ID3 Tag Header
		assert("ID3" <> rest = output)                  # Header preamble
		assert(<< 3, 0, 0 >> <> rest = rest)            # Version and flags
		<< size :: integer-size(32) >> <> rest = rest   # Size

		### ID3 Frames
		rest
		|> assert_text("TXXX", "Podcast platform of choice\0polyvox.audio")
		|> assert_text("TALB", "polyvox")
		|> assert_text("TIT2", "Beefsteak Handshake")
		|> assert_text("TRCK", "1")
		|> assert_text("TPE1", "Bryan/Heather/Curtis")
		|> assert_text("TYER", "2015")
		|> assert_text("TIT3", "Our inaugural podcast")
		|> assert_text("COMM", "\0\0\0\0In our inaugural podcast, we start with the underhandedness of SourceForge and conclude with vending machines in public restrooms.")
		|> assert_text("TXXX", "Show Notes\0What did we talk about?<ul><li>The recent underhandedness of SourceForge.net and how it relates to Pulp Fiction</li>\n<li>Bryan's new Apple Watch</li>\n<li>Starbuck's, banks, Amazon, and all of the other Big Brothers</li>\n<li>Blackpowder, gunpowder and shooting stuff</li>\n<li>Bryan's upcoming birthday</li>\n<li>Keanu Reeves and Shia LeBouf</li>\n<li>Using smartphones for their smart and not their phone</li>\n<li>Long-format writing</li>\n<li>Gonzo journalism</li>\n<li>Our first vinyl records, cassette tapes, and CDs</li>\n<li>\n<a href=\"http://www.youtube.com/watch?v=2pv4xmZF_EI\">Underdog</a></li>\n<li>The mysteries of mattresses and pillows</li>\n<li>Vending machines in public restrooms</li>\n<li>The <a href=\"https://en.wikipedia.org/wiki/Half_cent_(United_States_coin)\">Ha' penny</a></ul><p>And, a listener submitted photo!</p><p><img src=\"http://podcasts.polyvox.audio/media/0001/peccadillo.jpg\" class=\"poly-img\"></p>")
		|> Kernel.===("")
		|> assert("Not what we wanted...")

		TagWriter.close(writer)
	end

	defp assert_text(rest, key, value) do
		value_size = byte_size(value)

		<< k :: binary-size(4) >>  <> rest = rest
		<< size :: integer-size(32) >> <> rest = rest
		<< flags :: integer-size(16) >> <> rest = rest
		<< encoding >> <> rest = rest
		v = binary_part(rest, 0, value_size)
		rest = binary_part(rest, value_size, byte_size(rest) - value_size)
		
		assert(k == key)
		assert(size == byte_size(value) + 1)
		assert(flags == 0)
		assert(encoding == 1)
		assert(v == value)
		
		rest
	end

	defp make_stream(<< x >> <> rest) do
		{x, rest}
	end

	defp make_stream("") do
		nil
	end
end
