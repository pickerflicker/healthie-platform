ExUnit.start()
defmodule SymphonyElixir.Linear.Client do
  def fetch_issues_by_states(_), do: Agent.get(:fixtures, & &1.held_result)
  def fetch_issue_states_by_ids(_), do: Agent.get(:fixtures, & &1.owner_result)
end
Code.require_file("project_gate.ex", __DIR__)
defmodule ProjectGateTest do
  use ExUnit.Case, async: false
  alias SymphonyElixir.ProjectGate
  setup do
    root = Path.join(System.tmp_dir!(), "healthie-gate-test-#{System.unique_integer([:positive])}")
    File.mkdir_p!(root)
    System.put_env("HEALTHIE_GATE_ROOT", root)
    {:ok, pid} = Agent.start_link(fn -> %{held_result: {:ok, []}, owner_result: {:ok, []}} end, name: :fixtures)
    on_exit(fn -> if Process.alive?(pid), do: Agent.stop(pid); File.rm_rf!(root) end)
    %{root: root}
  end

  defp issue(id, state, blocked_by \\ []), do: %{id: id, state: state, blocked_by: blocked_by}

  defp held(issues), do: Agent.update(:fixtures, &%{&1 | held_result: {:ok, issues}})
  defp owner(issues), do: Agent.update(:fixtures, &%{&1 | owner_result: {:ok, issues}})

  test "Todo claims without a readiness label and safe idle claims nothing", %{root: root} do
    todo = issue("old", "Todo")

    assert {:ok, [^todo]} = ProjectGate.filter([issue("parent", "Backlog"), todo])
    assert File.read!(Path.join(root, "owner")) == "old\n"

    File.rm!(Path.join(root, "owner"))
    assert {:ok, []} = ProjectGate.filter([])
    refute File.exists?(Path.join(root, "owner"))
  end

  test "Review or Blocked reconstructs ownership and holds a second ready ticket", %{root: root} do
    for state <- ["In Review", "Blocked"] do
      File.rm(Path.join(root, "owner"))
      held([issue("old", state)])

      assert {:ok, []} = ProjectGate.filter([issue("new", "Todo")])
      assert File.read!(Path.join(root, "owner")) == "old\n"
    end
  end

  test "an active ticket reconstructs ownership without bypassing a regressed prerequisite", %{root: root} do
    active = issue("old", "In Progress", [%{state: "Canceled"}])
    held([active])

    assert {:ok, []} = ProjectGate.filter([active, issue("new", "Todo")])
    assert File.read!(Path.join(root, "owner")) == "old\n"
  end

  test "slot survives restart, feedback resumes it and Done releases it", %{root: root} do
    old = issue("old", "Todo")
    new = issue("new", "Todo")

    assert {:ok, [^old]} = ProjectGate.filter([old, new])
    assert File.read!(Path.join(root, "owner")) == "old\n"

    owner([issue("old", "In Review")])
    assert {:ok, []} = ProjectGate.filter([new])

    owner([old])
    assert {:ok, [^old]} = ProjectGate.filter([new, old])

    owner([issue("old", "Done")])
    held([issue("old", "In Progress")])
    assert {:ok, [^new]} = ProjectGate.filter([issue("old", "In Progress"), new])
    assert File.read!(Path.join(root, "owner")) == "new\n"
  end

  test "unfinished and canceled prerequisites do not dispatch; Done does", %{root: root} do
    for blocker_state <- ["Backlog", "Todo", "In Progress", "In Review", "Blocked", "Canceled"] do
      candidate = issue("new", "Todo", [%{state: blocker_state}])
      assert {:ok, []} = ProjectGate.filter([candidate])
      refute File.exists?(Path.join(root, "owner"))
    end

    candidate = issue("new", "Todo", [%{state: "Done"}])
    assert {:ok, [^candidate]} = ProjectGate.filter([candidate])
  end

  test "pause survives another filter call and preserves existing ownership", %{root: root} do
    File.write!(Path.join(root, "owner"), "old\n")
    File.write!(Path.join(root, "paused"), "paused")

    assert {:ok, []} = ProjectGate.filter([issue("new", "Todo")])
    assert File.read!(Path.join(root, "owner")) == "old\n"
  end

  test "duplicate held ownership fails closed", %{root: root} do
    held([issue("old", "In Review"), issue("other", "In Progress")])

    assert {:error, :multiple_project_owners} = ProjectGate.filter([issue("new", "Todo")])
    refute File.exists?(Path.join(root, "owner"))
  end

  test "missing, canceled, or unrelated held owner fails closed", %{root: root} do
    File.write!(Path.join(root, "owner"), "old\n")

    for owner_issues <- [[], [issue("old", "Canceled")], [issue("old", "Backlog")]] do
      owner(owner_issues)
      assert {:ok, []} = ProjectGate.filter([issue("new", "Todo")])
      assert File.read!(Path.join(root, "owner")) == "old\n"
    end

    owner([issue("old", "Todo")])
    held([issue("other", "In Review")])
    assert {:error, :multiple_project_owners} = ProjectGate.filter([issue("old", "Todo")])
  end

  test "tracker failures fail closed without changing ownership", %{root: root} do
    File.write!(Path.join(root, "owner"), "old\n")
    Agent.update(:fixtures, &%{&1 | held_result: {:error, :tracker_unavailable}})

    assert {:error, :tracker_unavailable} = ProjectGate.filter([issue("new", "Todo")])
    assert File.read!(Path.join(root, "owner")) == "old\n"
  end
end
