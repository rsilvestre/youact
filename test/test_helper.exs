ExUnit.start()

# Set up a test API key for doctests
Application.put_env(:youact, :youtube_api_key, "TEST_API_KEY")

# Mock HTTP client for doctests
:meck.new(Youact.HttpClient, [:passthrough])

# We'll set up the mocks in individual tests instead of globally
# to avoid conflicts
