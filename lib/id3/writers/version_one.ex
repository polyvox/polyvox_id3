defmodule Polyvox.ID3.Writers.VersionOne do
	def stream(state) do
		[do_text_stream("ID3"),
		 do_text_stream(Map.get(state, :title), 30),
		 do_text_stream(Map.get(state, :participants), 30),
		 do_text_stream(Map.get(state, :podcast), 30),
		 do_text_stream(Map.get(state, :year)),
		 do_text_stream(Map.get(state, :summary), 28),
		 do_int_stream(0),
		 do_int_stream(Map.get(state, :number)),
		 do_int_stream(101)]
		|> Stream.concat
	end

	defp do_text_stream(text, truncate \\ nil)

	defp do_text_stream(text, truncate) when is_binary(text) do
		truncate = truncate || byte_size(text)
		
		text
		|> binary_part(0, truncate)
		|> Stream.unfold(&make_stream/1)
	end

	defp do_text_stream(list, truncate) when is_list(list) do
		do_text_stream(Stream.join(list, ", "), truncate)
	end

	defp do_text_stream(value, truncate) do
		do_text_stream(to_string(value), truncate)
	end

	defp do_int_stream(value) do
		do_text_stream(<< value >>)
	end

	defp make_stream(<< x >> <> rest) do
		{x, rest}
	end

	defp make_stream("") do
		nil
	end
end
