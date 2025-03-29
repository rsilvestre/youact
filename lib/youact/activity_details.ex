defmodule Youact.ActivityDetails do
  @moduledoc """
  Module representing details of a YouTube channel activity.

  This module provides a struct and functions for working with YouTube channel activity metadata
  retrieved from the YouTube Data API.
  """

  use Youact.Types
  use TypedStruct

  typedstruct enforce: true do
    field :id, activity_id
    field :channel_id, channel_id
    field :title, String.t()
    field :description, String.t(), default: ""
    field :published_at, String.t()
    field :thumbnail_url, String.t(), default: ""
    field :activity_type, String.t()
    field :video_id, String.t(), default: ""
    field :playlist_id, String.t(), default: ""
  end

  @doc """
  Creates a new ActivityDetails struct from the parsed activity details JSON.

  This function handles mapping from the YouTube Data API response
  to a consistently structured ActivityDetails struct.
  """
  def new(activity_details) do
    snippet = Map.get(activity_details, "snippet", %{})
    content_details = Map.get(activity_details, "contentDetails", %{})
    
    activity_type = determine_activity_type(content_details)
    
    %__MODULE__{
      id: Map.get(activity_details, "id", ""),
      channel_id: Map.get(snippet, "channelId", ""),
      title: Map.get(snippet, "title", ""),
      description: Map.get(snippet, "description", ""),
      published_at: Map.get(snippet, "publishedAt", ""),
      thumbnail_url: get_thumbnail_url(snippet),
      activity_type: activity_type,
      video_id: get_video_id(content_details, activity_type),
      playlist_id: get_playlist_id(content_details, activity_type)
    }
  end

  @doc """
  Formats the publish date in a more readable format.

  ## Example

      iex> activity = %Youact.ActivityDetails{published_at: "2023-01-15T14:30:45Z"}
      iex> Youact.ActivityDetails.format_date(activity)
      "Jan 15, 2023"
  """
  def format_date(%__MODULE__{published_at: date_string}) do
    case DateTime.from_iso8601(date_string) do
      {:ok, date_time, _} ->
        Calendar.strftime(date_time, "%b %d, %Y")

      _ ->
        date_string
    end
  end

  # Private helper functions

  defp get_thumbnail_url(snippet) do
    case Map.get(snippet, "thumbnails", %{}) do
      %{"high" => %{"url" => url}} -> url
      %{"medium" => %{"url" => url}} -> url
      %{"default" => %{"url" => url}} -> url
      _ -> ""
    end
  end
  
  defp determine_activity_type(content_details) do
    cond do
      Map.has_key?(content_details, "upload") -> "upload"
      Map.has_key?(content_details, "playlistItem") -> "playlistItem"
      Map.has_key?(content_details, "like") -> "like"
      Map.has_key?(content_details, "favorite") -> "favorite"
      Map.has_key?(content_details, "comment") -> "comment"
      Map.has_key?(content_details, "subscription") -> "subscription"
      Map.has_key?(content_details, "recommendation") -> "recommendation"
      Map.has_key?(content_details, "social") -> "social"
      Map.has_key?(content_details, "channelItem") -> "channelItem"
      true -> "unknown"
    end
  end
  
  defp get_video_id(content_details, activity_type) do
    case activity_type do
      "upload" -> get_in(content_details, ["upload", "videoId"]) || ""
      "playlistItem" -> get_in(content_details, ["playlistItem", "resourceId", "videoId"]) || ""
      "like" -> get_in(content_details, ["like", "resourceId", "videoId"]) || ""
      _ -> ""
    end
  end
  
  defp get_playlist_id(content_details, activity_type) do
    case activity_type do
      "playlistItem" -> get_in(content_details, ["playlistItem", "playlistId"]) || ""
      "channelItem" -> get_in(content_details, ["channelItem", "playlistId"]) || ""
      _ -> ""
    end
  end
end