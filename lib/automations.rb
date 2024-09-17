require "automations/version"
require "automations/engine"
require "automations/core_ext"

module Automations
  require_relative "automations/types"
  require_relative "automations/validations"
  require_relative "automations/daily_schedule"
  require_relative "automations/weekly_schedule"
  require_relative "automations/monthly_schedule"
  require_relative "automations/annual_schedule"
  require_relative "automations/event_name_filter"
  require_relative "automations/container"
end
