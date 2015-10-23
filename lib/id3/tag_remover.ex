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
			_ -> file_start = nil
		end
		case Polyvox.ID3.Readers.VersionOne.parse_header_only(from_path) do
		  %{s: tag_start} -> file_end = tag_start
			_ -> file_end = nil
		end

		from_status = File.open(from_path, [:read]) do

		from_status
		|> bytes_between(file_start, file_end)
		|> move(to_path)
		|> close_files
		|> package_reply
	end

	defp bytes_between({:error, reason}, _, _), do: {:error, reason}
	defp bytes_between({:ok, pid}, fs, fe) do
		fs = fs || 0
		{pid, fs, fe}
	end

	defp move({:error, reason}, _), do: {:error, reason}
	defp move({from_pid, fs, fe}, to_path) do
		{:ok, to_pid} = File.open(to_path, [:write])

		
		
		{from_pid, to_pid}
	end

	defp close_files({:error, reason}) do
		{:error, reason}
	end

	defp close_files({from_pid, to_pid}) do
		File.close(from_pid)
		File.close(to_pid)
		:ok
	end
	
	defp package_reply(:ok) do
		{:stop, :normal, :ok, nil}
	end

	defp package_reply({:error, reason}) do
		{:stop, :normal, {:error, reason}, nil}
	end
end
