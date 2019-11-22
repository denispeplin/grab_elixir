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
    with {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} <- HTTPoison.get(url) do
      response_body
      |> get_topic_from_body()
      |> Enum.map(fn body ->
        post = Floki.raw_html(body)

        with {link, username} <- get_user_link_and_username(post) do
          post_body = get_post_body(post)

          {username, link, post_body}
        else
          _result ->
            parse_next_page(post)
        end
      end)
      |> Enum.reject(&is_nil(&1))
    end
  end

  defp get_topic_from_body(response_body) do
    Floki.find(response_body, "div.topic-body")
  end

  defp get_user_link_and_username(post) do
    with [
           {"a", [{"itemprop", "url"}, {"href", link}],
            [{"span", [{"itemprop", "name"}], [username]}]}
         ] <- Floki.find(post, "span.creator a") do
      {link, username}
    end
  end

  defp get_post_body(post) do
    post
    |> Floki.find("div.post")
    |> Floki.raw_html()
  end

  defp parse_next_page(post) do
    post
    |> Floki.find("div.crawler-post a")
    |> do_parse_next_page()
  end

  defp do_parse_next_page([
         {"a", [{"rel", "next"}, {"itemprop", "url"}, {"href", next_page_path}], _}
       ]) do
    messages(@base_url <> next_page_path)
  end

  defp do_parse_next_page(_), do: nil
end
