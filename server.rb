require 'pry'
require 'json'
require 'socket'
require 'digest'

require './et_hop_response'
require './et_hop_request'

DEBUG = true



# Operations:
# register: register client, and send back an id.
# alive: client is alive. Sent every 5 mins.

class EtHopSubscriber
  attr_reader :id, :host, :port
  def initialize(id, host, port)
    @id = id
    @port = port
    @host = host
  end
end

class EtHopServer < TCPServer
  attr_reader :magic
  def initialize(parameters = {})
    @mode = parameters.fetch(:mode) { :server }
    unless [:client, :server].include? @mode
      raise "Unknown mode '#{@mode}'. Use :client or :server"
    end
    @port = parameters.fetch(:port) { 2020 }
    @client_index = 0
    @magic = Digest::MD5.hexdigest(Time.now.to_s + rand(1000000).to_s).to_s
    @clients = {}
    super(@port)
    warn "Registed port #{@port}."
  end

  def get_next_id
    id = @client_index
    @client_index += 1
    id
  end

  def register(client, port)
    id = get_next_id
    subscriber = EtHopSubscriber.new(id, client, port)
    @clients[id] = subscriber
    warn "Registering client #{subscriber.host}:#{port} as ##{id}"
    EtHopResponse.new(EtHopResponse::CODE_OK, id: id, magic: magic)
  end

  def start
    loop do
      Thread.start(accept) do |client|
        client_port, client_host = Socket.unpack_sockaddr_in(client.getsockname)
        warn "Accepted connection from #{client_host}:#{client_port}."
        begin
          json = client.gets
          warn "Received request: #{json}"
          request = EtHopRequest.from_json(json)
          warn "Request parsed."
          response = request.process(self, client_host)
          warn "Response dump to json..."
          json = response.to_json
          warn "Response: #{json}"
          client.puts(json)
        rescue StandardError => e
          warn "Could not process command '#{command.inspect}': #{e.message}"
          warn e.backtrace.join("\n") if DEBUG
        ensure
          warn "Closing connection with #{client_host}:#{client_port}"
          client.close
        end
      end
    end
  end
end

et_hop_server = EtHopServer.new
et_hop_server.start
