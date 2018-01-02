defmodule HelloCalendar.Calendar do
  require Logger

  defstruct [:start_time, :end_time, :repeat, :time_unit, :calendar]

  @valid_time_units ["minutely", "hourly", "daily", "weekly", "monthly", "yearly"]

  @doc """
  Start a new calendar
  * start_time - DataTime struct
  * end_time - DateTime struct
  * repeat - integer number of repeats
  * time_unit - one of
    * "minutely"
    * "hourly"
    * "daily"
    * "weekly"
    * "monthly"
    * "yearly"
  """
  def new(%DateTime{} = start_time, %DateTime{} = end_time, repeat, time_unit)
  when time_unit in @valid_time_units do
    %__MODULE__{
      start_time: start_time,
      end_time: end_time,
      repeat: repeat,
      time_unit: time_unit
    }
    |> build_calendar()
  end


  def build_calendar(%__MODULE__{} = calendar) do
    current_time_seconds = :os.system_time(:second)
    start_time_seconds = DateTime.to_unix(calendar.start_time, :seconds)
    end_time_seconds = DateTime.to_unix(calendar.end_time, :seconds)
    repeat = calendar.repeat
    repeat_frequency_seconds = time_unit_to_seconds(repeat, calendar.time_unit)

    new_calendar =
      do_build_calendar(current_time_seconds,
                        start_time_seconds,
                        end_time_seconds,
                        repeat,
                        repeat_frequency_seconds)
                        |> Enum.map(&DateTime.from_unix!(&1))
    %{calendar | calendar: new_calendar}
  end

  def do_build_calendar(now_seconds, start_time_seconds, end_time_seconds, repeat, repeat_frequency_seconds) do
    Logger.warn "Using (very) slow calendar builder!"
    grace_period_cutoff_seconds = now_seconds - 60
      Range.new(start_time_seconds, end_time_seconds)
      |> Enum.take_every(repeat * repeat_frequency_seconds)
      |> Enum.filter(&Kernel.>(&1, grace_period_cutoff_seconds))
      |> Enum.take(60)
      |> Enum.map(&Kernel.-(&1, div(&1, 60)))
  end

  @compile {:inline, [time_unit_to_seconds: 2]}
  defp time_unit_to_seconds(_, "never"), do: 0
  defp time_unit_to_seconds(repeat, "minutely"), do: 60 * repeat
  defp time_unit_to_seconds(repeat, "hourly"), do: 60 * 60 * repeat
  defp time_unit_to_seconds(repeat, "daily"), do: 60 * 60 * 24 * repeat
  defp time_unit_to_seconds(repeat, "weekly"), do: 60 * 60 * 24 * 7 * repeat
  defp time_unit_to_seconds(repeat, "monthly"), do: 60 * 60 * 24 * 30 * repeat
  defp time_unit_to_seconds(repeat, "yearly"), do: 60 * 60 * 24 * 365 * repeat

  @compile {:autoload, false}
  @on_load :load_nif
  def load_nif do
    nif_file = '#{:code.priv_dir(:hello_calendar)}/build_calendar'
    case :erlang.load_nif(nif_file, 0) do
      :ok -> :ok
      {:error, {:reload, _}} -> :ok
      {:error, reason} -> Logger.warn "Failed to load nif: #{inspect reason}"
    end
  end
end
