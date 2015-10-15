# Polyvox.ID3

A podcast-centric ID3 library for parsing and writing ID3 tags.

## ID3 tag support

In this parlance, a podcast-centric ID3 library supports the following
information for ID3 tags.

| Name                | Example                                                         | v1† | v2.3 frame | Atom            |
| ------------------- | --------------------------------------------------------------- | :-: | :--------: | --------------- |
| Podcast name        | polyvox                                                         |  X  |  TALB      | `:podcast`      |
| Episode title       | Beefsteak Handshake                                             |  X  |  TIT2      | `:title`        |
| Episode number      | 1                                                               |  X  |  TRCK      | `:number`       |
| Participants        | Bryan, Heather, and Curtis                                      |  X  |  TPE1      | `:participants` |
| Year recorded       | 2015                                                            |  X  |  TYER      | `:year`         |
| Summary             | Our inaugural podcast                                           |  X  |  TIT3      | `:summary`      |
| Description         | In our inaugural podcast, we start with the underhandedness...  |     |  COMM      | `:description`  |
| Show notes          | What did we talk about? &lt;ul&gt;&lt;li&gt;The recent...       |     |  TXXX      | `:show_notes`   |
| Genres              | Personal Journals                                               |  X  |  TCON      | `:genres`       |
| Episode artwork     | Pretty picture :)                                               |     |  APIC      | `:artwork`      |
| Month/date recorded | June 3                                                          |     |  TDAT      | `:date`         |
| Episode Web page    | http://polyvox.audio/podcasts/1.html                            |     |  WOAF      | `:url`          |
| Podcast Web page    | http://polyvox.audio                                            |     |  WOAS      | `:podcast_url`  |
| Unique Identifier   | 2CA119D7-1A5D-4CBE-BE5D-06A001B53B52                            |     |  UFID      | `:uid`          |

† **A note about v1 ID3 tags** The podcast name, episode title, and participants
can have no more than 30 characters. The summary can have no more than 28
characters. Don't worry, though: most podcast players use the v2.3 tags without
a problem.
