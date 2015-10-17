defmodule Polyvox.ID3 do
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
	"""
	@spec get_writer(Stream.t) :: {:ok, pid} | {:error, term}
	def get_writer(stream) do
		Polyvox.ID3.TagWriterSupervisor.get_writer(stream)
	end
end
