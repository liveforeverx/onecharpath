defmodule Onecharpath do
  def main([dictionary, first, last]) do
    words = File.read!(dictionary) |> String.split("\n")
    build_graph(:digraph.new, words, []) |> :digraph.get_path(first, last) |> Enum.each(&IO.puts/1)
  end

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
end
