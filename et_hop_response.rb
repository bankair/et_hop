require 'json'
require 'pry'

class EtHopResponse

  CODE_OK         = 0
  CODE_NOK        = 1

  CODE_KEY        = 'code'
  PARAMETERS_KEY  = 'parameters'

  attr_reader :code, :parameters
  def initialize(code, parameters = {})
    @code = code
    @parameters = parameters
  end

  def to_json
    { CODE_KEY => code, PARAMETERS_KEY => parameters }.to_json
  end

  def self.from_json(json)
    puts ' -> ' + json.inspect
    hash = JSON.parse(json)
    code = hash.fetch(CODE_KEY)
    parameters = hash.fetch(PARAMETERS_KEY) { {} }
    EtHopResponse.new(code, parameters)
  end

  def method_missing(m, *args, &block)  
    @parameters.fetch(m.to_s) { super }
  end
  
end

