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
#   When a document is added to "Uploads" and its status is "awaiting_review" it will be moved "across" to the "Review" folder and then "down" to the "In progress" folder and the reviewer notified.

RSpec.describe "Firing a trigger that moves documents to different folders", type: :model do
  # standard:disable Lint/ConstantDefinitionInBlock

  # Configuration for the "Review documents" automation
  class ReviewDocuments < Struct.new(:status, keyword_init: true)
    def ready? **params
      params.key?(:documents) && params[:documents].any? { |d| d.requires_review? }
    end
  end

  # Handler for the "move documents to review folder" action
  class MoveDocumentsAcross < Struct.new(:folder_name, keyword_init: true)
    def call(documents:, folder:, **)
      raise FolderNotFound if (destination_folder = folder.sibling_called(folder_name)).nil?
      # This is a bit nasty - have to convert to an array because if we are given an ActiveRecord relation for "all documents in folder X" then the relation will update itself to be empty after we move the documents out of that folder
      documents = documents.collect { |d| d.update!(folder: destination_folder) && d }
      {documents: documents, folder: destination_folder}
    end
  end

  # Handler for the "move documents to in progress folder" action
  class MoveDocumentsDown < Struct.new(:folder_name, keyword_init: true)
    def call(documents:, folder:, **)
      raise FolderNotFound if (destination_folder = folder.children.find_by(name: folder_name)).nil?

      # This is a bit nasty - have to convert to an array because if we are given an ActiveRecord relation for "all documents in folder X" then the relation will update itself to be empty after we move the documents out of that folder
      documents = documents.collect { |d| d.update!(folder: destination_folder) && d }
      {documents: documents, folder: destination_folder}
    end
  end

  # Handler for the "notify the reviewer" action
  class NotifyReviewer < Struct.new(:email_address, keyword_init: true)
    def call(documents:, folder:, **)
      # TODO: ReviewerMailer.with(documents: documents, folder: folder, recipient: email_address).documents_awaiting_review.deliver_later
      {documents: documents, folder: folder, reviewer: email_address}
    end
  end

  class FolderNotFound < Automations::Error
  end
  # standard:enable Lint/ConstantDefinitionInBlock

  before do
    @project = Automatable.create! name: "Some project"
    @uploads_folder = Folder.create! project: @project, name: "Uploads"
    @review_folder = Folder.create! project: @project, name: "Review"
    @in_progress_folder = Folder.create! project: @project, name: "In progress", parent: @review_folder
    @completed_folder = Folder.create! project: @project, name: "Completed", parent: @review_folder

    @automation = Automations::Trigger.create! container: @project, name: "Review documents", configuration: ReviewDocuments.new
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
