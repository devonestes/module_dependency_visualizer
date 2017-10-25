defmodule ModuleDependencyVisualizer do
  @moduledoc """
  This is the public interface for this simple little tool to parse a file or
  list of files for dependencies between modules. It will use the `dot` command
  to generate a graph PNG for us thanks to graphviz.
  """

  @doc """
  Analyzes a given list of file paths (absolute or relative), creates the
  necessary Graphviz file, and then creates the graph and opens it.
  """
  @spec run(list) :: :ok
  def run(file_paths) do
    file_paths
    |> analyze
    |> create_gv_file
    |> create_and_open_graph

    :ok
  end

  @doc """
  This will accept a list of file paths (absolute or relative), read each of
  those files, and return a keyword list of all the module dependencies in
  all those files. The output looks something like this:

  [{"ModuleName", "String"}, {"ModuleName", "lists"}]

  The lowercase modules are Erlang modules, and the camelcase modules are all
  Elixir modules.
  """
  @spec analyze([String.t()]) :: [{String.t(), String.t()}]
  def analyze(file_paths) when is_list(file_paths) do
    Enum.flat_map(file_paths, fn file_path ->
      {:ok, file} = File.read(file_path)
      analyze(file)
    end)
  end

  @doc """
  Analyzes a single file for dependencies between modules. This is the real meat
  of this tool. After this is done, then it's just formatting the graphviz file
  correctly and that's pretty easy.
  """
  @spec analyze(String.t()) :: [{String.t(), String.t()}]
  def analyze(file) when is_binary(file) do
    {:ok, ast} = Code.string_to_quoted(file)

    {_, all_modules} =
      Macro.postwalk(ast, [], fn
        ast = {:__aliases__, _meta, module_info}, modules ->
          {ast, modules ++ [module_info]}

        ast, modules ->
          {ast, modules}
      end)

    all_modules
  end

  @doc """
  Takes a list of dependencies and returns a string that is a valid `dot` file.
  """
  @spec create_gv_file(list) :: String.t()
  def create_gv_file(dependency_list) do
    body = Enum.map(dependency_list, fn {mod1, mod2} -> "  \"#{mod1}\" -> \"#{mod2}\";" end)
    "digraph G {\n#{Enum.join(body, "\n")}\n}\n"
  end

  @doc """
  This creates the graphviz file on disk, then runs the `dot` command to
  generate the graph as a PNG, and opens that PNG for you.
  """
  @spec create_and_open_graph(String.t()) :: {Collectable.t(), exit_status :: non_neg_integer}
  def create_and_open_graph(gv_file) do
    gv_file_path = "./output.gv"
    graph_path = "./graph.png"
    File.write(gv_file_path, gv_file)
    System.cmd("dot", ["-Tpng", gv_file_path, "-o", graph_path])
    System.cmd("open", [graph_path])
  end
end
