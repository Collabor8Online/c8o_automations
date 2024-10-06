class RespondsWithGreeting < Struct.new(:greeting, keyword_init: true)
  def call(**params) = {greeting: "#{greeting} #{params[:name]}"}
end
