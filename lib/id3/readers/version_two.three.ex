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
				|> parse_frame(device, acc)
			_ -> {device, acc}
		end
	end

	defp parse_frame("TPE1", device, acc) do
		device
		|> get_text
		|> String.split("/")
		|> accumulate(:participants, device, acc)
		|> parse_frames
	end

	defp parse_frame("TXXX", device, acc) do
		device
		|> get_text
		|> String.split("\0")
		|> List.last
		|> accumulate(:show_notes, device, acc)
		|> parse_frames
	end

	defp parse_frame("WOAS", device, acc) do
		device
		|> get_text
		|> accumulate(:podcast_url, device, acc)
		|> parse_frames
	end

	defp parse_frame("TCON", device, acc) do
		device
		|> get_text
		|> accumulate(:genres, device, acc)
		|> parse_frames
	end

	defp parse_frame("TYER", device, acc) do
		device
		|> get_text
		|> String.to_integer
		|> accumulate(:year, device, acc)
		|> parse_frames
	end

	defp parse_frame("TRCK", device, acc) do
		device
		|> get_text
		|> String.to_integer
		|> accumulate(:number, device, acc)
		|> parse_frames
	end

	defp parse_frame("WOAF", device, acc) do
		device
		|> get_text
		|> accumulate(:url, device, acc)
		|> parse_frames
	end		 

	defp parse_frame("TIT2", device, acc) do
		device
		|> get_text
		|> accumulate(:title, device, acc)
		|> parse_frames
	end		 

	defp parse_frame("TIT3", device, acc) do
		device
		|> get_text
		|> accumulate(:summary, device, acc)
		|> parse_frames
	end		 

	defp parse_frame("TDAT", device, acc) do
		device
		|> get_text
		|> accumulate(:date, device, acc)
		|> parse_frames
	end		 

	defp parse_frame("TALB", device, acc) do
		device
		|> get_text
		|> accumulate(:podcast, device, acc)
		|> parse_frames
	end		 

	defp parse_frame("COMM", device, acc) do
		device
		|> get_text
		|> ignore(4)
		|> String.split("\0")
		|> List.last
		|> accumulate(:description, device, acc)
		|> parse_frames
	end

	defp parse_frame("UFID", device, acc) do
		device
		|> get_text
		|> String.split("\0")
		|> List.last
		|> accumulate(:uid, device, acc)
		|> parse_frames
	end

	defp parse_frame(_, device, acc) do
		device
		|> skip_frame(acc)
		|> parse_frames
	end

	defp ignore(s, n) do
		s
		|> String.slice(n, String.length(s))
	end

	defp skip_frame(device, acc) do
		<< size :: integer-size(32) >> = IO.binread(device, 4)
		IO.binread(device, 2 + size) # Throw away flags
		{device, acc}
	end

	defp accumulate(value, key, device, acc) do
		{device, Map.put(acc, key, value)}
	end

	defp get_text(device) do
		<< size :: integer-size(32) >> = IO.binread(device, 4)
		IO.binread(device, 2) # Throw away flags
		IO.binread(device, 1) # Throw away encoding

		device
		|> IO.binread(size - 1)
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
