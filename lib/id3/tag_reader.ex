defmodule Polyvox.ID3.TagReader do
	use GenServer

	defstruct [:v1, :v2]

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

	def handle_info({:v1, tag}, {_, %{v2: nil} = struct}) do
		{:noreply, {:unparsed, %__MODULE__{struct | v1: tag}}}
	end
	
	def handle_info({:v1, tag}, {_, struct}) do
		{:noreply, {:parsed, %__MODULE__{struct | v1: tag}}}
	end
	
	def handle_info({:v2, tag}, {_, %{v1: nil} = struct}) do
		{:noreply, {:unparsed, %__MODULE__{struct | v2: tag}}}
	end
	
	def handle_info({:v2, tag}, {_, struct}) do
		{:noreply, {:parsed, %__MODULE__{struct | v2: tag}}}
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

		defp get(%{v2: v2, v1: v1}, atom) do
			get_prop(v2, atom) || get_prop(v1, atom) || :notfound
		end

		defp get_prop(nil, _), do: nil
		defp get_prop(map, atom), do: map |> Map.get(atom)
	end
end
