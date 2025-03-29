defmodule Youact.Types do
  @moduledoc false

  alias Youact.Activity
  alias Youact.ActivityDetails

  defmacro __using__(_opts) do
    quote do
      @type activity :: Activity.t()
      @type channel_id :: String.t()
      @type activity_id :: String.t()

      @type activity_details_found :: {:ok, list(ActivityDetails.t())}
      @type error :: {:error, :not_found} | {:error, String.t()}
    end
  end
end