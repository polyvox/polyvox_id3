defmodule Polyvox.ID3.TagWriter do
	@moduledoc """
	Provides a way to write tags around a given stream.

  You should get a reference to a tag writer through the
	[`Polyvox.ID3.get_writer`](./Polyvox.ID3.html#get_writer/1) method.
	"""

	use GenServer

	defstruct [:file_stream, :summary, :podcast, :title, :number, :participants, :year, :description, :show_notes, :genres, :artwork, :date, :url, :podcast_url, :uid]

	@doc """
	A generic method for setting the value of the supplied `atom` for the
	writer.

  Supported atoms for this method are as follows:

  * `:artwork`
	* `:date`
	* `:description`
	* `:genres`
	* `:number`
	* `:participants`
	* `:podcast`
	* `:podcast_url`
	* `:show_notes`
	* `:summary`
	* `:title`
	* `:uid`
	* `:url`
	* `:year`

  For expected `values` associated with each of those atoms, see the
	corresponding method with the same name.
	"""
	@spec set(pid, atom, binary) :: pid
	def set(pid, atom, value) do
		GenServer.call(pid, {:set, atom, value})
	end

	@doc "Sets the content of the episode summary."
	@spec summary(pid, binary) :: pid
	def summary(pid, value) when is_binary(value) do
		set(pid, :summary, value)
	end

	@doc "Sets the value of the podcast name."
	@spec podcast(pid, binary) :: pid
	def podcast(pid, value) when is_binary(value) do
		set(pid, :podcast, value)
	end

	@doc "Sets the value of the episode title."
	@spec title(pid, binary) :: pid
	def title(pid, value) when is_binary(value) do
		set(pid, :title, value)
	end

	@doc "Sets the value of the episode number."
	@spec number(pid, integer) :: pid
	def number(pid, value) when is_integer(value) do
		set(pid, :number, value)
	end

	@doc "Sets the list of people that participated in the episode."
	@spec participants(pid, list(binary)) :: pid
	def participants(pid, value) when is_list(value) do
		set(pid, :participants, value)
	end

	@doc "Sets the year of the podcast recording."
	@spec year(pid, integer) :: pid
	def year(pid, value) when is_integer(value) do
		set(pid, :year, value)
	end

	@doc "Sets the description of the episode."
	@spec description(pid, binary) :: pid
	def description(pid, value) when is_binary(value) do
		set(pid, :description, value)
	end

	@doc "Sets the show notes for the episode."
	@spec show_notes(pid, binary) :: pid
	def show_notes(pid, value) when is_binary(value) do
		set(pid, :show_notes, value)
	end

	@doc "Sets the list of genres for the episode."
	@spec genres(pid, list(integer)) :: pid
	def genres(pid, value) when is_list(value) do
		set(pid, :genres, value)
	end

	@doc """
  Sets the embedded artwork for the episode.

  __Note: This is not yet implemented because it's not MVP.__
  """
	@spec artwork(pid, Stream.t) :: pid
	def artwork(pid, _) do
		pid
	end

	@doc "Sets the date or the recording (in expected DDMM) format for the episode."
	@spec date(pid, binary) :: pid
	def date(pid, value) when is_binary(value) do
		set(pid, :date, value)
	end

	@doc "Sets the URL where someone can find this episode."
	@spec url(pid, binary) :: pid
	def url(pid, value) when is_binary(value) do
		set(pid, :url, value)
	end

	@doc "Sets the URL for the podcast."
	@spec podcast_url(pid, binary) :: pid
	def podcast_url(pid, value) when is_binary(value) do
		set(pid, :podcast_url, value)
	end

	@doc "Sets the unique identifier for the episode."
	@spec uid(pid, binary) :: pid
	def uid(pid, value) when is_binary(value) do
		set(pid, :uid, value)
	end

	@doc """
	Gets a stream that will write the tags around the originally supplied
	stream. By default, the writer will write both version 1 and 2.3 tags.

  By setting `v1: true`, the writer will write version 1 tags.
  By setting `v2_3: true`, the writer will write version 2 tags.
  """
	@spec stream(pid, Keyword.t) :: pid
	def stream(pid, opts \\ [v1: true, v2_3: true]) do
		GenServer.call(pid, {:stream, opts})
	end

	@doc """
	Closes the writer and stops the process.

  Use [`Polyvox.ID3.get_writer/1`](./Polyvox.ID3.html#get_writer/1)
	to get a tag reader.
	"""
	@spec close(pid) :: :ok
	def close(pid) do
		GenServer.cast(pid, :close)
	end

	@doc false
	@spec start_link(Stream.t) :: {:ok, pid} | {:error, term}
	def start_link(stream) do
		GenServer.start_link(__MODULE__, stream)
	end

	def init(stream) do
		{:ok, %__MODULE__{file_stream: stream}}
	end

	def handle_call({:set, atom, value}, _, state) do
		{:reply, self, Map.put(state, atom, value)}
	end

	def handle_call({:stream, opts}, _, state) do
		opts = opts || []
		{:reply, stream_for_tags(state, opts), state}
	end

	def handle_cast(:close, state) do
		{:stop, :normal, state}
	end

	defp stream_for_tags(state, opts) do
		streams = []
		if opts[:v1] do
			streams = [Polyvox.ID3.Writers.VersionOne.stream(state)]
		end
		streams = [state.file_stream | streams]
		if opts[:v2_3] do
			streams = [Polyvox.ID3.Writers.VersionTwoThree.stream(state) | streams]
		end

		streams |> Stream.concat
	end
end
