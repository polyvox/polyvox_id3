defmodule Polyvox.ID3.Readers.VersionOne do
	@moduledoc false
	
	defstruct [:title, :participants, :podcast, :year, :summary, :number, :genres, :s, :e, :size]

	def parse_header_only(path) do
		File.open(path)
		|> do_parse
		|> close_file
	end
	
	def parse(%{path: path, caller: caller}) do
		File.open(path) |> parse_or_error(caller)
	end

	defp close_file(nil), do: nil
	defp close_file({pid, struct}) do
		File.close(pid)
		struct
	end

	defp parse_or_error({:ok, device}, caller) do
		device
		|> do_parse
		|> send_to(caller)
		|> File.close
	end

	defp parse_or_error(e, caller) do
		e
		|> inform_error(caller)
	end

	defp do_parse({:error, _}), do: nil
	defp do_parse({:ok, device}), do: do_parse(device)
	defp do_parse(device) do
		case :file.position(device, {:eof, -128}) do
			{:ok, position} -> 
				tag = device |> IO.binread(128) |> match_tag(position, position + 128)
				{device, tag}
			e -> {device, e}
		end
	end

	defp match_tag(<< "TAG",
										title			:: binary-size(30),
										artist		:: binary-size(30),
										album			:: binary-size(30),
										year			:: binary-size(4),
										comment		:: binary-size(28),
										0,
										track_num :: binary-size(1),
										genre			:: binary-size(1) >>,
								 start_position,
								 end_position) do
		map_to_struct(title, artist, album, year, comment, track_num, genre, start_position, end_position)
	end

	defp match_tag(<< "TAG",
										title		:: binary-size(30),
										artist	:: binary-size(30),
										album		:: binary-size(30),
										year		:: binary-size(4),
										comment :: binary-size(30),
										genre		:: binary-size(1) >>,
								 start_position,
								 end_position) do
		map_to_struct(title, artist, album, year, comment, "0", genre, start_position, end_position)
	end

	defp match_tag(_, _, _) do
		:notfound
	end

	defp map_to_struct(title, artist, album, year, comment, track_num, genre, start_position, end_position) do
		%__MODULE__{
			title: String.rstrip(title, 0),
			participants: String.rstrip(artist, 0),
			podcast: String.rstrip(album, 0),
			year: parse_integer(year),
			summary: String.rstrip(comment, 0),
			number: convert_integer(track_num),
			genres: convert_integer(genre),
			s: start_position,
			e: end_position,
			size: 128
		}
	end

	defp parse_integer(s) do
		case Integer.parse(s) do
			{value, ""} -> value
			_ -> nil
		end
	end

	defp convert_integer(s), do: s |> String.to_char_list |> List.first

	defp send_to({device, {:error, reason}}, caller) do
		inform_error({:error, reason}, caller)
		device
	end
	
	defp send_to({device, content}, caller) do
		send(caller, {:v1, content})
		device
	end

	defp inform_error({:error, reason}, caller) do
		send(caller, {:error, :v1, reason})
	end
end
