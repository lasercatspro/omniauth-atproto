require 'omniauth-oauth2'
require 'json'
require 'net/http'
require 'atproto_client'
require 'didkit'
require 'faraday'

module OmniAuth
  module Strategies
    class Atproto < OmniAuth::Strategies::OAuth2
      option :fields, %i[handle]
      option :scope, 'atproto'
      option :pkce, true

      info do
        {
          did: @access_token.params['sub'],
          pds_host: options.client_options.site
        }
      end

      def self.setup
        lambda do |env|
          session = env["rack.session"]

          if env["rack.request.form_hash"] && handle = env["rack.request.form_hash"]["handle"]
            resolver = DIDKit::Resolver.new
            did = resolver.resolve_handle(handle)

            unless did
              env['omniauth.strategy'].fail!(:unknown_handle,
                OmniAuth::Error.new(
                  'Handle parameter did not resolve to a did'
                ))
            end

            endpoint = resolver.resolve_did(did).pds_endpoint
            auth_server = get_authorization_server(endpoint)
            session["authorization_info"] = authorization_info = get_authorization_data(auth_server)
          end
          
          if authorization_info ||= session.delete("authorization_info")
            env['omniauth.strategy'].options["client_options"]["site"] = authorization_info["issuer"]
            env['omniauth.strategy'].options["client_options"]["authorize_url"] = authorization_info['authorization_endpoint']
            env['omniauth.strategy'].options["client_options"]["token_url"] = authorization_info['token_endpoint']
          end
        end
      end

      option :setup, setup

      private

      def build_access_token
        response = AtProto::Client.new(private_key: options.private_key).get_token!(
          **token_params.merge({
                                 code: request.params['code'],
                                 jwk: options.client_jwk,
                                 client_id: options.client_id,
                                 redirect_uri: full_host + callback_path,
                                 site: options.client_options.site,
                                 endpoint: options.client_options.token_url
                               }).to_h.symbolize_keys
        )
        ::OAuth2::AccessToken.from_hash(client, response)
      end

      def self.get_authorization_server(pds_endpoint)
        response = Faraday.get("#{pds_endpoint}/.well-known/oauth-protected-resource")

        unless response.success?
          fail!(:invalid_auth_server,
                OmniAuth::Error.new(
                  "Failed to get PDS authorization server: #{response.status}"
                ))
        end

        result = JSON.parse(response.body)

        auth_server = result.dig('authorization_servers', 0)
        unless auth_server
          fail!(:invalid_auth_server,
                OmniAuth::Error.new('No authorization server found in response'))
        end
        auth_server
      end

      def self.get_authorization_data(issuer)
        response = Faraday.get("#{issuer}/.well-known/oauth-authorization-server")

        unless response.success?
          fail!(:invalid_metadata,
                OmniAuth::Error.new(
                  "Failed to get authorization server metadata: #{response.status}"
                ))
        end
        result = JSON.parse(response.body)

        unless result['issuer'] == issuer
          fail!(:invalid_metadata,
                OmniAuth::Error.new('Invalid metadata - issuer mismatch'))
        end
        # we cannot keep everything in session (cookie overflow error)
        fields = %w[issuer authorization_endpoint token_endpoint]
        result.select { |k, _v| fields.include?(k) }
      end
    end
  end
end
