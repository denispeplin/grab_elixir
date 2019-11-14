defmodule GrabElixir do
  @url "https://elixirforum.com/t/i-want-to-teach-some-elixir-any-volunteers-to-be-taught/26750"

  def run do
    with {:ok, response} <- HTTPoison.get(@url) do
      messages =
        response.body
        |> Floki.find("div.topic-body")
        |> Enum.map(fn body ->
          post = Floki.raw_html(body)

          [
            {"a", [{"itemprop", "url"}, {"href", link}],
             [{"span", [{"itemprop", "name"}], [username]}]}
          ] = Floki.find(post, "span.creator a")

          post_body =
            post
            |> Floki.find("div.post")
            |> Floki.raw_html()

          {username, link, post_body}
        end)

      message_bodies =
        Enum.reduce(messages, %{}, fn {username, _link, post_body}, acc ->
          # note that bodies will be in reverse order as result
          Map.put(acc, username, [post_body | Map.get(acc, username) || []])
        end)

      user_links =
        Enum.map(messages, fn {username, link, _post_body} ->
          {username, link}
        end)
        |> Enum.uniq()

      {user_links, message_bodies}
    end
  end
end
