defmodule YouactTest do
  use ExUnit.Case
  # Temporarily disable doctests for now
  # doctest Youact

  alias Youact.{Activity, ActivityDetails}

  setup do
    # Mock is already created in test_helper.exs, just add cleanup
    on_exit(fn -> 
      # Don't unload since it's used by other tests
      :meck.reset(Youact.HttpClient)
    end)
    :ok
  end

  describe "get_channel_activities/1" do
    test "successfully retrieves channel activities" do
      # Mock successful API response
      mock_activities_response = File.read!("test/fixtures/sample_activities_response.json")
      :meck.expect(Youact.HttpClient, :get, fn _url -> {:ok, mock_activities_response} end)

      result = Youact.get_channel_activities("UC5_L-VbFcOOCp6xDCQB4Aog")
      
      assert {:ok, activities} = result
      assert is_list(activities)
      assert length(activities) > 0

      # Check the first activity
      activity = List.first(activities)
      assert %ActivityDetails{} = activity
      assert activity.channel_id == "UC5_L-VbFcOOCp6xDCQB4Aog"
      assert activity.activity_type in ["upload", "like", "playlistItem", "subscription"]
    end

    test "returns error for invalid channel ID" do
      # Mock 404 response
      :meck.expect(Youact.HttpClient, :get, fn _url -> {:error, :not_found} end)

      result = Youact.get_channel_activities("invalid_channel_id")
      
      assert {:error, :not_found} = result
    end

    test "gets data from cache if available" do
      # Mock cache hit
      mock_activities = [
        %ActivityDetails{
          id: "test_activity_id",
          channel_id: "test_channel_id",
          title: "Test Activity",
          description: "Test Description",
          published_at: "2023-01-01T00:00:00Z",
          thumbnail_url: "https://example.com/thumbnail.jpg",
          activity_type: "upload",
          video_id: "test_video_id",
          playlist_id: ""
        }
      ]

      # Start cache if not already started
      case Process.whereis(Youact.Cache) do
        nil -> {:ok, _pid} = Youact.Cache.start_link([])
        _pid -> :ok
      end
      Youact.Cache.put_channel_activities("test_channel_id", {:ok, mock_activities})

      # Get should fetch from cache not API
      result = Youact.get_channel_activities("test_channel_id")
      
      assert {:ok, activities} = result
      assert length(activities) == 1
      assert List.first(activities).id == "test_activity_id"
    end
  end

  describe "Activity module" do
    test "creates a new activity with channel ID" do
      activity = Activity.new("UC5_L-VbFcOOCp6xDCQB4Aog")
      
      assert %Activity{} = activity
      assert activity.channel_id == "UC5_L-VbFcOOCp6xDCQB4Aog"
    end
  end

  describe "ActivityDetails module" do
    test "formats date correctly" do
      activity = %ActivityDetails{
        id: "test_id",
        channel_id: "test_channel_id",
        title: "Test",
        description: "Test description",
        published_at: "2023-01-15T14:30:45Z",
        thumbnail_url: "",
        activity_type: "upload",
        video_id: "",
        playlist_id: ""
      }

      formatted_date = ActivityDetails.format_date(activity)
      assert formatted_date == "Jan 15, 2023"
    end
  end
end