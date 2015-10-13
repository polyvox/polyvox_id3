defmodule Polyvox.ID3 do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_, _) do
		Polyvox.ID3.Supervisor.start_link
  end

	@doc """
	Gets the pid of a `TagReader` to read the ID3 tags found in
	the file located at path.
	"""
	@spec get_reader(binary) :: {:ok, pid} | {:error, term}
	def get_reader(path) do
		Polyvox.ID3.Supervisor.get_reader(path)
	end
end
