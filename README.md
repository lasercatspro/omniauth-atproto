

# Omniauth-atproto

An omniauth strategy for Atproto (bluesky)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'omniauth-atproto'
```


## Usage

You can configure it :
```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider(:atproto,
    "#{Rails.application.config.app_url}/oauth/client-metadata.json",
    nil,
    client_options: {
        site: "https://bsky.social",
        authorize_url: "https://bsky.social/oauth/authorize",
        token_url: "https://bsky.social/oauth/token"
    },
    scope: "atproto transition:generic",
    private_key: OmniAuth::Atproto::KeyManager.current_private_key,
    client_jwk: OmniAuth::Atproto::KeyManager.current_jwk)
end
```
client_options are optional if you use handle resolution (see below).

You will have to generate keys and the oauth/client-metadata.json document (a generator should come soon).

```ruby
#lib/tasks/atproto.rake
:atproto do
  desc "Generate new AtProto key pair and rotate keys"
  task rotate_keys: :environment do
    OmniAuth::Atproto::KeyManager.rotate_keys
    puts "New key generated and saved. Old key backed up if it existed."
    Rake::Task["atproto:generate_metadata"].invoke
  end

  desc "Generate client metadata JSON file"
  task generate_metadata: :environment do
    metadata = {
      client_id: "#{Rails.application.config.app_url}/oauth/client-metadata.json",
      application_type: "web",
      client_name: Rails.application.class.module_parent_name,
      client_uri: Rails.application.config.app_url,
      dpop_bound_access_tokens: true,
      grant_types: %w[authorization_code refresh_token],
      redirect_uris: [ "#{Rails.application.config.app_url}/auth/atproto/callback" ],
      response_types: [ "code" ],
      scope: "atproto transition:generic",
      token_endpoint_auth_method: "private_key_jwt",
      token_endpoint_auth_signing_alg: "ES256",
      jwks: {
        keys: [ OmniAuth::Atproto::KeyManager.current_jwk ]
      }
    }

    oauth_dir = Rails.root.join("public", "oauth")
    FileUtils.mkdir_p(oauth_dir) unless Dir.exist?(oauth_dir)
    metadata_path = oauth_dir.join("client-metadata.json")
    File.write(metadata_path, JSON.pretty_generate(metadata))
    puts "Generated metadata file at #{metadata_path}"
  end
end
```
Then you can
```bash
rails atproto:generate_metadata
```
The values from the metadata endpoint should correspond to those you gave as option for the strategy (that's why a generator would be very handy).

All subsequent request made with the token should use the same private_key (with dpop), you might want to use https://github.com/lasercatspro/atproto-ruby.

The pds is going to request your app at oauth/client-metadata.json. For developement you will have to use some kind of proxy, like ngrok (there is a "development mode" in the spec but I didnt try it)

You can either set default client_options in the initializer, or keep it empty if you want to resolve the authorization server from the user handle. In this case you can add a handle param to the original omniauth request :

```erb
<%= form_tag('/auth/atproto', method: 'post', data: {turbo: false}) do %>
  <input name="handle" value="frabr.lasercats.fr"></input>
  <button type='submit'>Login with Atproto</button>
<% end %>
```

Here is the [documentation I tried to follow](https://atproto.com/specs/oauth)
