# Youact

A tool to retrieve channel activities from YouTube. Youact allows you to easily fetch channel activities (uploads, likes, playlist additions, etc.) from YouTube using the official YouTube Data API.

## Installation

Add `youact` to the list of dependencies inside `mix.exs`:

```elixir
def deps do
  [
    {:youact, "~> 0.1.0"}
  ]
end
```

This package requires Elixir 1.15 or later and has the following dependencies:
- poison ~> 6.0 (JSON parsing)
- httpoison ~> 2.2 (HTTP client)
- typed_struct ~> 0.3 (Type definitions)
- nimble_options ~> 1.0 (Option validation)

## YouTube API Key Setup

Youact uses the official YouTube Data API to fetch channel activities. You'll need to obtain an API key from the Google Cloud Console by following these steps:

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the "YouTube Data API v3" for your project
4. Create an API key in the "Credentials" section
5. Set up the API key in one of the following ways:

### Environment Variable (recommended)

```bash
export YOUTUBE_API_KEY=your_api_key_here
```

### Application Configuration

```elixir
# In config/config.exs
config :youact, 
  youtube_api_key: "your_api_key_here"
```

**Note**: Be careful not to commit your API key to version control. Consider using environment variables or a secrets management solution in production.

## Usage

### Get Channel Activities

**Youact.get_channel_activities(channel_id)**

Retrieves activities from a YouTube channel by channel ID.

```elixir
Youact.get_channel_activities("UC5_L-VbFcOOCp6xDCQB4Aog")

{:ok, [
  %Youact.ActivityDetails{
    id: "MTIzNDU2Nzg5MDEyMzQ1Njc4OTAxMjM0NTY3",
    channel_id: "UC5_L-VbFcOOCp6xDCQB4Aog",
    title: "New Video Title",
    description: "Description of the activity...",
    published_at: "2023-01-15T14:30:45Z",
    thumbnail_url: "https://i.ytimg.com/...",
    activity_type: "upload",
    video_id: "dQw4w9WgXcQ",
    playlist_id: ""
  },
  # ...more results
]}
```

### Error Handling

All functions return either:
- `{:ok, result}` for successful operations
- `{:error, reason}` when something goes wrong (typically `:not_found`)

### Bang Functions

If you don't need to pattern match `{:ok, data}` and `{:error, reason}`, there is also a trailing bang version that raises an exception on error:

```elixir
# Returns the activities directly or raises an exception
activities = Youact.get_channel_activities!("UC5_L-VbFcOOCp6xDCQB4Aog")
```

## Formatting Helpers

Youact provides helper functions for formatting activity data:

```elixir
# Format date
Youact.ActivityDetails.format_date(activity) # => "Jun 24, 2014"
```

## Caching

Youact includes a flexible caching mechanism to improve performance and reduce API calls to YouTube.
The cache system supports multiple backend options:

- **Memory**: In-memory cache using ETS tables (default, fast but not persistent)
- **Disk**: Persistent local storage using DETS (survives application restarts)
- **S3**: Cloud storage using AWS S3 (survives restarts and shareable across instances)
- **Cachex**: Distributed caching using Cachex (supports horizontal scaling across multiple nodes)

### Using Caching

If using Youact as an application (included in your supervision tree), caching is automatically enabled. Otherwise, you need to manually start the cache:

```elixir
# Start cache
Youact.start()
```

### Cache Configuration

You can configure cache behavior in your config:

```elixir
# In config/config.exs
config :youact, 
  # General cache settings
  cache_ttl: 86_400_000,                    # TTL (time-to-live) - 1 day in milliseconds (default)
  cache_cleanup_interval: 3_600_000,        # Cleanup interval - every hour (default)
  
  # Configure which backend to use for the activities cache
  cache_backends: %{
    # Memory backend (default)
    channel_activities: %{
      backend: Youact.Cache.MemoryBackend,
      backend_options: [
        table_name: :channel_activities_cache,
        max_size: 1000                      # Max entries in memory
      ]
    }
  }
```

### Cache Operations

```elixir
# Check if cache is enabled
Youact.use_cache?()

# Clear cache
Youact.clear_cache()
```

When caching is enabled, activities are stored with a TTL (time-to-live). The cache is automatically cleaned up periodically to prevent storage issues.

## Data Structure

### Youact.ActivityDetails

The activity details structure containing:
- `id`: Activity ID
- `channel_id`: YouTube channel ID
- `title`: Activity title
- `description`: Activity description
- `published_at`: Activity publication date (ISO 8601 format)
- `thumbnail_url`: URL to the activity thumbnail image
- `activity_type`: Type of activity (upload, like, playlistItem, etc.)
- `video_id`: ID of the video (if applicable)
- `playlist_id`: ID of the playlist (if applicable)

**Helper Functions:**
- `format_date/1`: Formats ISO date as human-readable text

## Examples

### Displaying Channel Activities

```elixir
defmodule ActivityProcessor do
  def print_activities(channel_id) do
    case Youact.get_channel_activities(channel_id) do
      {:ok, activities} ->
        activities_summary = activities
          |> Enum.take(5)
          |> Enum.map_join("\n\n", &format_activity/1)
          
        """
        Channel Activities (#{length(activities)} total):
        #{activities_summary}
        """
      
      {:error, reason} -> 
        "Error: #{reason}"
    end
  end
  
  defp format_activity(activity) do
    icon = case activity.activity_type do
      "upload" -> "📹"
      "like" -> "👍"
      "playlistItem" -> "🎬"
      "subscription" -> "📢"
      _ -> "🔔"
    end
    
    """
    #{icon} #{activity.title} (#{Youact.ActivityDetails.format_date(activity)})
    Type: #{activity.activity_type}
    #{if activity.video_id != "", do: "Video ID: #{activity.video_id}", else: ""}
    #{if activity.description != "", do: String.slice(activity.description, 0, 100) <> if(String.length(activity.description) > 100, do: "...", else: ""), else: ""}
    """
  end
end

# Usage:
summary = ActivityProcessor.print_activities("UCt8Nz7iFr4d6F9UrpiUbGwg")
IO.puts(summary)

# Output:
# Channel Activities (42 total):
# 📹 New Video Title (Jan 15, 2023)
# Type: upload
# Video ID: dQw4w9WgXcQ
# Check out this awesome new content that I've created...
# 
# 👍 Great Tutorial Video (Jan 12, 2023)
# Type: like
# Video ID: xyzABC123
# This is a video I liked about programming
```

## License

MIT License