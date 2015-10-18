defmodule Polyvox.ID3 do
	@moduledoc """
	A library for reading and writing ID3 tags from and to a file.
	"""

  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_, _) do
		Polyvox.ID3.TagInteractionSupervisor.start_link
  end

	@doc """
	Gets the pid of a `TagReader` to read the ID3 tags found in
	the file located at path.
	"""
	@spec get_reader(binary) :: {:ok, pid} | {:error, term}
	def get_reader(path) do
		Polyvox.ID3.TagReaderSupervisor.get_reader(path)
	end

	@doc """
	Gets the pid of the `TagWriter` to create a stream that
	prepends and appends ID3 tags to another stream.

  A tag writer takes a stream which is the raw MP3 file. Then,
  by adding data to the writer, you can get a stream to write
  that will place tags in the proper position within the output.

  ## Example Usage

			alias Polyvox.ID3.TagWriter
			mp3_in_stream = File.stream!("raw.mp3")
			mp3_out_stream = File.stream!("tagged.mp3")
			{:ok, writer} = Polyvox.ID3.get_writer(mp3_in_stream)
			writer
			|> TagWriter.podcast("Your podcast name")
			|> TagWriter.title("The title of the episode") 
			|> TagWriter.participants(["John", "Ringo", "Paul", "George"])
			|> TagWriter.stream
			|> Enum.into(mp3_out_stream)
  """
	@spec get_writer(Stream.t) :: {:ok, pid} | {:error, term}
	def get_writer(stream) do
		Polyvox.ID3.TagWriterSupervisor.get_writer(stream)
	end
end
