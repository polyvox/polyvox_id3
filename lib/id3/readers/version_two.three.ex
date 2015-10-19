defmodule Polyvox.ID3.Readers.VersionTwoThree do
	@moduledoc false

	defstruct [:podcast, :summary, :title, :number, :participants, :year, :description, :show_notes, :genres, :artwork, :date, :url, :podcast_url, :uid, :s, :version, :size, :synced, :ext, :exp]

	def parse(%{path: path, caller: caller}) do
		File.open(path) |> parse_or_error(caller)
	end

	defp parse_or_error({:ok, device}, caller), do: device |> parse_tag |> send_to(caller) |> File.close
	defp parse_or_error(e, caller), do: e |> inform_error(caller)

	defp parse_tag(device) do
		{:ok, pos} = :file.position(device, :cur)
		acc = %__MODULE__{version: 2.3, s: pos}

		{device, acc}
		|> parse_header
		|> parse_frames
	end

	defp parse_header({device, _} = s) do
		s
		|> parse_header(IO.binread(device, 10))
	end

	defp parse_header({device, acc}, << ?I, ?D, ?3, 3, 0, sync :: size(1), ext :: size(1), exp :: size(1), 0 :: size(5),	size :: binary-size(4) >>) do
		{device, %__MODULE__{acc | size: unsync(size) + 10, synced: sync == 1, ext: ext == 1, exp: exp == 1}}
	end

	defp parse_header({device, _}, _) do
		{:stop, device}
	end

	defp parse_frames({:stop, device}) do
		{device, :notfound}
	end

	defp parse_frames({device, %__MODULE__{s: s, size: size} = acc}) do
		case :file.position(device, :cur) do
			{:ok, pos} when pos < s + size ->
				device
				|> IO.binread(4)
				|> parse_frame(device, acc)
			_ -> {device, acc}
		end
	end

	defp parse_frame(<< 0, 0, 0, 0 >>, device, acc) do
		{device, acc}
	end

	defp process_frame(device, acc, key),
		do: device |> process_frame(acc, key, &(&1))

	defp process_frame(device, acc, key, modifier),
		do: device |> process_frame(acc, key, modifier, 0)

	defp process_frame(device, acc, key, modifier, ignore) do
		device
		|> get_text(ignore: ignore)
		|> modifier.()
		|> accumulate(key, device, acc)
		|> parse_frames
	end
	
	defp parse_frame("WOAS", device, acc),
		do: device |> process_frame(acc, :podcast_url)

	defp parse_frame("TCON", device, acc),
		do: device |> process_frame(acc, :genres)

	defp parse_frame("WOAF", device, acc),
		do: device |> process_frame(acc, :url)

	defp parse_frame("TIT2", device, acc),
		do: device |> process_frame(acc, :title)

	defp parse_frame("TIT3", device, acc),
		do: device |> process_frame(acc, :summary)

	defp parse_frame("TDAT", device, acc),
		do: device |> process_frame(acc, :date)

	defp parse_frame("TALB", device, acc),
		do: device |> process_frame(acc, :podcast)

	defp parse_frame("TYER", device, acc),
		do: device |> process_frame(acc, :year, &String.to_integer/1)

	defp parse_frame("TRCK", device, acc),
		do: device |> process_frame(acc, :number, &String.to_integer/1)

	defp parse_frame("TPE1", device, acc),
		do: device |> process_frame(acc, :participants, &(String.split(&1, "/")))

	defp parse_frame("TXXX", device, acc),
		do: device |> process_frame(acc, :show_notes, &value_of_described_frame/1)

	defp parse_frame("UFID", device, acc),
		do: device |> process_frame(acc, :uid, &value_of_described_frame/1)

	defp parse_frame("COMM", device, acc),
		do: device |> process_frame(acc, :description, &value_of_described_frame/1, 4)

	defp parse_frame(_unknown_frame_id, device, acc) do
		device
		|> skip_frame(acc)
		|> parse_frames
	end

	defp value_of_described_frame(text) do
		text
		|> String.split("\0")
		|> List.last
	end

	defp skip_frame(device, acc) do
		<< size :: integer-size(32) >> = IO.binread(device, 4)
		IO.binread(device, 2 + size) # Throw away flags
		{device, acc}
	end

	defp accumulate(value, key, device, acc) do
		{device, Map.put(acc, key, value)}
	end

	defp get_text(device, opts \\ [ignore: 0]) do
		<< size :: integer-size(32) >> = IO.binread(device, 4)
		IO.binread(device, 2) # Throw away flags
		<< encoding >> = IO.binread(device, 1)
		IO.binread(device, opts[:ignore])

		device
		|> IO.binread(size - 1 - opts[:ignore])
		|> decode(encoding)
		|> trim_junk
	end

	defp decode(text, 0) do
		text
	end

	defp decode(<< 0xFF, 0xFE >> <> text, 1) do
		case :unicode.characters_to_binary(text, {:utf16, :little}, :utf8) do
			{:incomplete, encoded, _} -> encoded
			{:error, _, _} -> {:error, text}
			text -> text
		end
	end

	defp decode(<< 0xFE, 0xFF >> <> text, 1) do
		case :unicode.characters_to_binary(text, :utf16, :utf8) do
			{:incomplete, encoded, _} -> encoded
			{:error, _, _} -> {:error, text}
			text -> text
		end
	end

	defp unsync(value) do
		integer_size = bit_size(value)
		<< i :: integer-size(integer_size) >> = do_unsync(value)
		i
	end

	defp do_unsync(<< 0 :: size(1), x :: size(7) >> <> rest) do
		remaining_size = 7 * byte_size(rest)
		padding_size = byte_size(rest) + 1
		<< 0 :: size(padding_size), x :: size(7), unsync(rest) :: size(remaining_size) >>
	end

	defp do_unsync(<< >>) do
		<< >>
	end

	defp trim_junk(text) do
		text |> String.rstrip(?\0)
	end

	defp send_to({:stop, device}, caller) do
		send(caller, {:v2_3, :notfound})
		device
	end

	defp send_to({device, content}, caller) do
		send(caller, {:v2_3, content})
		device
	end

	defp inform_error({:error, reason}, caller) do
		send(caller, {:error, :v2_3, reason})
	end
end
