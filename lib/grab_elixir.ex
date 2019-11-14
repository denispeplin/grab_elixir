defmodule GrabElixir do
  @url "https://elixirforum.com/t/i-want-to-teach-some-elixir-any-volunteers-to-be-taught/26750"

  def run do
    with {:ok, response} <- HTTPoison.get(@url) do
      Floki.find(response.body, "span a")
      |> Enum.map(fn {"a", [{"itemprop", "url"}, {"href", link}],
                      [{"span", [{"itemprop", "name"}], [username]}]} ->
        {link, username}
      end)
    end
  end
end
