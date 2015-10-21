defmodule Polyvox.ID3.TagRemoverSupervisor do
	@moduledoc false

	use Supervisor

	def start_link do
		Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
	end

	def init(_) do
		prototype = [
			worker(Polyvox.ID3.TagRemover, [], restart: :temporary)
		]
		supervise(prototype, strategy: :simple_one_for_one)
	end

	def get_reader(path) do
		case Supervisor.start_child(__MODULE__, [path]) do
			{:error, {:bad_return_value, {:error, e}}} -> {:error, e}
			ok -> ok
		end
	end
end
