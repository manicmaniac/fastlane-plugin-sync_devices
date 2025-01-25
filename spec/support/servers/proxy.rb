# frozen_string_literal: true

# MITM Proxy server that redirects SSL access of AppStore Connect API to our mock server.

require 'webrick'
require 'webrick/httpproxy'
require 'webrick/https'
require_relative 'app'

module WEBrick
  class HTTPRequest
    attr_writer :unparsed_uri
  end
end

class ProxyServer < WEBrick::HTTPProxyServer
  attr_reader :app_port

  def initialize(config)
    @app_port = config.delete(:AppPort)
    super
  end

  def do_CONNECT(req, res) # rubocop:disable Naming/MethodName
    host = req.unparsed_uri.split(':', 2)[0]
    req.unparsed_uri = "localhost:#{app_port}" if host == 'api.appstoreconnect.apple.com'

    super
  end
end
