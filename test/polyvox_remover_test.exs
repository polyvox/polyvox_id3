defmodule Polyvox.TagRemover.Test do
  use ExUnit.Case

	test "does nothing with an untagged file" do
		{:ok, pid} = StringIO.open("Untagged content.")

		pid
		|> IO.binstream(1024)
		|> Stream.into(File.stream!("original.mp3", [:write]))
		|> Stream.run

		pid
		|> StringIO.close

		assert(:ok == Polyvox.ID3.remove_tags("original.mp3", "copied.mp3"))

		{:ok, stat} =
			"copied.mp3"
		|> File.stat

		assert(stat.size == 17)

		File.rm("original.mp3")
		File.rm("copied.mp3")
	end

	test "removes version 1 tag" do
		content = "Untagged content."
		suffix = << "TAG", 0 :: integer-size(1000) >>
		{:ok, pid} = StringIO.open(content <> suffix)
		on_exit(fn () -> (File.rm("original.1.mp3"); File.rm("copied.1.mp3")) end)

		pid
		|> IO.binstream(1024)
		|> Stream.into(File.stream!("original.1.mp3", [:write]))
		|> Stream.run

		pid
		|> StringIO.close

		assert(:ok == Polyvox.ID3.remove_tags("original.1.mp3", "copied.1.mp3"))

		{:ok, stat} =
			"copied.1.mp3"
		|> File.stat

		assert(stat.size == String.length(content))
	end
end
