defmodule Youact.CacheTest do
  use ExUnit.Case
  alias Youact.{Cache, ActivityDetails}

  setup do
    # Start cache for testing or use existing
    case Process.whereis(Cache) do
      nil ->
        # Choose backend based on available dependencies (MemoryBackend or CachexBackend)
        backend =
          if Code.ensure_loaded?(Cachex) do
            Youact.Cache.CachexBackend
          else
            Youact.Cache.MemoryBackend
          end

        opts = [
          backends: %{
            channel_activities: %{
              backend: backend,
              backend_options: [table_name: :test_channel_activities]
            }
          }
        ]

        {:ok, _pid} = Cache.start_link(opts)

      _pid ->
        :ok
    end

    # Clear cache before each test
    Cache.clear()

    # Pass the backend type used to tests
    backend_type =
      if Code.ensure_loaded?(Cachex) do
        :cachex
      else
        :memory
      end

    {:ok, %{backend_type: backend_type}}
  end

  test "caches and retrieves channel activities" do
    channel_id = "UC123456789"

    activities = [
      %ActivityDetails{
        id: "test_activity_id",
        channel_id: channel_id,
        title: "Test Activity",
        description: "This is a test description",
        published_at: "2023-01-01T12:00:00Z",
        thumbnail_url: "https://example.com/thumb.jpg",
        activity_type: "upload",
        video_id: "test_video_id",
        playlist_id: ""
      }
    ]

    # Cache the activities
    Cache.put_channel_activities(channel_id, {:ok, activities})

    # Retrieve from cache
    case Cache.get_channel_activities(channel_id) do
      {:ok, cached_activities} ->
        assert cached_activities == activities

      other ->
        flunk("Expected {:ok, activities}, got: #{inspect(other)}")
    end
  end

  test "returns {:miss, nil} for non-existent items" do
    assert Cache.get_channel_activities("non_existent_id") == {:miss, nil}
  end

  test "clear removes all cached items" do
    channel_id = "UC123456789"

    activities = [
      %ActivityDetails{
        id: "test_activity_id",
        channel_id: channel_id,
        title: "Test Activity",
        description: "This is a test description",
        published_at: "2023-01-01T12:00:00Z",
        thumbnail_url: "https://example.com/thumb.jpg",
        activity_type: "upload",
        video_id: "test_video_id",
        playlist_id: ""
      }
    ]

    Cache.put_channel_activities(channel_id, {:ok, activities})

    # Verify cache has the item
    case Cache.get_channel_activities(channel_id) do
      {:ok, cached_activities} ->
        assert cached_activities == activities

      other ->
        flunk("Expected {:ok, activities}, got: #{inspect(other)}")
    end

    # Clear cache
    Cache.clear()

    # Verify item is gone
    assert Cache.get_channel_activities(channel_id) == {:miss, nil}
  end

  @tag :cachex
  test "runs with Cachex backend if available", %{backend_type: backend_type} do
    # Skip if Cachex is not available
    if backend_type != :cachex do
      # Just return early from the test if Cachex isn't available
      IO.puts("Skipping Cachex test - Cachex not available")
      assert true
    else
      # This test verifies that the code can run using the Cachex backend
      # by storing and retrieving a value
      channel_id = "cachex_test_channel"

      activities = [
        %ActivityDetails{
          id: "test_activity_id",
          channel_id: channel_id,
          title: "Test Activity",
          description: "This is a test description",
          published_at: "2023-01-01T12:00:00Z",
          thumbnail_url: "https://example.com/thumb.jpg",
          activity_type: "upload",
          video_id: "test_video_id",
          playlist_id: ""
        }
      ]

      # Cache the activities
      Cache.put_channel_activities(channel_id, {:ok, activities})

      # Retrieve from cache
      case Cache.get_channel_activities(channel_id) do
        {:ok, cached_activities} ->
          assert cached_activities == activities

        other ->
          flunk("Expected {:ok, activities}, got: #{inspect(other)}")
      end
    end
  end
end