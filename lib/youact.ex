defmodule Youact do
  @moduledoc """
  Main module with functions to retrieve YouTube channel activities.
  """

  use Youact.Types

  alias Youact.{Cache, Activity, ActivityDetails}
  alias Youact.ActivityDetails.Fetch, as: ActivityDetailsFetch

  @doc """
  Starts the Youact application with caching enabled.
  Call this function when you want to use caching outside
  of a supervision tree.

  ## Options

  * `:backends` - A map of cache backend configurations (optional)
  * `:ttl` - Cache TTL in milliseconds (optional)

  ## Examples

      # Start with default memory backend
      Youact.start()

      # Start with custom configuration
      Youact.start(backends: %{
        activity_details: %{
          backend: Youact.Cache.DiskBackend,
          backend_options: [cache_dir: "my_cache_dir"]
        }
      })
  """
  def start(opts \\ []) do
    # If specific backends are provided, update application env
    if backend_config = Keyword.get(opts, :backends) do
      Application.put_env(:youact, :cache_backends, backend_config)
    end

    # If TTL is provided, update application env
    if ttl = Keyword.get(opts, :ttl) do
      Application.put_env(:youact, :cache_ttl, ttl)
    end

    Cache.start_link(Keyword.get(opts, :cache_opts, []))
  end

  @doc """
  Get activities for a YouTube channel by channel ID.
  
  Returns a list of activity results with information including:
  - activity_id
  - title
  - description
  - published_at
  - thumbnail_url
  - activity_type
  
  ## Examples
  
      iex> alias Youact.ActivityDetails
      iex> Youact.get_channel_activities("UC5_L-VbFcOOCp6xDCQB4Aog")
      {:ok, [
        %ActivityDetails{
          id: "MTIzNDU2Nzg5MDEyMzQ1Njc4OTAxMjM0NTY3",
          channel_id: "UC5_L-VbFcOOCp6xDCQB4Aog",
          title: "New Video Title",
          description: "Description of the activity...",
          published_at: "2023-01-15T14:30:45Z",
          thumbnail_url: "https://i.ytimg.com/...",
          activity_type: "upload",
          video_id: "video123",
          playlist_id: ""
        }
      ]}
  """
  @spec get_channel_activities(channel_id) :: {:ok, list(ActivityDetails.t())} | error
  def get_channel_activities(channel_id) do
    case use_cache?() && Cache.get_channel_activities(channel_id) do
      {:miss, nil} ->
        # Not in cache, fetch and cache it
        fetch_and_cache_channel_activities(channel_id)

      {:ok, result} ->
        {:ok, result}

      {:error, _reason} = error ->
        error

      _other ->
        # Fallback for unexpected responses
        fetch_and_cache_channel_activities(channel_id)
    end
  end

  defp fetch_and_cache_channel_activities(channel_id) do
    result =
      channel_id
      |> Activity.new()
      |> ActivityDetailsFetch.channel_activities()

    case result do
      {:ok, _} = ok_result ->
        if use_cache?(), do: Cache.put_channel_activities(channel_id, ok_result)
        ok_result

      error ->
        error
    end
  end

  @doc """
  Gets activities for a YouTube channel.
  Like `get_channel_activities/1` but raises an exception on error.
  """
  @spec get_channel_activities!(channel_id) :: list(ActivityDetails.t())
  def get_channel_activities!(channel_id) do
    case get_channel_activities(channel_id) do
      {:ok, activities} -> activities
      {:error, reason} -> raise RuntimeError, message: to_string(reason)
    end
  end

  @doc """
  Clears all cached data including channel activities.
  """
  def clear_cache do
    if use_cache?() do
      Cache.clear()
    else
      {:error, :cache_not_started}
    end
  end

  @doc """
  Checks if caching is enabled.
  """
  def use_cache? do
    case Process.whereis(Cache) do
      nil -> false
      _pid -> true
    end
  end
end