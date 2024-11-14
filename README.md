# Automations

This module allows you to define "automations" (think [IFTTT](https://ifttt.com) or [Shortcuts](https://support.apple.com/en-gb/guide/shortcuts/welcome/ios) but for your Rails app).

## TODO

- [ ] Add audit trail
- [X] Rename methods for handlers/configurations - #call does not explain what they do

## Usage

We use Automations at Collabor8Online to allow user-defined actions to take place in response to various "triggers".

(Also note that this gem was developed for use by us.  We're sharing it in case others find it useful, but depending upon demand, it may not be a true "community" project.  Finally note that currently it's licensed under the [LGPL](/LICENSE) which may make it unsuitable for some - contact us if you'd like to know about options).

In your application, you choose an ActiveRecord model to be the "container" that holds your automations.  Of course, depending upon your requirements, you may have multiple containers.  To become a container, you `include Automations::Container`.  

In Collabor8Online, all automations are attached to a "Project", so the Project model is also the Automations::Container.

A typical automation is when a document is uploaded into a folder (where a folder is a child model of a project).  If it is marked as "for review", it is moved from the Uploads folder into a "Review/In progress" folder and the reviewer notified.  Then, when the review is completed, another automation is triggered, which moves the document into the "Review/Completed" folder.

A version of this is shown in the [example specification](/spec/examples/trigger_spec.rb).

## Containers

Automations are attached to "containers" - these can be any ActiveRecord model.

Include the [Automations::Container](lib/automations/container.rb) module into your model.  This then gives you access to a series of methods that let you manage the automations attached to that container.

```ruby
class MyContainer < ActiveRecord::Base
  include Automations::Container
end

@my_container = MyContainer.create ...
@my_container.add_automation "8 am every day", configuration: Automations::DailySchedule.new(days: [0, 1, 2, 3, 4, 5, 6], times: [8])
@my_container.add_automation "Someone said hello", configuration: Automations::EventNameFilter.new(event_names: ["someone_said_hello"])

@my_container.automations
# => 2 automations

@my_container.trigger_automations event: "someone_said_hello", data: @user_who_said_hello
# => This will ask each automation if it is ready?.  The "Someone said hello" configuration will respond with true, whereas the "8 am every day" configuration will respond with false.  Therefore the "Someone said hello" automation will trigger and any actions that it has will be called.  

@my_container.trigger_automations time: Time.now
# => This will ask each automation if it is ready?.  The "Someone said hello" configuration will respond with false, whereas the "8 am every day" configuration will respond with true if the current time is betweeen 8am and 9am.  If it is the correct time, the "8 am every day" automation's actions will be called.  
```

## Configurations

By themselves, automations do very little.  They are governed by their configurations.

A configuration can be any class that:
- takes a set of keyword arguments in its constructor - `def initialize(first: "some value", second: "other value")`
- has a `to_h` method that can be used to extract the parameters needed to reconstruct the object later
- has a `ready?(**params)` method that returns true if the automation should be triggered
- has a `to_s` method that returns a summary of the configuration

The constructor will receive any configuration data required.  The `#ready?` method will receive the data that was used to trigger the automation.

If you want automations to run on a schedule, at particular days or times, there are a set of pre-built configurations that you can reuse - for example the [DailySchedule](lib/automations/daily_schedule.rb) uses an array of `days` and `times` to specify when it should be triggered.

```ruby
@my_container.add_automation "8 am every day", configuration: Automations::DailySchedule.new(days: [0, 1, 2, 3, 4, 5, 6], times: [8])
```

Your application could have an hourly cron job that finds your container and tells it to trigger its automations, passing in the current time as a parameter.  The container will find the automation and `call` it, passing the parameters it has been given.  The automation will then call `ready?` with those parameters, and if the configuration replies that it is ready (because the time it has been given is between 8am and 9am) then the automation will trigger and its actions will be called.  

```ruby
# cron job fires a rake task which...
@my_container.trigger_automations time: Time.now
# container goes through each automation and forwards the parameters to the call method...
automation.call **params
# automation forwards the parameters to the configuration's ready? method to see if it should fire
configuration.ready? **params
```
In addition to the prebuilt "schedule" configurations, there is an [EventNameFilter](lib/automations/event_name_filter.rb) - which expects to be supplied with a string "event_name" and a "data" parameter (which can be any type).  The constructor to the EventNameFilter is given a list of event_names to accept - so if the event_name provided is in the list, it will say it is `ready?` to fire.  

However, in most cases, you will need to write your own configurations to deal with the various triggers that could happen within your application.

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

Note that the `ready?` method uses a `splat` parameter - this is because (depending upon how you have things configured), you may be sending all kinds of different data to the automations in your application, so with a splat, you can accept varying parameters and respond only if the ones you were expecting were provided.  

## Actions

An automation uses the configuration to decide if it should be triggered, based on the parameters passed into the containers `trigger_automations` method and the response it receives from its configuration's `ready?` method.

Once triggered, it then goes through its list of actions and triggers each of those in turn.

However, just like automations, actions do not do very much by themselves.  

Instead, they rely on a handler.  Similar to configurations, these can be built from `Struct`s (as long as `keyword_init: true`) is provided.

A handler can be any class that:
- takes a set of keyword arguments in its constructor - `def initialize(folder_name: "Uploads")`
- has a `to_h` method that can be used to extract the parameters needed to reconstruct the object later
- has a `call(**params)` method to actually perform the action
- has a `to_s` method that returns a summary of the handler

`call` takes the parameters that were passed to `trigger_automations` and is expected to perform its actions and then return a hash.

As each action is triggered, the returned hash is merged in with the previous parameters and that merged hash is then passed on to the next action in the sequence.  So an action may return the input data unchanged, it may add new items for the next action to use, or it can override some of the existing data.  

If the action raises an exception, then details of the exception are added to the data (with the :error_type and :error_message keys) and execution is stopped.

The final data returns from the sequence of actions includes a key :success - which will be true if all actions fired correctly or false if an exception was raised.

