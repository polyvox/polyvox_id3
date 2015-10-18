defprotocol Polyvox.ID3.Tag do
	@moduledoc "Represents a tag, virtual or physical, in an MP3 file."

	@doc "Gets the podcast name."
	@spec podcast(Tag.t) :: binary | nil
	def podcast(tag)

	@doc "Gets the title of the episode."
	@spec title(Tag.t) :: binary | nil
	def title(tag)

	@doc "Gets the number of the episode."
	@spec number(Tag.t) :: integer | nil
	def number(tag)

	@doc "Gets the names of the people in the episode."
	@spec participants(Tag.t) :: list(binary) | nil
	def participants(tag)

	@doc "Gets the year of the recording of the episode."
	@spec year(Tag.t) :: integer | nil
	def year(tag)

	@doc "Gets the summary of the episode's contents."
	@spec summary(Tag.t) :: binary | nil
	def summary(tag)

	@doc "Gets the description of the episode's contents."
	@spec description(Tag.t) :: binary | nil
	def description(tag)

	@doc "Gets the notes for the show."
	@spec show_notes(Tag.t) :: binary | nil
	def show_notes(tag)

	@doc "Gets the list of genres for the episode."
	@spec genres(Tag.t) :: list(integer) | nil
	def genres(tag)

	@doc """
  Gets a stream that contains the artwork for the episode.

  __Note: This is not yet implemented because it's not MVP.__
  """
	@spec artwork(Tag.t) :: Stream.t | nil
	def artwork(tag)

	@doc "Gets the date of the recording of the podcast in DDMM format."
	@spec date(Tag.t) :: binary | nil
	def date(tag)

	@doc "Gets the URL for the episode."
	@spec url(Tag.t) :: binary | nil
	def url(tag)

	@doc "Gets the URL of the podcast."
	@spec podcast_url(Tag.t) :: binary | nil
	def podcast_url(tag)

	@doc "Gets the unique identifier for the episode."
	@spec uid(Tag.t) :: binary | nil
	def uid(tag)
end
