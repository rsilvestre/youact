defmodule Youact.Activity do
  @moduledoc """
  A module that represents a YouTube channel activity request.
  """

  use Youact.Types
  use TypedStruct

  typedstruct enforce: true do
    field :channel_id, channel_id
  end

  @doc """
  Creates a new Activity struct with a channel ID.
  """
  @spec new(channel_id) :: __MODULE__.t()
  def new(channel_id) do
    %__MODULE__{
      channel_id: channel_id
    }
  end
end