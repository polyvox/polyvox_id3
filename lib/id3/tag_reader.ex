defmodule Polyvox.ID3.TagReader do
	use GenServer

	defstruct v1: nil

	@moduledoc """
	Reads ID3 tags from a file.
	"""

	@doc """
	Starts a tag reader for the file at the specified path.
	"""
	@spec start_link(binary) :: {:ok, pid} | {:error, term}
	def start_link(path) do
		GenServer.start_link(__MODULE__, path)
	end

	@doc """
	Gets the tags read from the file.
	"""
	@spec tag(pid) :: list(Polyvox.ID3.Tag.t) | :notready
	def tag(tag_reader) do
		GenServer.call(tag_reader, :tag)
	end

	@doc """
	Closes the provided tag reader.
	"""
	@spec close(pid) :: :ok
	def close(tag_reader) do
		GenServer.cast(tag_reader, :close)
	end

	def init(path) do
		case File.exists?(path) do
			true ->
				run_task(Polyvox.ID3.Readers.VersionOne, path)
				{:ok, {:unparsed, %Polyvox.ID3.TagReader{}}}
			_ ->
				{:stop, :enoent}
		end
	end

	def handle_call(:tag, _, {:unparsed, _} = s) do
		{:reply, :notready, s}
	end

	def handle_call(:tag, _, {:parsed, tags} = s) do
		{:reply, tags, s}
	end

	def handle_cast(:close, state) do
		{:stop, :normal, state}
	end

	def handle_info({:error, :v1, :einval}, {_, struct}) do
		{:noreply, {:parsed, %Polyvox.ID3.TagReader{struct | v1: :notfound}}}
	end

	def handle_info({:error, :v1, reason}, state) do
		{:stop, {:error, reason}, state}
	end

	def handle_info({:v1, tag}, {_, struct}) do
		{:noreply, {:parsed, %Polyvox.ID3.TagReader{struct | v1: tag}}}
	end
	
	defp run_task(module, path) do
		Task.start(module, :parse, [%{path: path, caller: self}])
	end
end
