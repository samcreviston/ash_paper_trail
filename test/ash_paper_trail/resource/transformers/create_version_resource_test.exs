# SPDX-FileCopyrightText: 2022 ash_paper_trail contributors <https://github.com/ash-project/ash_paper_trail/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshPaperTrail.Resource.Transformers.CreateVersionResourceTest do
  use ExUnit.Case

  defmodule Tag do
    use Ash.Resource,
      domain: AshPaperTrail.Resource.Transformers.CreateVersionResourceTest.Domain,
      data_layer: Ash.DataLayer.Ets,
      extensions: [AshPaperTrail.Resource],
      validate_domain_inclusion?: false

    ets do
      private? true
    end

    actions do
      default_accept :*
      defaults [:create, :update, :destroy, :read]
    end

    attributes do
      attribute :name, :string do
        public? true
        allow_nil? false
        primary_key? true
        constraints max_length: 20
      end
    end
  end

  defmodule Domain do
    use Ash.Domain, extensions: [AshPaperTrail.Domain], validate_config_inclusion?: false

    resources do
      resource Tag
      resource Tag.Version
    end
  end

  describe "attribute :version_source_id" do
    setup do
      version_source_id = Ash.Resource.Info.attribute(Tag.Version, :version_source_id)
      [version_source_id: version_source_id]
    end

    test "uses resource primary key type", %{version_source_id: version_source_id} do
      assert version_source_id.type == Ash.Type.String
    end

    test "uses resource primary key constraints", %{version_source_id: version_source_id} do
      assert Keyword.equal?(version_source_id.constraints,
               allow_empty?: false,
               trim?: true,
               max_length: 20
             )
    end
  end

  defmodule TeamMember do
    use Ash.Resource,
      domain: AshPaperTrail.Resource.Transformers.CreateVersionResourceTest.CompositeDomain,
      data_layer: Ash.DataLayer.Ets,
      extensions: [AshPaperTrail.Resource],
      validate_domain_inclusion?: false

    ets do
      private? true
    end

    actions do
      default_accept :*
      defaults [:create, :read, :destroy]
    end

    attributes do
      attribute :team_id, :uuid do
        primary_key? true
        allow_nil? false
        public? true
      end

      attribute :user_id, :uuid do
        primary_key? true
        allow_nil? false
        public? true
      end
    end
  end

  defmodule CompositeDomain do
    use Ash.Domain, extensions: [AshPaperTrail.Domain], validate_config_inclusion?: false

    resources do
      resource TeamMember
      resource TeamMember.Version
    end
  end

  describe "composite primary keys" do
    test "creates version source attributes for each primary key component" do
      assert Ash.Resource.Info.attribute(TeamMember.Version, :version_source_team_id)
      assert Ash.Resource.Info.attribute(TeamMember.Version, :version_source_user_id)
      refute Ash.Resource.Info.attribute(TeamMember.Version, :version_source_id)
    end

    test "relates version to source with has_one and paper_trail_versions with filter" do
      version_source = Ash.Resource.Info.relationship(TeamMember.Version, :version_source)
      assert version_source.type == :has_one
      assert version_source.no_attributes?

      paper_trail_versions = Ash.Resource.Info.relationship(TeamMember, :paper_trail_versions)
      assert paper_trail_versions.type == :has_many
      assert paper_trail_versions.no_attributes?
    end
  end
end
