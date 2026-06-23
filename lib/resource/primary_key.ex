# SPDX-FileCopyrightText: 2022 ash_paper_trail contributors <https://github.com/ash-project/ash_paper_trail/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshPaperTrail.Resource.PrimaryKey do
  @moduledoc false
  # Shared version-source primary key mapping for single and composite keys.

  @version_source_id :version_source_id

  @doc "Returns `{source_pk, version_attr}` pairs for a resource or DSL state."
  def pairs(resource) do
    resource
    |> Ash.Resource.Info.primary_key()
    |> Enum.map(&{&1, version_source_attribute_name(resource, &1)})
  end

  #Returns true when the resource has more than one primary key attribute.
  def composite?(resource) do
    resource |> Ash.Resource.Info.primary_key() |> length() > 1
  end

  # Returns the version-side attribute name for a given source PK — :version_source_id for
  # single PK, :version_source_<name> for composite.
  # sobelow_skip ["DOS.StringToAtom"]
  def version_source_attribute_name(resource, source_key) do
    case Ash.Resource.Info.primary_key(resource) do
      [_single] -> @version_source_id
      _ -> String.to_atom("version_source_#{source_key}")
    end
  end

  # Returns all version-side attribute names for a resource's primary key(s).
  def version_source_attribute_names(resource) do
    resource
    |> Ash.Resource.Info.primary_key()
    |> Enum.map(&version_source_attribute_name(resource, &1))
  end

  # Returns {source_pk, version_attr, source_attribute} tuples, including type and
  # constraints from the source attribute.
  def mappings(resource) do
    resource
    |> pairs()
    |> Enum.map(fn {source_key, version_attr} ->
      {source_key, version_attr, Ash.Resource.Info.attribute(resource, source_key)}
    end)
  end

  # Builds a map of version attribute names → values from a source record,
  # for use when creating a version at runtime.
  def version_source_input(result, resource) do
    Map.new(pairs(resource), fn {source_key, version_attr} ->
      {version_attr, Map.get(result, source_key)}
    end)
  end

  # Filter for `has_many :paper_trail_versions` on the source resource.
  def source_versions_filter(resource) do
    resource
    |> source_versions_filter_ast()
    |> build_filter()
  end

  # Filter for `has_one :version_source` on the version resource.
  def version_source_filter(resource) do
    resource
    |> version_source_filter_ast()
    |> build_filter()
  end

  # Returns quoted AST for the source-side filter (e.g. version_source_team_id == parent(team_id)),
  # used when embedding expr(...) in generated code.
  def source_versions_filter_ast(resource) do
    resource
    |> pairs()
    |> Enum.map(fn {source_key, version_attr} ->
      quote do
        unquote(Macro.var(version_attr, nil)) == parent(unquote(Macro.var(source_key, nil)))
      end
    end)
    |> combine_and()
  end

  # Returns quoted AST for the version-side filter (e.g. team_id == parent(version_source_team_id)),
  # used when embedding expr(...) in generated code.
  def version_source_filter_ast(resource) do
    resource
    |> pairs()
    |> Enum.map(fn {source_key, version_attr} ->
      quote do
        unquote(Macro.var(source_key, nil)) == parent(unquote(Macro.var(version_attr, nil)))
      end
    end)
    |> combine_and()
  end

  # Converts quoted filter AST into a runtime Ash filter struct via Ash.Expr.expr/1.
  # sobelow_skip ["RCE.CodeModule"]
  defp build_filter(ast) do
    {filter, _} =
      Code.eval_quoted(
        quote do
          require Ash.Expr
          Ash.Expr.expr(unquote(ast))
        end,
        [],
        __ENV__
      )

    filter
  end

  # Joins one or more quoted filter conditions into a single and expression.
  defp combine_and([single]), do: single

  defp combine_and([first | rest]) do
    Enum.reduce(rest, first, fn right, left ->
      quote do
        unquote(left) and unquote(right)
      end
    end)
  end
end
