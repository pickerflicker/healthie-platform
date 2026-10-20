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
    case held do
      [issue] when issue.state in ["In Review", "Blocked"] ->
        hold(issue, slot)

      [issue] ->
        resume(candidates, issue, slot)

      [] ->
        case Enum.find(candidates, &(dispatchable?(&1) and ready?(&1))) do
          nil -> {:ok, []}
          issue -> claim(candidates, issue, slot)
        end

      _ ->
        {:error, :multiple_project_owners}
    end
  end

  defp select(candidates, held, owner, slot) do
    with {:ok, issues} <- Client.fetch_issue_states_by_ids([owner]) do
      case issues do
        [%{state: "Done"}] ->
          File.rm!(slot)

          select(
            Enum.reject(candidates, &(&1.id == owner)),
            Enum.reject(held, &(&1.id == owner)),
            nil,
            slot
          )

        [%{state: state} = issue] when state in ["Todo", "In Progress"] ->
          if Enum.any?(held, &(&1.id != owner)),
            do: {:error, :multiple_project_owners},
            else: claim(candidates, issue, slot)

        [%{state: state}] when state in ["In Review", "Blocked"] ->
          if Enum.any?(held, &(&1.id != owner)),
            do: {:error, :multiple_project_owners},
            else: {:ok, []}

        _ -> {:ok, []}
      end
    end
  end

  defp claim(candidates, issue, slot) do
    if dispatchable?(issue) and ready?(issue) do
      with :ok <- persist_owner(slot, issue.id) do
        {:ok, Enum.filter(candidates, &(&1.id == issue.id))}
      end
    else
      {:ok, []}
    end
  end

  defp resume(candidates, issue, slot) do
    with :ok <- persist_owner(slot, issue.id) do
      if dispatchable?(issue) and ready?(issue),
        do: {:ok, Enum.filter(candidates, &(&1.id == issue.id))},
        else: {:ok, []}
    end
  end

  defp hold(issue, slot) do
    with :ok <- persist_owner(slot, issue.id), do: {:ok, []}
  end

  defp persist_owner(slot, issue_id) do
    case File.open(slot, [:write, :exclusive]) do
      {:ok, file} ->
        result = IO.write(file, issue_id <> "\n")
        File.close(file)
        result

      {:error, :eexist} ->
        case File.read(slot) do
          {:ok, existing} ->
            if String.trim(existing) == issue_id,
              do: :ok,
              else: {:error, :owner_claim_race}

          {:error, reason} -> {:error, {:owner_read_failed, reason}}
        end

      {:error, reason} ->
        {:error, {:owner_write_failed, reason}}
    end
  end

  defp dispatchable?(issue), do: issue.state in ["Todo", "In Progress"]
  defp ready?(issue), do: Enum.all?(issue.blocked_by, &(&1.state == "Done"))
end
