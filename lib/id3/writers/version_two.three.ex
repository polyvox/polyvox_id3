defmodule Polyvox.ID3.Writers.VersionTwoThree do
	@moduledoc false
	
	def stream(state) do
		do_frames(state)
		|> add_header
		|> Enum.map(&to_stream/1)
		|> Stream.concat
	end

	defp add_header(frames) do
		["ID3" <> << 3, 0, 0, sync(byte_size(frames)) :: integer-size(32) >>,
		 frames]
	end

	defp do_frames(state) do
		""
		|> text_frame("TXXX", "Podcast platform of choice", "polyvox.audio")
		|> text_frame("TALB", Map.get(state, :podcast))
		|> text_frame("TIT2", Map.get(state, :title))
		|> text_frame("TRCK", Map.get(state, :number))
		|> list_frame("TPE1", "/", Map.get(state, :participants))
		|> text_frame("TYER", Map.get(state, :year))
		|> text_frame("TIT3", Map.get(state, :summary))
		|> comments_frame(Map.get(state, :description))
		|> text_frame("TXXX", "Show Notes", Map.get(state, :show_notes))
		|> list_frame("TCON", "(", ")", Map.get(state, :genres))
		|> text_frame("TDAT", Map.get(state, :date))
		|> url_frame("WOAF", Map.get(state, :url))
		|> url_frame("WOAS", Map.get(state, :podcast_url))
		|> id_frame(Map.get(state, :uid))
	end

	defp comments_frame(acc, nil), do: acc
	defp comments_frame(acc, value) do
		{size, encoding, value} = encode(value)
		acc <> "COMM" <> << (size + 5) :: integer-size(32), 0, 0, encoding, 0, 0, 0, 0 >> <> value
	end

	defp id_frame(acc, nil), do: acc
	defp id_frame(acc, value) do
		value = "http://polyvox.audio/guids\0" <> value
		acc <> "UFID" <> << byte_size(value) :: integer-size(32), 0, 0 >> <> value
	end

	defp list_frame(acc, key, _, nil), do: acc |> text_frame(key, nil)
	defp list_frame(acc, key, delim, value) do
		acc |> text_frame(key, Enum.join(value, delim))
	end

	defp list_frame(acc, _, _, _, nil), do: acc
	defp list_frame(acc, key, prefix, suffix, value) do
		value = prefix <> Enum.join(value, suffix <> prefix) <> suffix
		acc |> text_frame(key, value)
	end

	defp text_frame(acc, _, _, nil), do: acc
	defp text_frame(acc, key, description, value) do
		acc |> text_frame(key, description <> "\0" <> value)
	end

	defp text_frame(acc, _, nil), do: acc
	defp text_frame(acc, key, value) when is_binary(value) do
		{size, encoding, value} = encode(value)
		acc <> key <> << (size + 1) :: integer-size(32), 0, 0, encoding >> <> value
	end

	defp text_frame(acc, key, value) do
		acc |> text_frame(key, to_string(value))
	end

	defp url_frame(acc, _, nil), do: acc
	defp url_frame(acc, key, value) do
		acc <> key <> << byte_size(value) :: integer-size(32), 0, 0 >> <> value
	end

	defp encode(binary) do
		encode_on_size(binary, String.length(binary), byte_size(binary))
	end

	defp encode_on_size(binary, string_length, byte_length) when string_length == byte_length do
		{byte_length, 0, binary}
	end

	defp encode_on_size(binary, _, _) do
		binary = << 0xFF, 0xFE >> <> :unicode.characters_to_binary(binary, :utf8, {:utf16, :little})
		{byte_size(binary), 1, binary}
	end

	defp to_stream(text) do
		text |> Stream.unfold(&make_stream/1)
	end

	defp make_stream(<< x >> <> rest) do
		{<< x >>, rest}
	end

	defp make_stream("") do
		nil
	end

	defp sync(i) do
		use Bitwise
		l4 = i &&& 0x7F
		l3 = ((i <<< 1) &&& 0x7F00)
		l2 = ((i <<< 2) &&& 0x7F0000)
		l1 = ((i <<< 3) &&& 0x7F000000)
		l1 + l2 + l3 + l4
	end
end
