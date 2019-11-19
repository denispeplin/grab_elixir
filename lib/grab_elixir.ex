defmodule GrabElixir do
  @base_url "https://elixirforum.com"
  @url @base_url <> "/t/i-want-to-teach-some-elixir-any-volunteers-to-be-taught/26750"

  def run(url \\ @url) do
    messages =
      messages(url)
      |> List.flatten()

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

  defp messages(url) do
    with {:ok, response} <- HTTPoison.get(url) do
      response.body
      |> Floki.find("div.topic-body")
      |> Enum.map(fn body ->
        post = Floki.raw_html(body)

        with [
               {"a", [{"itemprop", "url"}, {"href", link}],
                [{"span", [{"itemprop", "name"}], [username]}]}
             ] <- Floki.find(post, "span.creator a") do
          post_body =
            post
            |> Floki.find("div.post")
            |> Floki.raw_html()

          {username, link, post_body}
        else
          _result ->
            post
            |> Floki.find("div.crawler-post a")
            |> parse_next_page()
        end
      end)
      |> Enum.reject(&is_nil(&1))
    end
  end

  defp parse_next_page([
         {"a", [{"rel", "next"}, {"itemprop", "url"}, {"href", next_page_path}], _}
       ]) do
    messages(@base_url <> next_page_path)
  end

  defp parse_next_page(_), do: nil
end
