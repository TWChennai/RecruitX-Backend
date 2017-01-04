defmodule RecruitxBackend.PanelistStatusSpec do
  use ESpec.Phoenix, model: RecruitxBackend.PipelineStatus

  alias RecruitxBackend.PipelineStatus

  let :valid_attrs, do: params_with_assocs(:pipeline_status)
  let :invalid_attrs, do: %{}

  context "valid changeset" do
    subject do: PipelineStatus.changeset(%PipelineStatus{}, valid_attrs())

    it do: should be_valid()
  end

  context "invalid changeset" do
    subject do: PipelineStatus.changeset(%PipelineStatus{}, invalid_attrs())

    it do: should_not be_valid()
    it do: should have_errors(name: {"can't be blank", [validation: :required]})

    it "should be invalid when name is an empty string" do
      pipeline_status_with_empty_name = Map.merge(valid_attrs(), %{name: ""})
      changeset = PipelineStatus.changeset(%PipelineStatus{}, pipeline_status_with_empty_name)

      expect(changeset) |> to(have_errors(name: {"can't be blank", [validation: :required]}))
    end

    it "should be invalid when name is nil" do
      pipeline_status_with_nil_name = Map.merge(valid_attrs(), %{name: nil})
      changeset = PipelineStatus.changeset(%PipelineStatus{}, pipeline_status_with_nil_name)

      expect(changeset) |> to(have_errors([name: {"can't be blank", [validation: :required]}]))
    end

    it "should be invalid when name is a blank string" do
      pipeline_status_with_blank_name = Map.merge(valid_attrs(), %{name: "  "})
      changeset = PipelineStatus.changeset(%PipelineStatus{}, pipeline_status_with_blank_name)

      expect(changeset) |> to(have_errors([name: {"has invalid format", [validation: :format]}]))
    end

    it "should be invalid when name is only numbers" do
      pipeline_status_with_numbers_name = Map.merge(valid_attrs(), %{name: "678"})
      changeset = PipelineStatus.changeset(%PipelineStatus{}, pipeline_status_with_numbers_name)

      expect(changeset) |> to(have_errors([name: {"has invalid format", [validation: :format]}]))
    end

    it "should be invalid when name starts with space" do
      pipeline_status_starting_with_space_name = Map.merge(valid_attrs(), %{name: " space"})
      changeset = PipelineStatus.changeset(%PipelineStatus{}, pipeline_status_starting_with_space_name)

      expect(changeset) |> to(have_errors([name: {"has invalid format", [validation: :format]}]))
    end
  end

  context "unique_constraint" do
    it "should be invalid when pipeline_status already exists with same name" do
      new_pipeline_status = insert(:pipeline_status)
      valid_pipeline_status = PipelineStatus.changeset(%PipelineStatus{}, %{name: new_pipeline_status.name})
      {:error, changeset} = Repo.insert(valid_pipeline_status)
      expect(changeset) |> to(have_errors(name: {"has already been taken", []}))
    end

    it "should be invalid when pipeline_status already exists with same name but different case" do
      new_pipeline_status = insert(:pipeline_status)
      pipeline_status_in_caps = PipelineStatus.changeset(%PipelineStatus{}, %{name: String.upcase(new_pipeline_status.name)})
      {:error, changeset} = Repo.insert(pipeline_status_in_caps)
      expect(changeset) |> to(have_errors(name: {"has already been taken", []}))
    end
  end
end
