module Automations
  class ActionCaller
    def initialize actions
      @actions = actions
    end

    def call **params
      result = params
      @actions.each do |action|
        result = result.merge(action.call(**result))
      rescue => ex
        # if we get an exception stop now and return the results
        return result.merge error_message: ex.message, error_type: ex.class.to_s, success: false
      end
      result.merge(success: true)
    end
  end
end
