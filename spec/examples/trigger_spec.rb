require "rails_helper"

#   The structure is:
#
#   Project
#   |
#   +-- Uploads
#   |
#   +-- Review
#       |
#       +-- In progress
#       |
#       +-- Completed
#
#  When a document is added to "Uploads" and its status is "awaiting_review" it will be moved "across" to the "Review" folder and then "down" to the "In progress" folder and the reviewer notified.
#  See [the test app](/spec/test_app/app/models) for the configurations and actions used in these tests

RSpec.describe "Firing a trigger that moves documents to different folders", type: :model do
  before do
    @project = Automatable.create! name: "Some project"
    @uploads_folder = Folder.create! project: @project, name: "Uploads"
    @review_folder = Folder.create! project: @project, name: "Review"
    @in_progress_folder = Folder.create! project: @project, name: "In progress", parent: @review_folder
    @completed_folder = Folder.create! project: @project, name: "Completed", parent: @review_folder

    @automation = Automations::Automation.create! container: @project, name: "Review documents", configuration: ReviewDocuments.new(statuses: ["requires_review"])
    @move_to_review = Automations::Action.create! automation: @automation, name: "Move to Review folder", handler: MoveDocumentsAcross.new(folder_name: "Review"), position: 1
    @move_to_in_progress = Automations::Action.create! automation: @automation, name: "Move to In progress folder", handler: MoveDocumentsDown.new(folder_name: "In progress"), position: 2
    @notify_reviewer = Automations::Action.create! automation: @automation, name: "Notify reviewer", handler: NotifyReviewer.new(email_address: "reviewer@example.com"), position: 3
  end

  it "does not fire if the configuration conditions are not met" do
    # this document is not awaiting review so should not fire
    @document = @uploads_folder.documents.create! name: "Not awaiting review.txt", status: "reviewed"

    @result = @automation.call documents: @uploads_folder.documents, folder: @uploads_folder

    expect(@result).to be_nil
    expect(@document.reload.folder).to eq @uploads_folder

    # this trigger is called with the wrong parameters so should not fire
    @result = @automation.call event_name: "something_happened", message: "somewhere else in the application"

    expect(@result).to be_nil
    expect(@document.reload.folder).to eq @uploads_folder
  end

  it "fires each action in turn" do
    @document_1 = @uploads_folder.documents.create! name: "document1.txt", status: "requires_review"
    @document_2 = @uploads_folder.documents.create! name: "document2.txt", status: "requires_review"

    @result = @automation.call documents: @uploads_folder.documents, folder: @uploads_folder

    expect(@result[:documents]).to include @document_1
    expect(@result[:documents]).to include @document_2
    expect(@result[:folder]).to eq @in_progress_folder
    expect(@result[:reviewer]).to eq "reviewer@example.com"
    expect(@result[:success]).to eq true
  end

  it "records its actions in the audit trail"

  it "stops when an action does not fire" do
    @document_1 = @uploads_folder.documents.create! name: "document1.txt", status: "requires_review"
    @document_2 = @uploads_folder.documents.create! name: "document2.txt", status: "requires_review"

    # Delete the "in progress" folder, so the MoveDocumentsDown(folder_name: "In progress") action cannot fire
    @in_progress_folder.destroy

    @result = @automation.call documents: @uploads_folder.documents, folder: @uploads_folder

    expect(@result[:documents]).to include @document_1
    expect(@result[:documents]).to include @document_2
    expect(@result[:folder]).to eq @review_folder
    expect(@result[:reviewer]).to be_nil
    expect(@result[:success]).to eq false
    expect(@result[:error_type]).to eq "FolderNotFound"
  end

  it "records that it has stopped in the audit trail"
end
