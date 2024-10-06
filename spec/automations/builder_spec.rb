require "rails_helper"

RSpec.describe Automations::Builder, type: :model do
  subject(:builder) { described_class.new configuration_file, container: project }
  let(:project) { Automatable.create! name: "Some project" }
  let(:configuration_file) do
    <<~YAML
      ---
      name: Review documents
      class_name: ReviewDocuments
      configuration:
        statuses:
        - requires_review
      actions:
      - name: Move to Review folder
        class_name: MoveDocumentsAcross
        configuration:
          folder_name: Review
      - name: Move to In progress folder
        class_name: MoveDocumentsDown
        configuration:
          folder_name: In progress
      - name: Notify reviewer
        class_name: NotifyReviewer
        configuration:
          email_address: reviewer@example.com
    YAML
  end

  it "creates an automation and adds it to a container" do
    @automation = builder.build_automation

    expect(@automation.container).to eq project
    expect(@automation.name).to eq "Review documents"
    expect(@automation.configuration).to be_kind_of ReviewDocuments
    expect(@automation.configuration.statuses).to eq ["requires_review"]
    expect(@automation.actions.count).to eq 3

    @move_to_review = @automation.actions.first
    expect(@move_to_review.name).to eq "Move to Review folder"
    expect(@move_to_review.handler).to be_kind_of MoveDocumentsAcross
    expect(@move_to_review.handler.folder_name).to eq "Review"

    @move_to_in_progress = @automation.actions.second
    expect(@move_to_in_progress.name).to eq "Move to In progress folder"
    expect(@move_to_in_progress.handler).to be_kind_of MoveDocumentsDown
    expect(@move_to_in_progress.handler.folder_name).to eq "In progress"

    @notify_reviewer = @automation.actions.third
    expect(@notify_reviewer.name).to eq "Notify reviewer"
    expect(@notify_reviewer.handler).to be_kind_of NotifyReviewer
    expect(@notify_reviewer.handler.email_address).to eq "reviewer@example.com"
  end

  it "updates an existing automation" do
    @existing_automation = Automations::Automation.create! container: project, name: "Review documents", configuration: ReviewDocuments.new(statuses: "awaiting_review")
    @move_to_review = Automations::Action.create! automation: @existing_automation, name: "Move to Start Review folder", handler: MoveDocumentsAcross.new(folder_name: "Start Review"), position: 1

    @automation = builder.build_automation

    expect(@automation).to eq @existing_automation
    expect(@automation.name).to eq "Review documents"
    expect(@automation.configuration).to be_kind_of ReviewDocuments
    expect(@automation.configuration.statuses).to eq ["requires_review"]
    expect(@automation.actions.count).to eq 3

    @move_to_review = @automation.actions.first
    expect(@move_to_review.name).to eq "Move to Review folder"
    expect(@move_to_review.handler).to be_kind_of MoveDocumentsAcross
    expect(@move_to_review.handler.folder_name).to eq "Review"

    @move_to_in_progress = @automation.actions.second
    expect(@move_to_in_progress.name).to eq "Move to In progress folder"
    expect(@move_to_in_progress.handler).to be_kind_of MoveDocumentsDown
    expect(@move_to_in_progress.handler.folder_name).to eq "In progress"

    @notify_reviewer = @automation.actions.third
    expect(@notify_reviewer.name).to eq "Notify reviewer"
    expect(@notify_reviewer.handler).to be_kind_of NotifyReviewer
    expect(@notify_reviewer.handler.email_address).to eq "reviewer@example.com"
  end

  it "generates a configuration file" do
    @automation = builder.build_automation

    @yaml = @automation.to_configuration_file

    expect(@yaml).to eq configuration_file
  end
end
