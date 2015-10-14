defmodule Polyvox.ID3.Readers.VersionOne do
	defstruct title: nil, artist: nil, album: nil, year: nil, comment: nil, track_num: nil, genre: nil, s: -1, e: -1

	def parse(%{path: path, caller: caller}) do
		File.open(path) |> parse_or_error(caller)
	end

	defp parse_or_error({:ok, device}, caller), do: device |> do_parse |> send_to(caller) |> File.close
	defp parse_or_error(e, caller), do: e |> inform_error(caller)

	defp do_parse(device) do
		{:ok, position} = :file.position(device, {:eof, -128})
		tag = device |> IO.binread(128) |> match_tag(position, position + 128)
		{device, tag}
	end

	defp match_tag(<< "TAG",
								    title     :: binary-size(30),
								 		artist    :: binary-size(30),
										album     :: binary-size(30),
										year      :: binary-size(4),
										comment   :: binary-size(28),
										0,
										track_num :: binary-size(1),
										genre     :: binary-size(1) >>,
								 start_position,
								 end_position) do
		map_to_struct(title, artist, album, year, comment, track_num, genre, start_position, end_position)
	end

	defp match_tag(<< "TAG",
								    title   :: binary-size(30),
								 		artist  :: binary-size(30),
										album   :: binary-size(30),
										year    :: binary-size(4),
										comment :: binary-size(30),
										genre   :: binary-size(1) >>,
								 start_position,
								 end_position) do
		map_to_struct(title, artist, album, year, comment, "0", genre, start_position, end_position)
	end

	defp map_to_struct(title, artist, album, year, comment, track_num, genre, start_position, end_position) do
		%__MODULE__{
			title: String.rstrip(title, 0),
			artist: String.rstrip(artist, 0),
			album: String.rstrip(album, 0),
			year: parse_integer(year),
			comment: String.rstrip(comment, 0),
			track_num: convert_integer(track_num),
			genre: convert_integer(genre),
			s: start_position,
			e: end_position
		}
	end

	defp parse_integer(s) do
		case Integer.parse(s) do
			{value, ""} -> value
			_ -> nil
		end
	end

	defp convert_integer(s), do: s |> String.to_char_list |> List.first

	defp send_to({device, content}, caller) do
		send(caller, {:v1, content})
		device
	end

	defp inform_error({:error, :enoent}, caller) do
		send(caller, {:error, :v1, :enoent})
	end
end
