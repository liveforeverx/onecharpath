defmodule Onecharpath do
  defmacrop t(quoted) do
    quote do
      {time, res} = :timer.tc(fn -> unquote(quoted) end)
      IO.puts("time elapsed #{div(time, 1_000)} ms")
      res
    end
  end
  def main(["naive", dictionary, first, last]) do
    words = File.read!(dictionary) |> String.split("\n")
    t(build_graph(:digraph.new, words, []) |> :digraph.get_short_path(first, last)) |> Enum.each(&IO.puts/1)
  end
  def main(["advanced", dictionary, first, last]) do
    words = File.read!(dictionary) |> String.split("\n") |> Enum.filter(&(&1 != ""))
    t(advanced_algorythm(words, first, last)) |> Enum.each(&IO.puts/1)
  end

  ## Naive
  def build_graph(g, [], _), do: g
  def build_graph(g, [word | words], acc) do
    neighbors = Enum.filter(acc, &compare_string(&1, word, 0))
    :digraph.add_vertex(g, word)
    for neighbor <- neighbors do
      :digraph.add_edge(g, word, neighbor)
      :digraph.add_edge(g, neighbor, word)
    end
    build_graph(g, words, [word | acc])
  end

  def compare_string(<<a :: utf8, rest1 :: binary>>, <<a :: utf8, rest2 :: binary>>, 0), do: compare_string(rest1, rest2, 0)
  def compare_string(<<_ :: utf8, rest :: binary>>, <<_ :: utf8, rest :: binary>>, 0), do: true
  def compare_string(_, _, _), do: false

  ## Advanced
  def advanced_algorythm(words, first, last) do
    graph = Enum.reduce(words, %{}, fn(word, map) ->
      replacements(word) |> Enum.reduce(map, fn(repl, map) ->
        update_in(map, [repl], &([word | (&1 || [])]))
      end)
    end)
    get_path(graph, [[first]], last)
  end

  def replacements(s) do
    for i <- 0..(byte_size(s)-1) do
      {first, << _ :: binary-size(1), last :: binary >>} = String.split_at(s, i)
      first <> last <> to_string(i)
    end
  end

  def get_path(graph, pathes, last) do
    try do
      get_path(graph, pathes, [], last, [pathes |> hd |> hd])
    catch
      {:path, path} -> Enum.reverse(path)
    end
  end

  def get_path(graph, [], acc, last, visited) do
    get_path(graph, acc, [], last, visited)
  end
  def get_path(graph, [path | pathes], acc, last, visited) do
    {visited, new_pathes} = hd(path) |> replacements |> Enum.reduce({visited, []}, fn(replacement, {visited, acc}) ->
      graph[replacement] |> Enum.reduce({visited, acc}, fn(word, {visited, acc}) ->
        cond do
          word == last ->
            throw {:path, [word | path]}
          Enum.member?(visited, word) ->
            {visited, acc}
          true ->
            {[word | visited], [[word | path] | acc]}
        end
      end)
    end)
    get_path(graph, pathes, new_pathes ++ acc, last, visited)
  end
end
