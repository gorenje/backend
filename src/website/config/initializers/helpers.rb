require 'jwe'
require 'digest/sha2'
require 'base64'

# if this crashes, then the RSA_PRIVATE_KEY isn't set correctly.
if ENV['RSA_PRIVATE_KEY_BASE64']
  OpenSSL::PKey::RSA.new(Base64.decode64(ENV['RSA_PRIVATE_KEY_BASE64']))
end
