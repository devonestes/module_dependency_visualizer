defmodule ModuleDependencyVisualizerTest do
  use ExUnit.Case
  alias ModuleDependencyVisualizer, as: MDV

  describe "analyze/1 when is_binary" do
    test "analyzing a file without aliases produces the right dependencies" do
      file = """
      defmodule Tester.One do
        def first(input) do
          String.length(input)
          List.first(input)
        end

        def second(input) do
          :lists.sort(input)
        end

        def third(input) do
          Tester.Other.first(input)
        end

        def fourth(input) do
          My.Long.Module.Chain.first(input)
        end
      end
      """

      result = file |> MDV.analyze() |> Enum.sort()

      assert result ==
               Enum.sort([
                 {"Tester.One", "String"},
                 {"Tester.One", "List"},
                 {"Tester.One", "lists"},
                 {"Tester.One", "Tester.Other"},
                 {"Tester.One", "My.Long.Module.Chain"}
               ])
    end

    test "analyzing a file with aliases produces the right dependencies" do
      file = """
      defmodule Tester.One do
        alias Tester.MyOther, as: Other
        alias My.Long.Module.Chain

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
          Chain.first(input)
        end
      end

      defmodule Tester.Two do
        alias Tester.Four
        alias Tester.Multi.{One, Three}

        def first(input) do
          input
            |> One.first
            |> Three.first
            |> Four.first
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
                 {"Tester.Two", "Tester.Multi.One"},
                 {"Tester.Two", "Tester.Multi.Three"},
                 {"Tester.Two", "Tester.Four"}
               ])
    end

    test "analyzing a file with use/import/require produces the right dependencies" do
      file = """
      defmodule Tester.One do
        alias Tester.MyOther, as: Other
        alias My.Long

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
          Long.Module.Chain.first(input)
        end
      end

      defmodule Tester.Two do
        alias Tester.{One, Three}
        import Tester.Five
        use Tester.Macro
        require Tester.Logger, as: Logger

        def first(input) do
          input |> One.third |> Tester.Logger.log
          Three.first(input)
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
                 {"Tester.Two", "Tester.One"},
                 {"Tester.Two", "Tester.Three"},
                 {"Tester.Two", "Tester.Five"},
                 {"Tester.Two", "Tester.Macro"},
                 {"Tester.Two", "Tester.Logger"}
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
