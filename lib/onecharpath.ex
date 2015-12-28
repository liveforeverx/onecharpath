defmodule Onecharpath do
  # Timing macro
  defmacrop t(quoted) do
    quote do
      {time, res} = :timer.tc(fn -> unquote(quoted) end)
      IO.puts("time elapsed #{div(time, 1_000)} ms")
      res
    end
  end

  # Main program
  def main([impl, dictionary, first, last]) do
    words = File.read!(dictionary) |> String.split("\n") |> Enum.filter(&(&1 != ""))
    t(
      case impl do
        "naive"    -> build_graph_naive(words)
        "advanced" -> build_graph_advanced(words)
      end |> :digraph.get_short_path(first, last)
    ) |> Enum.each(&IO.puts/1)
  end

  ## Naive
  def build_graph_naive(g \\ :digraph.new, words, acc \\ [])
  def build_graph_naive(g, [], _), do: g
  def build_graph_naive(g, [word | words], acc) do
    neighbors = Enum.filter(acc, &compare_string(&1, word, 0))
    :digraph.add_vertex(g, word)
    for neighbor <- neighbors, do: connect(g, word, neighbor)
    build_graph_naive(g, words, [word | acc])
  end

  def compare_string(<<a :: utf8, rest1 :: binary>>, <<a :: utf8, rest2 :: binary>>, 0), do: compare_string(rest1, rest2, 0)
  def compare_string(<<_ :: utf8, rest :: binary>>, <<_ :: utf8, rest :: binary>>, 0), do: true
  def compare_string(_, _, _), do: false

  ## Advanced
  def build_graph_advanced(words) do
    g = :digraph.new
    Enum.reduce(words, %{}, fn(word, map) ->
      replacements(word) |> Enum.reduce(map, fn(repl, map) ->
        update_in(map, [repl], &([word | (&1 || [])]))
      end)
    end) |> Enum.each(fn({_, values}) -> connect_edges(g, values) end)
    g
  end

  def connect_edges(g, []), do: g
  def connect_edges(g, [value | values]) do
    :digraph.add_vertex(g, value)
    Enum.each(values, &(connect(g, &1, value)))
    connect_edges(g, values)
  end

  def replacements(s) do
    for i <- 0..(byte_size(s)-1) do
      {first, << _ :: binary-size(1), last :: binary >>} = String.split_at(s, i)
      first <> last <> to_string(i)
    end
  end

  ## Helper
  defp connect(g, word1, word2) do
    :digraph.add_edge(g, word1, word2)
    :digraph.add_edge(g, word2, word1)
  end
end
