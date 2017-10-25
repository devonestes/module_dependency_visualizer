defmodule ModuleDependencyVisualizerTest do
  use ExUnit.Case
  alias ModuleDependencyVisualizer, as: MDV

  describe "analyze/1 when is_binary" do
    test "analyzing a file produces the right dependencies" do
      file = """
      defmodule Tester.One do
        alias Tester.MyOther, as: Other

        def first(input) do
          String.length(input)
          List.first(input)
        end

        def second(input) do
          :lists.sort(input)
        end

        def third(input) do
          Other.first(input)
        end

        def fourth(input) do
          My.Long.Module.Chain.first(input)
        end
      end

      defmodule Tester.Two do
        alias Tester.One

        def first(input) do
          One.third(input)
        end
      end
      """

      result = file |> MDV.analyze() |> Enum.sort()

      assert result ==
               Enum.sort([
                 {"Tester.One", "String"},
                 {"Tester.One", "List"},
                 {"Tester.One", "lists"},
                 {"Tester.One", "Tester.MyOther"},
                 {"Tester.One", "My.Long.Module.Chain"},
                 {"Tester.Two", "Tester.One"}
               ])
    end
  end

  describe "create_gv_file/1" do
    test "turns a dependency list into a properly formatted graphviz file" do
      dependency_list = [
        {"Tester.One", "String"},
        {"Tester.One", "lists"},
        {"Tester.One", "Tester.MyOther"},
        {"Tester.One", "My.Long.Module.Chain"},
        {"Tester.Two", "Tester.One"}
      ]

      expected = """
      digraph G {
        "Tester.One" -> "String";
        "Tester.One" -> "lists";
        "Tester.One" -> "Tester.MyOther";
        "Tester.One" -> "My.Long.Module.Chain";
        "Tester.Two" -> "Tester.One";
      }
      """

      assert MDV.create_gv_file(dependency_list) == expected
    end
  end
end
