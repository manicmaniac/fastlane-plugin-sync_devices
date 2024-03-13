# frozen_string_literal: true

# MITM Proxy server that redirects SSL access of AppStore Connect API to our mock server.
#
# @example
#   curl -x https://localhost:8888 -k https://api.appstoreconnect.apple.com/v1/devices

require 'webrick'
require 'webrick/httpproxy'
require 'webrick/https'
require_relative 'app'

class WEBrick::HTTPRequest
  attr_writer :unparsed_uri
end

class ProxyServer < WEBrick::HTTPProxyServer
  def do_CONNECT(req, res)
    host = req.unparsed_uri.split(':', 2)[0]
    if host == 'api.appstoreconnect.apple.com'
      req.unparsed_uri = 'localhost:4567'
    end
    super
  end
end

if (pid = fork)
  proxy = ProxyServer.new({Port: 8888})
  trap("INT") do
    proxy.shutdown
    Process.kill('INT', pid)
  end
  proxy.start
else
  app = Sinatra::Application
  app.set(:server_settings, {
    Port: 4567,
    SSLEnable: true,
    SSLCertName: [['CN', 'api.appstoreconnect.apple.com']]
  })
  app.start!
end

