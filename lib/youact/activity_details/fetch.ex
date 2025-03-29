defmodule Youact.ActivityDetails.Fetch do
  @moduledoc false

  use Youact.Types

  alias Youact.HttpClient
  alias Youact.ActivityDetails
  # alias Youact.Activity - unused

  @youtube_activities_api_url "https://content-youtube.googleapis.com/youtube/v3/activities"
  @activities_api_parts "snippet,contentDetails"

  @spec channel_activities(activity) :: {:ok, list(ActivityDetails.t())} | error
  def channel_activities(activity) do
    activity.channel_id
    |> build_activities_api_url()
    |> fetch_from_api()
    |> parse_response()
  end

  defp build_activities_api_url(channel_id) do
    api_key = get_api_key()
    "#{@youtube_activities_api_url}?channelId=#{channel_id}&part=#{@activities_api_parts}&key=#{api_key}"
  end

  defp get_api_key do
    System.get_env("YOUTUBE_API_KEY") ||
      Application.get_env(:youact, :youtube_api_key) ||
      raise "YouTube API key not found. Please set the YOUTUBE_API_KEY environment variable or configure it in your application config."
  end

  defp fetch_from_api(url) do
    HttpClient.get(url)
  end

  defp parse_response({:ok, json_body}) do
    case Poison.decode(json_body) do
      {:ok, %{"items" => items}} when is_list(items) and length(items) > 0 ->
        activities = Enum.map(items, &ActivityDetails.new/1)
        {:ok, activities}

      {:ok, %{"items" => []}} ->
        {:ok, []}

      {:ok, %{"error" => %{"message" => message}}} ->
        {:error, message}

      {:error, _} ->
        {:error, :parse_error}

      _ ->
        {:error, :unknown_error}
    end
  end

  defp parse_response({:error, reason}), do: {:error, reason}
end