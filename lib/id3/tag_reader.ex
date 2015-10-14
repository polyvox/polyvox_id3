defmodule Polyvox.ID3.TagReader do
	use GenServer

	@moduledoc """
	Reads ID3 tags from a file.
	"""

	@doc """
	Starts a tag reader for the file at the specified path.
	"""
	@Spec start_link(binary) :: {:ok, pid} | {:error, term}
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
		case File.open(path) do
			{:ok, device} ->
				send(self, :parse)
				{:ok, {:unparsed, device}}
			e -> e
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

	def handle_info(:parse, {:unparsed, device}) do
		File.close(device)
		{:noreply, {:parsed, "It's all good!"}}
	end
end
