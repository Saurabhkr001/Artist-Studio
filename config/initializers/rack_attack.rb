class Rack::Attack
  # 1. Block suspicious requests for PHP files or generic vulnerabilities
  blocklist('block known malicious requests') do |req|
    req.path.include?('.php') || req.path.include?('wp-admin')
  end

  # 2. Throttle all requests by IP (60 requests per minute max)
  throttle('req/ip', limit: 60, period: 1.minute) do |req|
    req.ip
  end

  # 3. Throttle login attempts by email address (5 attempts per 20 seconds)
  throttle('logins/email', limit: 5, period: 20.seconds) do |req|
    if req.path == '/users/sign_in' && req.post?
      req.params.dig('user', 'email').to_s.downcase.gsub(/\s+/, "")
    end
  end

  # 4. Throttle public enquiries by IP (3 attempts per minute)
  throttle('enquiries/ip', limit: 3, period: 1.minute) do |req|
    if req.path.end_with?('/enquire') && req.post?
      req.ip
    end
  end

  # Respond with a simple 429 Too Many Requests
  self.throttled_responder = lambda do |env|
    [ 429,  # status
      { 'Content-Type' => 'text/plain' }, # headers
      ["Too Many Requests. Please slow down.\n"] # body
    ]
  end
end
