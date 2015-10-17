defmodule Polyvox.ID3.TagInteractionSupervisor do
	use Supervisor

	def start_link do
		Supervisor.start_link(__MODULE__, nil)
	end

	def init(_) do
		children = [
			supervisor(Polyvox.ID3.TagReaderSupervisor, []),
			supervisor(Polyvox.ID3.TagWriterSupervisor, [])
		]
		supervise(children, strategy: :one_for_one)
	end
end
