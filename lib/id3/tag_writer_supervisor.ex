defmodule Polyvox.ID3.TagWriterSupervisor do
	@moduledoc false

	use Supervisor

	def start_link do
		Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
	end

	def init(_) do
		prototype = [
			worker(Polyvox.ID3.TagWriter, [], restart: :temporary)
		]
		supervise(prototype, strategy: :simple_one_for_one)
	end

	def get_writer(stream) do
		case Supervisor.start_child(__MODULE__, [stream]) do
			{:error, {:bad_return_value, {:error, e}}} -> {:error, e}
			ok -> ok
		end
	end
end
