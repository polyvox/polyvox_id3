defmodule Polyvox.TagRemover.Test do
  use ExUnit.Case

	test "returns error on file that does not exist" do
		assert({:error, :enoent} == Polyvox.ID3.remove_tags("unknown.mp3", "whatever.mp3"))
	end
	
	test "does nothing with an untagged file" do
		run_test("no-tags.mp3", "no-tags.copied.mp3", "", "")
	end

	test "removes version 1 tag" do
		suffix = << "TAG", 0 :: integer-size(1000) >>
		run_test("v1.mp3", "v1.removed.mp3", "", suffix)
	end

	test "removes version 2.3 tag" do
		prefix = << "ID3", 3, 0, 0, 0, 0, 0, 125, 0 :: integer-size(1000) >>
		run_test("v2.3.mp3", "v2.3.removed.mp3", prefix, "")
	end

	defp run_test(original_name, copied_name, prefix, suffix) do
		content = prefix <> "Untagged content." <> suffix
		{:ok, pid} = StringIO.open(content)
		on_exit(fn () -> (File.rm(copied_name); File.rm(original_name)) end)

		pid
		|> IO.binstream(1024)
		|> Stream.into(File.stream!(original_name, [:write]))
		|> Stream.run

		pid
		|> StringIO.close

		assert(:ok == Polyvox.ID3.remove_tags(original_name, copied_name))

		{:ok, stat} =
			copied_name
		|> File.stat

		assert(stat.size == 17)
	end
end
