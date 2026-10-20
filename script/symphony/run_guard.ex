defmodule SymphonyElixir.RunGuard do
  @moduledoc "Classify completed turns and bound automatic recovery without losing ticket ownership."

  def completion_result(payload) do
    case get_in(payload, ["params", "turn", "status"]) do
      status when status in [nil, "completed"] -> {:ok, :turn_completed}
      status -> {:error, {:turn_failed, %{status: status}}}
    end
  end

  def begin_attempt(id) do
    with_root(fn root ->
      file = failure_file(root, id) <> ".attempts"
      count = case File.read(file) do
        {:ok, value} -> String.to_integer(String.trim(value))
        {:error, :enoent} -> 0
      end
      if count >= 2 do
        checkpoint(root, id, "automatic_attempt_budget_exhausted")
        {:error, :automatic_attempt_budget_exhausted}
      else
        File.write!(file, Integer.to_string(count + 1))
        :ok
      end
    end)
  end

  def record_success(id) do
    with_root(fn root ->
      File.rm(failure_file(root, id))
      File.rm(failure_file(root, id) <> ".attempts")
      :ok
    end)
  end

  def record_failure(id) do
    with_root(fn root ->
      file = failure_file(root, id)
      count = case File.read(file) do
        {:ok, value} -> String.to_integer(String.trim(value))
        {:error, :enoent} -> 0
      end
      File.write!(file <> ".new", Integer.to_string(count + 1))
      File.rename!(file <> ".new", file)
      if count + 1 >= 2, do: checkpoint(root, id, "two_consecutive_worker_failures")
      :ok
    end)
  end

  def turn_limit(id), do: with_root(&checkpoint(&1, id, "continuation_turn_limit"))

  defp checkpoint(root, id, reason) do
    File.write!(Path.join(root, "checkpoint.json"), Jason.encode!(%{issue_id: id, reason: reason}))
    File.write!(Path.join(root, "paused"), "operator checkpoint required\n")
    :ok
  end

  defp failure_file(root, id), do: Path.join(root, "failures-" <> Base.url_encode64(id, padding: false))

  defp with_root(fun) do
    case System.get_env("HEALTHIE_GATE_ROOT") do
      nil -> :ok
      root -> File.mkdir_p!(root); fun.(root)
    end
  end
end
