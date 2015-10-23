defmodule Polyvox.TagRemover.Test do
  use ExUnit.Case

	test "returns error on file that does not exist" do
		assert({:error, :enoent} == Polyvox.ID3.remove_tags("unknown.mp3", "whatever.mp3"))
	end
	
	test "does nothing with an untagged file" do
		run_test("no-tags.mp3", "no-tags.copied.mp3", "", "")
	end

	defp run_test(original_name, copied_name, prefix, suffix) do
		content = prefix <> "Untagged content." <> suffix
		{:ok, pid} = StringIO.open(content)
		on_exit(fn () -> (File.rm(original_name); File.rm(copied_name); StringIO.close(pid)) end)

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

	# test "removes version 1 tag" do
	# 	content = "Untagged content."
	# 	suffix = << "TAG", 0 :: integer-size(1000) >>
	# 	{:ok, pid} = StringIO.open(content <> suffix)
	# 	on_exit(fn () -> (File.rm("original.1.mp3"); File.rm("copied.1.mp3")) end)

	# 	pid
	# 	|> IO.binstream(1024)
	# 	|> Stream.into(File.stream!("original.1.mp3", [:write]))
	# 	|> Stream.run

	# 	pid
	# 	|> StringIO.close

	# 	assert(:ok == Polyvox.ID3.remove_tags("original.1.mp3", "copied.1.mp3"))

	# 	{:ok, stat} =
	# 		"copied.1.mp3"
	# 	|> File.stat

	# 	assert(stat.size == String.length(content))
	# end

	# test "removes version 2.3 tag" do
	# 	content = "Untagged content."
	# 	prefix = << "ID3", 3, 0, 0, 0, 0, 0, 30, 0 :: integer-size(240) >>
	# 	{:ok, pid} = StringIO.open(prefix <> content)
	# 	on_exit(fn () -> (File.rm("original.2.3.mp3"); File.rm("copied.2.3.mp3")) end)

	# 	pid
	# 	|> IO.binstream(1024)
	# 	|> Stream.into(File.stream!("original.2.3.mp3", [:write]))
	# 	|> Stream.run

	# 	pid
	# 	|> StringIO.close

	# 	assert(:ok == Polyvox.ID3.remove_tags("original.2.3.mp3", "copied.2.3.mp3"))

	# 	# {:ok, stat} =
	# 	# 	"copied.1.mp3"
	# 	# |> File.stat

	# 	# assert(stat.size == String.length(content))
	# end
end
