defmodule SymphonyElixir.ProjectGate do
  @moduledoc "Persistent project dispatch ownership; tracker/file failures close the gate."
  alias SymphonyElixir.Linear.Client

  def filter(candidates) do
    root = System.fetch_env!("HEALTHIE_GATE_ROOT")
    File.mkdir_p!(root)
    slot = Path.join(root, "owner")
    if File.exists?(Path.join(root, "paused")) do
      {:ok, []}
    else
      with {:ok, held} <- Client.fetch_issues_by_states(["In Review", "Blocked", "In Progress"]) do
        owner = case File.read(slot) do
          {:ok, id} -> String.trim(id)
          {:error, :enoent} -> nil
          {:error, reason} -> raise "Cannot read project owner: #{inspect(reason)}"
        end
        select(candidates, held, owner, slot)
      end
    end
  end

  defp select(candidates, held, nil, slot) do
    cond do
      Enum.any?(held, &(&1.state in ["In Review", "Blocked"])) -> {:ok, []}
      length(held) > 1 -> {:error, :multiple_project_owners}
      held != [] -> claim(candidates, hd(held), slot)
      true ->
        case Enum.find(candidates, &ready?/1) do
          nil -> {:ok, []}
          issue -> claim(candidates, issue, slot)
        end
    end
  end

  defp select(candidates, held, owner, slot) do
    with {:ok, issues} <- Client.fetch_issue_states_by_ids([owner]) do
      case issues do
        [%{state: "Done"}] ->
          File.rm!(slot)
          select(candidates, held, nil, slot)
        [%{state: state} = issue] when state in ["Todo", "In Progress"] ->
          if Enum.any?(held, &(&1.id != owner)), do: {:ok, []}, else: claim(candidates, issue, slot)
        _ -> {:ok, []}
      end
    end
  end

  defp claim(candidates, issue, slot) do
    if ready?(issue) do
      File.write!(slot <> ".new", issue.id <> "\n")
      File.rename!(slot <> ".new", slot)
      {:ok, Enum.filter(candidates, &(&1.id == issue.id))}
    else
      {:ok, []}
    end
  end

  defp ready?(issue), do: Enum.all?(issue.blocked_by, &(&1.state == "Done"))
end
