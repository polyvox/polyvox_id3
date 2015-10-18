defmodule Polyvox.ID3 do
	@moduledoc """
	An entry point into the library that allows you to get readers
	and writers of ID3 tags.
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

  This method takes the path to a file and will return an
  asynchronous reader of ID3 tags.

  Example Usage
  -------------

  The following code shows how to get the tag from a tag reader
  after the asynchronous operations complete.

      alias Polyvox.ID3.TagReader
      {:ok, reader} = Polyvox.ID3.get_reader("tagged.mp3")
      tag = get_tag(reader)
      
      def get_tag(reader) do
        reader |> do_get_tag
      end
      
      def do_get_tag(reader, status \\ :notfound)
      
      def do_get_tag(reader, :notfound) do
        status = reader |> TagReader.tag
        reader |> do_get_tag(status)
      end
      
      def do_get_tag(_, tag) do
        tag
      end  
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

  Example Usage
  -------------

  The following code shows how to write values into the tag
  writer and put them into the corresponding output stream.

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
