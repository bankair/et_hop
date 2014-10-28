require 'json'
require 'pry'
require './et_hop_response'

class EtHopRequest
  def initialize(parameters = {})
    @parameters = {}
    self.class._keys.each do |k|
      @parameters[k] = parameters.fetch(k)
    end
  end
  # Override to add keys
  def self._keys() [] end
  def _process(server, client)
    raise "Override the '_process' instance method in sub classes."
  end
  def process(server, client)
    begin
      return _process(server, client)
    rescue StandardError => e
      warn e.message
      warn e.backtrace.join("\n")
      return EtHopResponse.new(EtHopResponse::CODE_NOK)
    end
  end

  def _to_json
    Hash[self.class._keys.map{|k| [k, @parameters.fetch(k)] }]
  end

  def to_json
    { 'operation' => self.class.name }.merge(_to_json).to_json
  end

  def self.from_json(json)
    hash = JSON.parse(json)
    operation = hash.fetch('operation')
    subclass = SUBCLASSES.fetch(operation) do
      raise "Unknown operation type '#{operation}'"
    end
    subclass.new(hash)
  end

  def method_missing(m, *args, &block)  
    @parameters.fetch(m.to_s) { super }
  end

  SUBCLASSES = {}
  def self.inherited(subclass)
    SUBCLASSES[subclass.name] = subclass
  end
end

class EtHopRegisterRequest < EtHopRequest
  def self._keys() super.concat(%w(local_port)) end
  def _process(server, client)
    server.register(client, local_port)
  end
end

class EtHopIdentifiedRequest < EtHopRequest
  def self._keys() super.concat(%w(id magic)) end
  def _process(server, client)
    server.identify(id, magic)
  end
end

class EtHopUnregisterRequest < EtHopIdentifiedRequest
  def _process(server, client)
    super
    server.unregister(client, local_port)
  end
end

