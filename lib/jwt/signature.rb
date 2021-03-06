# frozen_string_literal: true

require 'jwt/security_utils'
require 'openssl'
require 'jwt/algos/hmac'
require 'jwt/algos/eddsa'
require 'jwt/algos/ecdsa'
require 'jwt/algos/rsa'
require 'jwt/algos/ps'
require 'jwt/algos/unsupported'
begin
  require 'rbnacl'
rescue LoadError
  raise if defined?(RbNaCl)
end

# JWT::Signature module
module JWT
  # Signature logic for JWT
  module Signature
    extend self
    ALGOS = [
      Algos::Hmac,
      Algos::Ecdsa,
      Algos::Rsa,
      Algos::Eddsa,
      Algos::Ps,
      Algos::Unsupported
    ].freeze
    ToSign = Struct.new(:algorithm, :msg, :key)
    ToVerify = Struct.new(:algorithm, :public_key, :signing_input, :signature)

    def sign(algorithm, msg, key)
      algo = ALGOS.find do |alg|
        alg.const_get(:SUPPORTED).include? algorithm
      end
      s = algo.sign(ToSign.new(algorithm, msg, key))
      puts "Signed: algo: #{algorithm}, msg: #{msg}, key: #{key}, signature: #{JWT::Base64.url_encode(s)}"
      s
    end

    def verify(algorithm, key, signing_input, signature)
      return true if algorithm == 'none'

      raise JWT::DecodeError, 'No verification key available' unless key

      algo = ALGOS.find do |alg|
        alg.const_get(:SUPPORTED).include? algorithm
      end
      to_verify = ToVerify.new(algorithm, key, signing_input, signature)
      verified = algo.verify(to_verify)
      raise(JWT::VerificationError, "Signature verification raised algo: #{to_verify.algorithm}, msg: #{to_verify.signing_input}, key: #{to_verify.public_key}, signature: #{to_verify.signature}") unless verified
    rescue OpenSSL::PKey::PKeyError
      raise JWT::VerificationError, "Signature verification raised algo: #{to_verify.algorithm}, msg: #{to_verify.signing_input}, key: #{to_verify.public_key}, signature: #{to_verify.signature}"
    ensure
      OpenSSL.errors.clear
    end
  end
end
