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
		file_start = nil
		file_end = nil

		case Polyvox.ID3.Readers.VersionTwoThree.parse_header_only(from_path) do
			%{size: size} -> file_start = size
			_ -> file_start = 0
		end
		case Polyvox.ID3.Readers.VersionOne.parse_header_only(from_path) do
		  %{s: tag_start} -> file_end = tag_start
			_ -> file_end = nil
		end

		{:ok, device} = File.open(from_path, [:read])
		{:ok, _} = :file.position(device, {:bof, file_start})

		File.open(from_path, [:read])
		|> move(File.open(to_path, [:write]))
		|> between(file_start, file_end)
		|> close_files
		|> package_reply
	end

	defp move({:ok, from_device}, {:ok, to_device}), do: {from_device, to_device, nil}
	defp move({:ok, from_device}, {:error, reason}), do: {from_device, nil, reason}
	defp move({:error, reason}, {:ok, to_device}),   do: {nil, to_device, reason}
	defp move({:error, reason}, {:error, _}),        do: {nil, nil, reason}

	defp between({nil, nil, reason}, _, _), do: {:error, reason, nil, nil}
	defp between({ fd, nil, reason}, _, _), do: {:error, reason, fd, nil}
	defp between({nil,  td, reason}, _, _), do: {:error, reason, nil, td}
	defp between({fd, td, _}, fs, fe) do
		{:ok, _} = :file.position(fd, {:bof, fs})

		case move(fd, td, fs, fe) do
			{:error, reason} -> {:error, reason, td, fd}
			_ -> {fd, td}
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

	defp move(from, to, e, e) do
		{from, to}
	end
	
	defp move(from, to, s, e) do
		e = e || s + 1025
		length = min(1024, e - s)
		case IO.binread(from, length) do
			{:error, _} = e -> e
			:eof ->
				{from, to}
			data ->
				IO.binwrite(to, data)
				move(from, to, s + length, e)
		end
	end

	def package_reply(:ok) do
		{:stop, :normal, :ok, nil}
	end

	def package_reply({:error, reason}) do
		{:stop, reason, nil, nil}
	end
end
