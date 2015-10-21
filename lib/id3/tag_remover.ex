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

	def handle_call({:remove, to_path}, caller, from_path) do
		file_start = 0
		file_end = 0

		case Polyvox.ID3.Readers.VersionTwoThree.parse_header_only(from_path) do
			%{size: size} -> file_start = size
		end
		case Polyvox.ID3.Readers.VersionOne.parse_header_only(from_path) do
		  %{s: tag_start} -> file_end = tag_start
		end

		{:ok, device} = File.open(from_path, [:read])
		{:ok, _} = :file.position(device, {:bof, file_start})

		File.open(from_path, [:read])
		|> move(File.open(to_path, [:write]))
		|> between(file_start, file_end)
		|> close_files
	end

	defp move({:error, _} = e), do: {e, nil}
	defp move({:ok, from_device}, to_path), do: {File.open(to_path), from_device}

	defp between({{:error, reason}, from_device} = e, _, _), do: {:error, reason, from_device, nil}
	defp between({{:ok, to_device}, from_device}, fs, fe) do
		{:ok, _} = :file.position(from_device, {:bof, fs})

		case move(from_device, to_device, fs, fe) do
			{:error, reason} -> {:error, reason, from_device, to_device}
			_ -> {from_device, to_device}
		end
	end

	defp close_files({:error, reason, from_device, to_device}) do
		File.close(from_device)
		File.close(to_device)
		{:error, reason}
	end

	defp close_files({from_device, to_device}) do
		File.close(from_device)
		File.close(to_device)
		:ok
	end

	defp move(_, _, e, e) do
		:ok
	end
	
	defp move(from, to, s, e) do
		length = min(1024, e - s)
		case IO.binread(from, length) do
			{:error, _} = e -> e
			data ->
				IO.binwrite(to, data)
				move(from, to, s + length, e)
		end
	end
end
