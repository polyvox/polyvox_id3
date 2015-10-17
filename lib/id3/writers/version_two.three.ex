defmodule Polyvox.ID3.Writers.VersionTwoThree do
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
	end

	defp comments_frame(acc, nil), do: acc
	defp comments_frame(acc, value) do
		acc <> "COMM" <> << (byte_size(value) + 5) :: integer-size(32), 0, 0, 1, 0, 0, 0, 0 >> <> value
	end

	defp list_frame(acc, key, _, nil), do: acc |> text_frame(key, nil)
	defp list_frame(acc, key, delim, value) do
		acc |> text_frame(key, Enum.join(value, delim))
	end

	defp text_frame(acc, _, _, nil), do: acc
	defp text_frame(acc, key, description, value) do
		acc |> text_frame(key, description <> "\0" <> value)
	end

	defp text_frame(acc, _, nil), do: acc
		defp text_frame(acc, key, value) when is_binary(value) do
		acc <> key <> << (byte_size(value) + 1) :: integer-size(32), 0, 0, 1 >> <> value
	end

	defp text_frame(acc, key, value) do
		acc |> text_frame(key, to_string(value))
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
		i
	end
end
