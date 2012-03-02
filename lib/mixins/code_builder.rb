module CodeBuilder
  def build_code(user, client)
    code = SecureRandom.hex(8)
    REDIS.set "code:#{code}",
      {user_id: user.id, client_id: 1}.to_json
    code
  end
end
