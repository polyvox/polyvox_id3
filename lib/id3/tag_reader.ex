defmodule Polyvox.ID3.TagReader do
	@moduledoc """
	Reads ID3 tags from a file.

  You should get a reference to a tag reader through the
  [`Polyvox.ID3.get_reader`](./Polyvox.ID3.html#get_reader/1)
  method.
	"""

	use GenServer

	defstruct [:v1, :v2_3]

	@doc false
	@spec start_link(binary) :: {:ok, pid} | {:error, term}
	def start_link(path) do
		GenServer.start_link(__MODULE__, path)
	end

	@doc """
	Gets a [`Polyvox.ID3.Tag`](./Polyvox.ID3.Tag.html) read
  from the file that provides information from
  higher-versioned ID3 tags before delegating to
	lower-versioned ID3 tags.

  For example, lets say an MP3 file has both the TRCK
	frame in a version 2.3 tag and the track byte in a
	version 1 tag set. The `Polyvox.ID3.Tag` returned by
	this method will give the information found in the
	version 2.3 tag.

  In another example, if an MP3 file had both version 1
  and version 2.3 tags. Now, assume that the version 2.3
	tag did not have a TYER frame to indicate the year of
	the recording. Then, the return value of this method
	will defer to the version 1 tag and return that year
	value.
	"""
	@spec tag(pid) :: Polyvox.ID3.Tag.t | :notready
	def tag(tag_reader) do
		GenServer.call(tag_reader, :tag)
	end

	@doc """
	Closes the provided tag reader.

  Use [`Polyvox.ID3.get_reader/1`](./Polyvox.ID3.html#get_reader/1)
	to get a tag reader.
	"""
	@spec close(pid) :: :ok
	def close(tag_reader) do
		GenServer.cast(tag_reader, :close)
	end

	def init(path) do
		case File.exists?(path) do
			true ->
				run_task(Polyvox.ID3.Readers.VersionOne, path)
				run_task(Polyvox.ID3.Readers.VersionTwoThree, path)
				{:ok, {:unparsed, %Polyvox.ID3.TagReader{}}}
			_ ->
				{:stop, :enoent}
		end
	end

	def handle_call(:tag, _, {:unparsed, _} = s) do
		{:reply, :notready, s}
	end

	def handle_call(:tag, _, {:parsed, struct} = s) do
		{:reply, struct, s}
	end

	def handle_cast(:close, state) do
		{:stop, :normal, state}
	end

	def handle_info({:error, :v1, :einval}, {_, struct}) do
		{:noreply, {:parsed, %__MODULE__{struct | v1: :notfound}}}
	end

	def handle_info({:error, :v1, reason}, state) do
		{:stop, {:error, reason}, state}
	end

	def handle_info({:error, :v2_3, :einval}, {_, struct}) do
		{:noreply, {:parsed, %__MODULE__{struct | v2_3: :notfound}}}
	end

	def handle_info({:error, :v2_3, reason}, state) do
		{:stop, {:error, reason}, state}
	end

	def handle_info({:v1, tag}, {_, %{v2_3: nil} = struct}) do
		{:noreply, {:unparsed, %__MODULE__{struct | v1: tag}}}
	end
	
	def handle_info({:v1, tag}, {_, struct}) do
		{:noreply, {:parsed, %__MODULE__{struct | v1: tag}}}
	end
	
	def handle_info({:v2_3, tag}, {_, %{v1: nil} = struct}) do
		{:noreply, {:unparsed, %__MODULE__{struct | v2_3: tag}}}
	end
	
	def handle_info({:v2_3, tag}, {_, struct}) do
		{:noreply, {:parsed, %__MODULE__{struct | v2_3: tag}}}
	end
	
	defp run_task(module, path) do
		Task.start(module, :parse, [%{path: path, caller: self}])
	end

	defimpl Polyvox.ID3.Tag do
		def podcast(tag), do: tag |> get(:podcast)
		
		def title(tag), do: tag |> get(:title)
		
		def number(tag), do: tag |> get(:number)
		
		def participants(tag), do: tag |> get(:participants)
		
		def year(tag), do: tag |> get(:year)
		
		def summary(tag), do: tag |> get(:summary)
		
		def description(tag), do: tag |> get(:description)
		
		def show_notes(tag), do: tag |> get(:show_notes)
		
		def genres(tag), do: tag |> get(:genres)
		
		def artwork(tag), do: tag |> get(:artwork)
		
		def date(tag), do: tag |> get(:date)
		
		def url(tag), do: tag |> get(:url)
		
		def podcast_url(tag), do: tag |> get(:podcast_url)
		
		def uid(tag), do: tag |> get(:uid)

		defp get(%{v2_3: v2_3, v1: v1}, atom) do
			get_prop(v2_3, atom) || get_prop(v1, atom) || :notfound
		end

		defp get_prop(nil, _), do: nil
		defp get_prop(map, atom), do: map |> Map.get(atom)
	end
end
