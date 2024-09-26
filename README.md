# Automations

This module allows you to define "automations" (think [IFTTT](https://ifttt.com) or [Shortcuts](https://support.apple.com/en-gb/guide/shortcuts/welcome/ios) but for your Rails app).

## TODO

- [ ] Add audit trail
- [X] Rename methods for handlers/configurations - #call does not explain what they do

## Usage

We use Automations at Collabor8Online to allow user-defined actions to take place in response to various "triggers".

(Also note that this gem was developed for use by us.  We're sharing it in case others find it useful, but depending upon demand, it may not be a true "community" project.  Finally note that currently it's licensed under the [LGPL](/LICENSE) which may make it unsuitable for some - contact us if you'd like to know about options).

In Collabor8Online, all automations are attached to a "Project", so the Project model is also the Automations::Container.

A typical automation is when a document is uploaded into a folder.  If it is marked as "for review", it is moved from the Uploads folder into a "Review/In progress" folder and the reviewer notified.  Then, when the review is completed, another automation is triggered, which moves the document into the "Review/Completed" folder.

A version of this is shown in the [example specification](/spec/examples/trigger_spec.rb).

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

@my_container.call_triggers event: "someone_said_hello", data: @user_who_said_hello
# => will check the "Someone said hello" configuration and if it passes (the event name is "someone_said_hello") will trigger the automation

@my_container.call_automations_at Time.now
# => will check the "8 am every day" configuration and if it passes (if it's between 8am and 9am) will trigger the automation
```

## Configurations

By themselves, automations do very little.  They are governed by their configurations.

A configuration can be any class that:
- takes a set of keyword arguments in its constructor - `def initialize(first: "some value", second: "other value")`
- has a `to_h` method that can be used to extract the parameters needed to reconstruct the object later
- has a `ready?(**params)` method that returns true if the automation should be triggered
- has a `to_s` method that returns a summary of the configuration

The constructor will receive any configuration data required.  The `#ready?` method will receive the data that was used to trigger the automation.

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

Triggers can be fired by any event within your application.  So instead of a time, the parameters passed to the configuration are application-specific.  The example [EventNameFilter](lib/automations/event_name_filter.rb) expects a string "event_name" parameter and a "data" parameter (which matches an observer from the plumbing gem).  The filter looks at the event name and returns true if it is included in its list.  However, in most cases, you will need to write your own configurations to deal with the various triggers that could happen within your application.

### Custom configurations

As mentioned, a configuration class must take keyword parameters in its constructor and have a `ready?` method that returns a boolean.

The easiest way to do this is to define a ruby `Struct` with the `keyword_init: true` parameter.

```ruby
class SpamEmailReceived < Struct.new(:blacklisted_domains, keyword_init: true)

  def ready? **input
	  event = input[:event]
		data = input[:data]
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
- takes a set of keyword arguments in its constructor - `def initialize(folder_name: "Uploads")`
- has a `to_h` method that can be used to extract the parameters needed to reconstruct the object later
- has a `call(**params)` method to actually perform the action
- has a `to_s` method that returns a summary of the handler

`call` takes those same parameters and is expected to perform its actions, returning a hash.

The automation triggers each action (and hence its handler) in sequence, passing in some parameters at the start.

As each action is triggered, it returns a hash which is merged in with the previous parameters - so the action modifies or adds to the data which is passed to the next action in the sequence.  So an action can either pass on the input data unchanged, it can add new items to the data, which are then given to the next action, or it can override some of the existing data.  If the action raises an exception, then details of the exception are added to the data (with the :error_type and :error_message keys) and execution is stopped.

The final data returns from the sequence of actions includes a key :success - which will be true if all actions fired correctly or false if an exception was raised.

