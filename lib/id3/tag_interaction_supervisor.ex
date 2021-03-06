defmodule Polyvox.ID3.TagInteractionSupervisor do
	@moduledoc false
	
	use Supervisor

	def start_link do
		Supervisor.start_link(__MODULE__, nil)
	end

	def init(_) do
		children = [
			supervisor(Polyvox.ID3.TagReaderSupervisor, []),
			supervisor(Polyvox.ID3.TagWriterSupervisor, []),
			supervisor(Polyvox.ID3.TagRemoverSupervisor, [])
		]
		supervise(children, strategy: :one_for_one)
	end
end
