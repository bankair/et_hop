require 'pry'
require 'json'
require 'socket'
require './et_hop_response'
require './et_hop_request'

class EtHopClient < TCPServer
  def initialize(parameters = {})
    @server_port = parameters.fetch(:server_port) { 2020 }
    @server_host = parameters.fetch(:server_host) { 'localhost' }
    @local_port = parameters.fetch(:local_port) { 2021 }
    connection_ok = false
    while ! connection_ok do
      begin
        warn "Trying to reserve port #{@local_port}"
        super(@local_port)
        connection_ok = true
      rescue => e
        warn e.message
        @local_port += 1
        raise "Could not create local server" if @local_port > 2029
      end
    end
  end

  def _register
    warn "Registering to #{@server_host}:#{@server_port}"
    s = TCPSocket.new(@server_host, @server_port)
    begin
      s.puts(EtHopRegisterRequest.new('local_port' => @local_port).to_json)
      response = s.gets
      et_hop_response = EtHopResponse.from_json(response)
      if et_hop_response.code != EtHopResponse::CODE_OK
        raise "Register operation failed. Response code: #{et_hop_response.code}"
      end
      @magic = et_hop_response.magic
      @id = et_hop_response.id
      warn "Got id (#{@id}) and magic (#{@magic}) from server."
    ensure
      s.close
    end
  end


  def start
    _register
    Thread.start do
      loop do
        Thread.start(accept) do |server|
          command = server.gets
          puts command
          server.close
        end
      end
    end
  end
end

et_hop_client = EtHopClient.new
puts "EtHopClient created"
et_hop_client.start
puts "EtHopClient started"
