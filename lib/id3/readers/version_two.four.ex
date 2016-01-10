defmodule Polyvox.ID3.Readers.VersionTwoFour do
  @moduledoc false

  defstruct [:podcast, :summary, :title, :number, :participants, :year, :description, :show_notes, :genres, :artwork, :date, :url, :podcast_url, :uid, :s, :version, :size, :synced, :ext, :exp]

  def parse_header_only(path) do
    case File.open(path) do
      {:error, _} -> nil
      {:ok, device} ->
        acc = %__MODULE__{version: 2.3, s: 0}

        {device, acc}
        |> parse_header
        |> return_header
    end
  end

  defp return_header({:stop, device}) do
    File.close(device)
    nil
  end

  defp return_header({device, acc}) do
    File.close(device)
    acc
  end

  defp parse_header({device, _} = s) do
    s
    |> parse_header(IO.binread(device, 10))
  end

  defp parse_header({device, acc}, << ?I, ?D, ?3, 4, 0, sync :: size(1), ext :: size(1), exp :: size(1), 0 :: size(5),  size :: binary-size(4) >>) do
    {device, %__MODULE__{acc | size: unsync(size) + 10, synced: sync == 1, ext: ext == 1, exp: exp == 1}}
  end

  defp parse_header({device, _}, _) do
    {:stop, device}
  end

  defp unsync(value) do
    integer_size = bit_size(value)
    << i :: integer-size(integer_size) >> = do_unsync(value)
    i
  end

  defp do_unsync(<< 0 :: size(1), x :: size(7) >> <> rest) do
    remaining_size = 7 * byte_size(rest)
    padding_size = byte_size(rest) + 1

    << 0 :: size(padding_size),
    x :: size(7),
    unsync(rest) :: size(remaining_size) >>
  end

  defp do_unsync(<< >>) do
    << >>
  end
end
