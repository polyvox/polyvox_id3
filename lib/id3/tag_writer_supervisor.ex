defmodule Polyvox.ID3.TagWriterSupervisor do
	use Supervisor

	@moduledoc false

	@doc """
	Convenience function to start the supervisor.
	"""
	@spec start_link() :: {:ok, pid} | {:error, term}
	def start_link do
		Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
	end

	def init(_) do
		prototype = [
			worker(Polyvox.ID3.TagWriter, [], restart: :temporary)
		]
		supervise(prototype, strategy: :simple_one_for_one)
	end

	@doc """
	Gets the pid of a `TagWriter` to write the ID3 tags added
	to the writer.
	"""
	@spec get_writer(Stream.t) :: {:ok, pid} | {:error, term}
	def get_writer(stream) do
		case Supervisor.start_child(__MODULE__, [stream]) do
			{:error, {:bad_return_value, {:error, e}}} -> {:error, e}
			ok -> ok
		end
	end
end
