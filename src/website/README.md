Credit Rating based on Account data
===

Sinatra app for handling account data to generate a credit rating.

Prerequistes
---

Before deploying to Heroku, you need to generate key/IV for the encryption
of the credentials.

Generate a new cred key with:

    rake shell
    prompt> cipher = OpenSSL::Cipher::AES.new(128, :CBC)
    prompt> cipher.encrypt
    prompt> Base64.encode64(cipher.random_key) ## value for CRED_KEY_BASE64
    prompt> Base64.encode64(cipher.random_iv) ## value for CRED_IV_BASE64


Generating Private/Public key pair suitable for password encryption:

    openssl genrsa -out mykey.pem 2048
    openssl rsa -in mykey.pem -pubout > mykey.pub

Or using ruby:

    key = OpenSSL::PKey::RSA.generate(2048)
    key.export # private key
    key.public_key.export
