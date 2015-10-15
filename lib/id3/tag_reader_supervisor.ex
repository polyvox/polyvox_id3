defmodule Polyvox.ID3.TagReaderSupervisor do
	use Supervisor

	@moduledoc """
	A supervisor that creates `TagReader`s.
	"""

	@doc """
	Convenience function to start the supervisor.
	"""
	@spec start_link() :: {:ok, pid} | {:error, term}
	def start_link do
		Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
	end

	def init(_) do
		prototype = [
			worker(Polyvox.ID3.TagReader, [], restart: :temporary)
		]
		supervise(prototype, strategy: :simple_one_for_one)
	end

	@doc """
	Gets the pid of a `TagReader` to read the ID3 tags found in
	the file located at path.
	"""
	@spec get_reader(binary) :: {:ok, pid} | {:error, term}
	def get_reader(path) do
		case Supervisor.start_child(__MODULE__, [path]) do
			{:error, {:bad_return_value, {:error, e}}} -> {:error, e}
			ok -> ok
		end
	end
end
