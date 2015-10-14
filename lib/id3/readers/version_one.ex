defmodule Polyvox.ID3.Readers.VersionOne do
	use GenServer

	def start_link(path) do
		GenServer.start_link(__MODULE__, path)
	end

	def init(path) do
		File.open(path)
	end
end
