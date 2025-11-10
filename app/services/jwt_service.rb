class JwtService
  SECRET_KEY = Rails.application.credentials.secret_key_base || "development_secret_key"

  def self.encode(payload)
    # Support both user object and hash payload
    if payload.is_a?(User)
      token_payload = {
        user_id: payload.id,
        exp: 15.minutes.from_now.to_i
      }
    else
      token_payload = payload.merge(exp: 15.minutes.from_now.to_i)
    end

    JWT.encode(token_payload, SECRET_KEY, "HS256")
  end

  def self.decode(token)
    decoded = JWT.decode(token, SECRET_KEY, true, { algorithm: "HS256" })
    decoded[0].symbolize_keys
  rescue JWT::DecodeError => e
    Rails.logger.error "JWT decode error: #{e.message}"
    raise JWT::DecodeError, e.message
  end
end
