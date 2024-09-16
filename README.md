# Automations

This module allows you to define "automations" (think [IFTTT](https://ifttt.com) or [Shortcuts](https://support.apple.com/en-gb/guide/shortcuts/welcome/ios) but for your Rails app).

## Example

We use Automations at Collabor8Online to allow user-defined actions to take place in response to various "triggers".

## Types of Automation

Automations fall in to two categories - ScheduledAutomations and Triggers.

As the name suggests, ScheduledAutomations are designed to fire at regular intervals.  There are four in-built configurations for ScheduledAutomations - a [DailySchedule](lib/automations/daily_schedule.rb), [WeeklySchedule](lib/automations/weekly_schedule.rb), [MonthlySchedule](lib/automations/monthly_schedule.rb) and [AnnualSchedule](lib/automations/annual_schedule.rb).  To get them to work, you will need to have a cron job (or similar) that triggers the `scheduled_automations:trigger` rake task once per hour.

Triggers are more flexible and rely on the containing application to provide the configuration that tells them when to fire.  There is only one in-built configuration for triggers - the [EventNameFilter](lib/automations/event_name_filter.rb).  See below for details about how to define your own and integrate triggers into your app.

## Containers

Automations are attached to "containers" - these can be any ActiveRecord model.

Include the [Automations::Container](lib/automations/container.rb) module into your model.  This then gives you access to a series of methods that let you manage the automations attached to that container.

```ruby
class MyContainer < ActiveRecord::Base
  include Automations::Container
end

@my_container = MyContainer.create ...
@my_container.add_scheduled_automation "8 am every day", configuration: Automations::DailySchedule.new(days: [0, 1, 2, 3, 4, 5, 6], times: [8])
@my_container.add_trigger "Someone said hello", configuration: Automations::EventNameFilter.new(event_names: ["someone_said_hello"])

@my_container.automations.active
# => 1 trigger, 1 scheduled automation
@my_container.automations.scheduled
# => 1 scheduled automation
@my_container.automations.triggers
# => 1 trigger

@my_container.call_triggers "someone_said_hello", data: @user_who_said_hello
# => will check the "Someone said hello" configuration and if it passes (the event name is "someone_said_hello") will trigger the automation

@my_container.call_automations_at Time.now
# => will check the "8 am every day" configuration and if it passes (if it's between 8am and 9am) will trigger the automation
```

## Configurations

By themselves, automations do very little.  They are governed by their configurations.

A configuration can be any class that:
- takes a set of keyword arguments in its constructor - `def initialize(**configuration_data)`
- has a `to_h` method that can be used to extract the parameters needed to reconstruct the object later
- has a `ready?(**params)` method
- has a `to_s` method that returns a summary of the configuration

The constructor will receive any configuration data required.  The `ready?` method will receive the data that was used to trigger the automation.

ScheduledAutomations are triggered at a time.  Therefore the [DailySchedule](lib/automations/daily_schedule.rb) uses an array of `days` and `times` to configure when it should be triggered.

```ruby
@my_container.add_scheduled_automation "8 am every day", configuration: Automations::DailySchedule.new(days: [0, 1, 2, 3, 4, 5, 6], times: [8])
```

Then, when the automation is triggered (for example, by an hourly cron job), the automation will ask the configuration if it is ready to be triggered.

```ruby
# automation
configuration.ready?(time: Time.now)
```

The DailySchedule then checks to see if it's currently between 8am and 9am and returns true or false accordingly.  If true, the automation then triggers its actions.

Triggers can be triggered by any event within your application.  So instead of a time, the parameters passed to the configuration are `event` and `data`.  The [EventNameFilter](lib/automations/event_name_filter.rb) looks at the event parameter and returns true if it is included in its list.  However, it is likely that you will need to write your own configurations to deal with the various triggers that could happen within your application.

### Custom configurations

As mentioned, a configuration class must take keyword parameters in its constructor and have a `ready?` method that returns a boolean.

The easiest way to do this is to define a ruby `Struct` with the `keyword_init: true` parameter.

```ruby
class SpamEmailReceived < Struct.new(:blacklisted_domains, keyword_init: true)

  def ready? event:, data:
    return false unless event == "email_received"
  	domain = data[:email].from.split("@").last
  	blacklisted_domains.include? domain
  end

end

@email_server.add_trigger "Spam Email", configuration: SpamEmailReceived.new(blacklisted_domains: ["annoyingmarketers.com", "shit-shovelers.com"])
```

## Actions

An automation uses the configuration to decide if it should be triggered, based on the time, or the event, it has been given.

Once triggered, it then goes through its list of actions and triggers each of those in turn.

However, just like automations which rely on their configurations, actions do not do very much by themselves.  Instead, they rely on a handler.  Similar to configurations, these can be built from `Struct`s (as long as `keyword_init: true`) is provided.

A handler can be any class that:
- takes a set of keyword arguments in its constructor - `def initialize(**configuration_data)`
- has a `to_h` method that can be used to extract the parameters needed to reconstruct the object later
- has a `accepts?(**params)` method to answer whether the action can be performed when given those parameters
- has a `call(**params)` method to actually perform the action
- has a `to_s` method that returns a summary of the handler

The `accepts?` method takes the incoming parameters and must respond with true or false (to say whether this handler will run).

`call` takes those same parameters and is expected to perform its actions, returning a hash.

The automation triggers each action (and hence its handler) in sequence, passing in some parameters at the start.  As each action is triggered, it can then modify or add to those parameters, which are then passed on to the next action in the sequence.  The parameters provided are merged with the results of the action and the combination is passed on to the next action in the sequence.  So an action can either pass on the input data unchanged, it can add new items to the data, which are then given to the next action, or it can override some of the existing data.

## Example

For example, at Collabor8Online, we have an automation that is set to trigger when a document is added to a folder.  A typical automation may be to look for documents added to the "Uploads" folder, then move them to the "Approvals" folder and start a task for a manager to review the document.

So the trigger is configured something like this:

```ruby
class DocumentAddedToFolder < Struct.new(:upload_folder_id, keyword_init: true)
	def ready? event:, data:
		(event == "document_added_to_folder") && (data.folder.id == upload_folder_id)
	end
end
```

The administrator adds the automation to a project (which is the container for automations), selecting "DocumentAddedToFolder" and specifying the ID of the "Uploads" folder.  When an activity is added to the audit trail, the automations for that project are triggered, passing the activity type as the event and the activity details as data.  If the documents were added to the "Uploads" folder then the automation starts.

The first action moves the documents to the "Approvals" folder.

```ruby
class MoveDocumentsAcross < Struct.new(:folder_name, keyword_init: true)
	def accepts? container:, automation:, action:, user:, folder:, documents:
		folder.has_sibling? folder_name
	end

	def call container:, automation:, action:, user:, folder:, documents:
	  destination_folder = folder.find_sibling folder_name
	  documents.each { |document| document.move_to destination_folder }
	  { folder: destination_folder }
	end
end
```

This checks that the folder it has been triggered from does have an "Approvals" folder alongside it, and then moves each document into that folder.  It then overrides the folder it was given with the "Approvals" folder, so subsequent actions will be working from there.

The next action starts an approval task for these documents.

```ruby
class StartTask < Struct.new(:workflow_template_name, :email_addresses, keyword_init: true)
	def accepts? container:, automation:, action:, user:, folder:, documents:
		container.workflow_templates.find_by(name: workflow_template_name).present?
	end

	def call container:, automation:, action:, user:, folder:, documents:
		workflow_template = container.workflow_templates.find_by(name: workflow_template_name)
		assignees = container.project_members.where(email: email_addresses)
		workflow_task = workflow_template.start_task_in folder, documents: documents, assignees: assignees, created_by: user
		{ workflow_task: workflow_task }
	end
end
```

This checks that the container (a Project in the application) has a WorkflowTemplate with the correct name.  If so, it then finds that template, finds the people that the new task will be assigned to, then creates the task, attaching the documents in question.  Finally, it returns the newly created task, so any subsequent actions can reference it.
