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

      attr_accessor :client

      def configure(conf)
        super
      end

      def start
        super
        @client = generate_client

        if @topic == nil
          start_at = now
          loop do
            sleep(@polling_interval)
            end_at = now
            soql = build_query(start_at, end_at)

            begin
              log.info "query: #{soql}"
              records = exec_query(soql)
              records.each do |record|
                router.emit(@tag, Fluent::Engine.now, record)
              end
              start_at = end_at
            rescue Restforce::UnauthorizedError => e
              log.error e
              # retry login
              @client = generate_client
            end
          end
        else
          EM.run do
            log.info "suscribe: #{@topic}"
            subscribe @topic do |message|
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
        request = Net::HTTP::Post.new(uri.request_uri, {'Content-Type' =>'text/xml', 'SOAPAction' => "''"})
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
          m = /^(https:\/\/.+\.salesforce\.com)\//.match(doc.css('serverUrl').inner_text)
          instance_url = m[1]
          log.info "login is successful. instance_url = '#{instance_url}'"

          {oauth_token: session_id, instance_url: instance_url}
        end
      end

      def login_endpoint
        "https://#{@login_endpoint}/services/Soap/u/#{@version}"
      end

      def build_query(start_at, end_at)
        where = "CreatedDate <= #{end_at} AND CreatedDate > #{start_at}"
        if m = /^(.+)\s(where|WHERE)\s(.+)$/.match(@query)
          return "#{m[1]} WHERE #{where} AND #{m[3]}"
        end

        "#{@query} WHERE #{where}"
      end

      def generate_client
        login_info = login
        Restforce.new login_info.merge(api_version: @version)
      end

      def exec_query(soql)
        @client.query(soql)
      end

      def subscribe(name, &block)
        @client.subscribe(name, &block)
      end

      def now
        DateTime.now.strftime('%Y-%m-%dT%H:%M:%S.000%Z')
      end
    end
  end
end
