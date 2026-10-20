ExUnit.start()
defmodule SymphonyElixir.Linear.Client do
  def fetch_issues_by_states(_), do: {:ok, Agent.get(:fixtures, & &1.held)}
  def fetch_issue_states_by_ids(_), do: {:ok, Agent.get(:fixtures, & &1.owner)}
end
Code.require_file("project_gate.ex", __DIR__)
defmodule ProjectGateTest do
  use ExUnit.Case, async: false
  alias SymphonyElixir.ProjectGate
  setup do
    root = Path.join(System.tmp_dir!(), "healthie-gate-test-#{System.unique_integer([:positive])}")
    File.mkdir_p!(root)
    System.put_env("HEALTHIE_GATE_ROOT", root)
    {:ok, pid} = Agent.start_link(fn -> %{held: [], owner: []} end, name: :fixtures)
    on_exit(fn -> if Process.alive?(pid), do: Agent.stop(pid); File.rm_rf!(root) end)
    %{root: root}
  end
  defp issue(id, state, blocked_by \\ []), do: %{id: id, state: state, blocked_by: blocked_by}
  test "Review or Blocked holds queue even before a slot file exists" do
    for state <- ["In Review", "Blocked"] do
      Agent.update(:fixtures, &%{&1 | held: [issue("old", state)]})
      assert {:ok, []} = ProjectGate.filter([issue("new", "Todo")])
    end
  end
  test "slot survives restart, feedback resumes it and Done releases it", %{root: root} do
    old = issue("old", "Todo")
    new = issue("new", "Todo")
    assert {:ok, [^old]} = ProjectGate.filter([old, new])
    assert File.read!(Path.join(root, "owner")) == "old\n"
    Agent.update(:fixtures, &%{&1 | owner: [issue("old", "In Review")]})
    assert {:ok, []} = ProjectGate.filter([new])
    Agent.update(:fixtures, &%{&1 | owner: [old]})
    assert {:ok, [^old]} = ProjectGate.filter([new, old])
    Agent.update(:fixtures, &%{&1 | owner: [issue("old", "Done")]})
    assert {:ok, [^new]} = ProjectGate.filter([new])
  end
  test "Canceled blockers are not delivered; pause preserves ownership", %{root: root} do
    assert {:ok, []} = ProjectGate.filter([issue("new", "Todo", [%{state: "Canceled"}])])
    File.write!(Path.join(root, "paused"), "paused")
    assert {:ok, []} = ProjectGate.filter([issue("new", "Todo")])
    refute File.exists?(Path.join(root, "owner"))
  end
end
