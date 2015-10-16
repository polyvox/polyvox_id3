defmodule Polyvox.ID3.Readers.VersionTwoThree do
	defstruct [:podcast, :title, :number, :participants, :year, :description, :show_notes, :genres, :artwork, :date, :url, :podcast_url, :uid, :s, :version, :size, :synced, :ext, :exp]

	def parse(%{path: path, caller: caller}) do
		File.open(path) |> parse_or_error(caller)
	end

	defp parse_or_error({:ok, device}, caller), do: device |> do_parse |> send_to(caller) |> File.close
	defp parse_or_error(e, caller), do: e |> inform_error(caller)

	defp do_parse(device) do
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

	defp parse_header({device, acc}, << ?I, ?D, ?3, 3, 0, sync :: size(1), ext :: size(1), exp :: size(1), 0 :: size(5),  size :: binary-size(4) >>) do
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
				|> parse_frames(device, acc)
			_ -> {device, acc}
		end
	end

	defp parse_frames("TPE1", device, acc) do
		device
		|> get_text
		|> String.split("/")
		|> merge(:participants, device, acc)
		|> parse_frames
	end

	defp parse_frames("TXXX", device, acc) do
		device
		|> get_text
		|> String.split("\0")
		|> List.last
		|> merge(:show_notes, device, acc)
		|> parse_frames
	end

	defp parse_frames("WOAS", device, acc) do
		device
		|> get_text
		|> merge(:podcast_url, device, acc)
		|> parse_frames
	end

	defp parse_frames("TCON", device, acc) do
		device
		|> get_text
		|> merge(:genres, device, acc)
		|> parse_frames
	end

	defp parse_frames("TYER", device, acc) do
		device
		|> get_text
		|> String.to_integer
		|> merge(:year, device, acc)
		|> parse_frames
	end

	defp parse_frames("TRCK", device, acc) do
		device
		|> get_text
		|> String.to_integer
		|> merge(:number, device, acc)
		|> parse_frames
	end

	defp parse_frames("WOAF", device, acc) do
		device
		|> get_text
		|> merge(:url, device, acc)
		|> parse_frames
	end		 

	defp parse_frames("TIT2", device, acc) do
		device
		|> get_text
		|> merge(:title, device, acc)
		|> parse_frames
	end		 

	defp parse_frames("TIT3", device, acc) do
		device
		|> get_text
		|> merge(:summary, device, acc)
		|> parse_frames
	end		 

	defp parse_frames("TDAT", device, acc) do
		device
		|> get_text
		|> merge(:date, device, acc)
		|> parse_frames
	end		 

	defp parse_frames("TALB", device, acc) do
		device
		|> get_text
		|> merge(:podcast, device, acc)
		|> parse_frames
	end		 

	defp parse_frames("COMM", device, acc) do
		device
		|> get_text
		|> ignore(4)
		|> String.split("\0")
		|> List.last
		|> merge(:description, device, acc)
		|> parse_frames
	end

	defp parse_frames("UFID", device, acc) do
		device
		|> get_text
		|> String.split("\0")
		|> List.last
		|> merge(:uid, device, acc)
		|> parse_frames
	end

	defp parse_frames(_, device, acc) do
		device
		|> skip_tag(acc)
		|> parse_frames
	end

	defp ignore(s, n) do
		s
		|> String.slice(n, String.length(s))
	end

	defp skip_tag(device, acc) do
		<< size :: integer-size(32) >> = IO.binread(device, 4)
		IO.binread(device, 2 + size) # Throw away flags
		{device, acc}
	end

	defp merge(value, key, device, acc) do
		{device, Map.put(acc, key, value)}
	end

	defp get_text(device) do
		<< size :: integer-size(32) >> = IO.binread(device, 4)
		IO.binread(device, 2) # Throw away flags
		<< encoding :: integer >> = IO.binread(device, 1)

		device
		|> IO.binread(size - 1)
		|> decode(encoding)
	end

	defp decode(string, 0) do
		string
	end

	defp unsync(value) do
		integer_size = bit_size(value)
		<< i :: integer-size(integer_size) >> = do_unsync(value)
		i
	end

	defp do_unsync(<< 0 :: size(1), x :: size(7), rest :: binary >>) do
		remaining_size = 7 * byte_size(rest)
		padding_size = byte_size(rest) + 1
		<< 0 :: size(padding_size), x :: size(7), unsync(rest) :: size(remaining_size) >>
	end

	defp do_unsync(<< >>) do
		<< >>
	end

	defp send_to({:stop, device}, caller) do
		send(caller, {:v2, :notfound})
		device
	end

	defp send_to({device, content}, caller) do
		send(caller, {:v2, content})
		device
	end

	defp inform_error({:error, :enoent}, caller) do
		send(caller, {:error, :v2, :enoent})
	end
end
