defmodule Youact.Cache do
  @moduledoc """
  Provides caching functionality for YouTube channel activities data to reduce API calls to YouTube.

  This module uses YouCache internally while maintaining the original API.
  """

  use YouCache,
    registries: [:channel_activities]

  use Youact.Types

  alias Youact.ActivityDetails

  # Default TTL of 1 day in milliseconds
  @default_ttl 86_400_000

  # Public API

  @doc """
  Gets channel activities from cache or returns nil if not found.
  """
  @spec get_channel_activities(channel_id) :: {:ok, list(ActivityDetails.t())} | {:miss, nil} | {:error, term()}
  def get_channel_activities(channel_id) do
    get(:channel_activities, channel_id)
  end

  @doc """
  Caches channel activities for a channel ID.
  """
  @spec put_channel_activities(channel_id, {:ok, list(ActivityDetails.t())}) :: {:ok, list(ActivityDetails.t())}
  def put_channel_activities(channel_id, {:ok, activities} = data) do
    ttl = get_ttl()
    # Store just the activities, not the full {:ok, activities} tuple
    put(:channel_activities, channel_id, activities, ttl)
    data
  end

  # Helper function to maintain original behavior
  defp get_ttl do
    Application.get_env(:youact, :cache_ttl, @default_ttl)
  end
end