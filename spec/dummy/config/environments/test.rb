Dummy::Application.configure do
  config.cache_classes = true
  config.consider_all_requests_local = true
  config.log_level = :debug
  config.threadsafe!

  config.active_support.deprecation = :stderr
end
