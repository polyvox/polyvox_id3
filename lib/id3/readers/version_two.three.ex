defmodule VersionTwoThree do
	defstruct [:podcast, :title, :number, :participants, :year, :description, :show_notes, :genres, :artwork, :date, :url, :podcast_url, :uid, :s, :e]

	def parse(%{path: path, caller: caller}) do
		File.open(path) |> parse_or_error(caller)
	end

	defp parse_or_error({:ok, device}, caller), do: device |> do_parse |> send_to(caller) |> File.close
	defp parse_or_error(e, caller), do: e |> inform_error(caller)

	defp do_parse(device) do
		
	end

	defp send_to({device, content}, caller) do
		send(caller, {:v2, content})
		device
	end

	defp inform_error({:error, :enoent}, caller) do
		send(caller, {:error, :v2, :enoent})
	end
end
