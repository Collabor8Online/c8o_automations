require "rails_helper"
require "plumbing/spec/modes"

RSpec.describe "Notifiying observers" do
  Plumbing::Spec.modes do
    context "In #{Plumbing.config.mode} mode" do
      describe "Automations.events" do
        it "allows observers to be added as blocks" do
          @observer = await do
            Automations.events.add_observer { |event_name, data| puts event_name }
          end

          @result = await { Automations.events.is_observer?(@observer) }
          expect(@result).to eq true
        end

        it "allows observers to be added as procs" do
          @observer = ->(event_name, data) { puts event_name }
          await { Automations.events.add_observer @observer }

          @result = await { Automations.events.is_observer?(@observer) }
          expect(@result).to eq true
        end

        it "allows observers to be removed" do
          @observer = ->(event_name, data) { puts event_name }

          Automations.events.add_observer @observer
          Automations.events.remove_observer @observer

          @result = await { Automations.events.is_observer?(@observer) }
          expect(@result).to eq false
        end
      end

      describe "notifying observers" do
        before do
          Plumbing.configure timeout: 3
          # Plumbing.config.logger.level = Logger::DEBUG

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

        it "notifies observers with an 'automations/automation_triggered' event when an automation has been triggered" do
          @results = []
          Automations.events.add_observer do |event_name, data|
            @results << data if event_name == "automations/automation_triggered"
          end
          @documents = [@uploads_folder.documents.create!(name: "document1.txt", status: "requires_review"), @uploads_folder.documents.create!(name: "document2.txt", status: "requires_review")]

          @automation.call documents: @uploads_folder.documents, folder: @uploads_folder

          expect { @results.count }.to become 1
          @data = @results.first

          expect(@data[:automation]).to eq @automation
          expect(@data[:documents]).to eq @documents
          expect(@data[:folder]).to eq @uploads_folder
        end

        it "does not notify observers if an automation was not triggered" do
          @results = []
          Automations.events.add_observer do |event_name, data|
            @results << data if event_name == "automations/automation_triggered"
          end
          @document = @uploads_folder.documents.create! name: "Not awaiting review.txt", status: "reviewed"

          @automation.call documents: @uploads_folder.documents, folder: @uploads_folder

          sleep 1 # cannot await a negative so we just have to sleep

          expect(@results.count).to eq 0
        end

        it "notifies observers with an 'automations/action_fired' event when an action fires" do
          @results = []
          Automations.events.add_observer do |event_name, data|
            @results << data if event_name == "automations/action_fired"
          end
          @documents = [@uploads_folder.documents.create!(name: "document1.txt", status: "requires_review"), @uploads_folder.documents.create!(name: "document2.txt", status: "requires_review")]

          @automation.call documents: @uploads_folder.documents, folder: @uploads_folder

          expect { @results.count }.to become 3

          @data = @results.first
          expect(@data[:action]).to eq @move_to_review
          expect(@data[:documents]).to eq @documents
          expect(@data[:folder]).to eq @uploads_folder

          @data = @results.second
          expect(@data[:action]).to eq @move_to_in_progress
          expect(@data[:documents]).to eq @documents
          expect(@data[:folder]).to eq @review_folder

          @data = @results.third
          expect(@data[:action]).to eq @notify_reviewer
          expect(@data[:documents]).to eq @documents
          expect(@data[:folder]).to eq @in_progress_folder
        end

        it "notifies observers with an 'automations/action_failed' event if an action raises an exception" do
          @results = []
          Automations.events.add_observer do |event_name, data|
            @results << data if event_name == "automations/action_failed"
          end
          @documents = [@uploads_folder.documents.create!(name: "document1.txt", status: "requires_review"), @uploads_folder.documents.create!(name: "document2.txt", status: "requires_review")]
          # Delete the "in progress" folder, so the MoveDocumentsDown(folder_name: "In progress") action cannot fire
          @in_progress_folder.destroy

          @automation.call documents: @uploads_folder.documents, folder: @uploads_folder

          expect { @results.count }.to become 1

          @data = @results.first
          expect(@data[:action]).to eq @move_to_in_progress
          expect(@data[:error_type]).to eq "FolderNotFound"
        end
      end
    end
  end
end
