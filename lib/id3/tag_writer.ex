defmodule Polyvox.ID3.TagWriter do
	use GenServer
	
	defstruct [:file_stream, :podcast, :title, :number, :participants, :year, :description, :show_notes, :genres, :artwork, :date, :url, :podcast_url]

	def set(pid, atom, value) do
		GenServer.call(pid, {:set, atom, value})
	end
	
	def podcast(pid, value) when is_binary(value) do
		set(pid, :podcast, value)
	end

	def title(pid, value) when is_binary(value) do
		set(pid, :title, value)
	end

	def number(pid, value) when is_integer(value) do
		set(pid, :number, value)
	end

	def participants(pid, value) when is_list(value) do
		set(pid, :participants, value)
	end

	def year(pid, value) when is_integer(value) do
		set(pid, :year, value)
	end

	def description(pid, value) when is_binary(value) do
		set(pid, :description, value)
	end

	def show_notes(pid, value) when is_binary(value) do
		set(pid, :show_notes, value)
	end

	def genres(pid, value) when is_list(value) do
		set(pid, :genres, value)
	end

	def artwork(pid, value) do
		set(pid, :artwork, value)
	end

	def date(pid, value) do
		set(pid, :date, value)
	end

	def url(pid, value) when is_binary(value) do
		set(pid, :url, value)
	end

	def podcast_url(pid, value) when is_binary(value) do
		set(pid, :podcast_url, value)
	end

	def stream(pid) do
		GenServer.call(pid, :stream)
	end

	def close(pid) do
		GenServer.cast(pid, :close)
	end

	def start_link(stream) do
		GenServer.start_link(__MODULE__, stream)
	end

	def init(stream) do
		{:ok, %__MODULE__{file_stream: stream}}
	end

	def handle_call({:set, atom, value}, _, state) do
		{:reply, self, Map.put(state, atom, value)}
	end

	def handle_call(:stream, _, state) do
		{:reply, stream_for_tags(state), state}
	end

	def handle_cast(:close, state) do
		{:stop, :normal, state}
	end

	defp stream_for_tags(state) do
		[#Polyvox.ID3.Writers.VersionTwoThree.stream(state),
		 state.file_stream,
		 Polyvox.ID3.Writers.VersionOne.stream(state)]
		|> Stream.concat
	end
end
