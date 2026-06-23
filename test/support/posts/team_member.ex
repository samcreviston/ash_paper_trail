# SPDX-FileCopyrightText: 2022 ash_paper_trail contributors <https://github.com/ash-project/ash_paper_trail/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshPaperTrail.Test.Posts.TeamMember do
  @moduledoc false
  use Ash.Resource,
    domain: AshPaperTrail.Test.Posts.Domain,
    data_layer: Ash.DataLayer.Ets,
    extensions: [AshPaperTrail.Resource],
    validate_domain_inclusion?: false

  ets do
    private? true
  end

  paper_trail do
    primary_key_type :uuid
    relationship_opts public?: true
  end

  code_interface do
    define :create
    define :read
    define :destroy
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
