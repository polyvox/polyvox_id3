defmodule Polyvox.ID3.TagRemover do
	use GenServer

	def remove(pid, to_path) do
		GenServer.call(pid, {:remove, to_path})
	end

	def start_link(from_path) do
		GenServer.start_link(__MODULE__, from_path)
	end

	def init(from_path) do
		{:ok, from_path}
	end

	def handle_call({:remove, to_path}, _, from_path) do
		case Polyvox.ID3.Readers.VersionTwoThree.parse_header_only(from_path) do
			%{size: size} -> file_start = size
			_ -> file_start = 0
		end
		case Polyvox.ID3.Readers.VersionOne.parse_header_only(from_path) do
			%{s: tag_start} -> file_end = tag_start
			_ -> file_end = :eof
		end

		file_start
		|> file_contents_until(file_end)
		|> move_contents_of(from_path)
		|> to_destination(to_path)
		|> report_success
	end

	defp file_contents_until(fs, fe),
		do: {fs, fe}

	defp move_contents_of({fs, fe}, from_path),
		do: {fs, fe, from_path}

	defp to_destination({0, :eof, from_path}, to_path) do
		File.rename(from_path, to_path)
	end

	defp to_destination({fs, :eof, from_path}, to_path) do
		case File.stat(from_path) do
			{:ok, stat} -> to_destination({fs, stat.size, from_path}, to_path)
			e -> e
		end
	end
	
	defp to_destination({fs, fe, from_path}, to_path) do
		try do
			File.stream!(from_path, [], 1)
			|> Stream.take(fe)
			|> Stream.drop(fs)
			|> Stream.into(File.stream!(to_path))
			|> Stream.run
		rescue
			e in File.Error -> {:error, e.reason}
		end
	end
	
	defp report_success(a) do
		{:stop, :normal, a, nil}
	end
end
