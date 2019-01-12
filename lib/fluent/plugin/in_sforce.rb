# frozen_string_literal: true

require 'nokogiri'
require 'restforce'
require 'date'
require 'net/http'
require 'faye'
require 'fluent/plugin/input'

module Fluent
  module Plugin
    class SforceInput < Input
      class SforceConnectionError < StandardError; end

      Fluent::Plugin.register_input('sforce', self)

      config_param :query, :string, default: 'SELECT id, Body, CreatedById FROM FeedItem'
      config_param :tag, :string, default: 'sforce'
      config_param :polling_interval, :integer, default: 60
      config_param :topic, :string, default: nil
      config_param :username, :string
      config_param :password, :string
      config_param :version, :string, default: '43.0'
      config_param :login_endpoint, :string, default: 'login.salesforce.com'

      def configure(conf)
        super
      end

      def start
        super
        login_info = login
        client = Restforce.new login_info.merge(api_version: @version)

        th_low = DateTime.now.strftime('%Y-%m-%dT%H:%M:%S.000%Z')
        # query
        if @topic == nil then
          sleep(@polling_interval)
          th_high = DateTime.now.strftime('%Y-%m-%dT%H:%M:%S.000%Z')
          loop do
            # create soql query string
            where = "CreatedDate <= #{th_high} AND CreatedDate > #{th_low}"
            soql = ''
            if @query =~ /^(.+)\s(where|WHERE)\s(.+)$/ then
              soql = "#{$1} WHERE #{where} AND #{$3}"
            elsif @query =~ /^(.+)$/ then
              soql = "#{$1} WHERE #{where}"
            end

            begin
              log.info "query: #{soql}"
              records = client.query(soql)
              records.each do |record|
                router.emit(@tag, Fluent::Engine.now, record)
              end
              sleep(@polling_interval)
              th_low = th_high
              th_high = DateTime.now.strftime('%Y-%m-%dT%H:%M:%S.000%Z')
            rescue Restforce::UnauthorizedError => e
              log.error e
              # retry login
              login_info = login
              client = Restforce.new login_info.merge(api_version: @version)
            end
          end
          # streaming api
        else
          EM.run do
            log.info "suscribe: #{@topic}"
            # Subscribe to the PushTopic.
            client.subscribe @topic do |message|
              router.emit(@tag, Fluent::Engine.now, message)
            end
          end
        end
      rescue SforceConnectionError => e
        log.error e.message
      end

      def shutdown
        super
      end

      private

      def login
        uri = URI(login_endpoint)
        request = Net::HTTP::Post.new(uri.request_uri, initheader = {'Content-Type' =>'text/xml', 'SOAPAction' => "''"})
        request.body = <<BODY
<?xml version="1.0" encoding="utf-8"?>
<env:Envelope xmlns:xsd="http://www.w3.org/2001/XMLSchema"
xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">
<env:Body>
<n1:login xmlns:n1="urn:partner.soap.sforce.com">
<n1:username>#{@username.encode(xml: :text)}</n1:username>
<n1:password>#{@password.encode(xml: :text)}</n1:password>
</n1:login>
</env:Body>
</env:Envelope>
BODY

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE

        # request login call and parse login response.
        http.start do |h|
          response = h.request(request)
          doc = Nokogiri::XML(response.body)
          fault = doc.css('faultstring').inner_text
          raise SforceConnectionError, fault unless fault.empty?

          session_id = doc.css('sessionId').inner_text
          /^(https:\/\/.+\.salesforce\.com)\//.match(doc.css('serverUrl').inner_text)
          instance_url = $1
          log.info "login is successful. instance_url = '#{instance_url}'"

          {oauth_token: session_id, instance_url: instance_url}
        end
      end

      def login_endpoint
        "https://#{@login_endpoint}/services/Soap/u/#{@version}"
      end
    end
  end
end
