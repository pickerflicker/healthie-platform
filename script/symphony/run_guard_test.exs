ExUnit.start()
Code.require_file("run_guard.ex", __DIR__)
defmodule RunGuardTest do
  use ExUnit.Case, async: false
  alias SymphonyElixir.RunGuard
  setup do
    root=Path.join(System.tmp_dir!(), "healthie-run-guard-#{System.unique_integer([:positive])}")
    System.put_env("HEALTHIE_GATE_ROOT", root)
    on_exit(fn -> File.rm_rf!(root); System.delete_env("HEALTHIE_GATE_ROOT") end)
    %{root: root}
  end
  test "failed completion is not a successful continuation" do
    for status <- ["failed", "interrupted", "cancelled", "unknown"] do
      assert {:error, {:turn_failed, %{status: ^status}}} = RunGuard.completion_result(%{"params" => %{"turn" => %{"status" => status}}})
    end
    assert {:ok, :turn_completed} = RunGuard.completion_result(%{"params" => %{"turn" => %{"status" => "completed"}}})
    assert {:ok, :turn_completed} = RunGuard.completion_result(%{"method" => "turn/completed"})
  end
  test "two errors hold the queue durably, including after module reload", %{root: root} do
    RunGuard.record_failure("issue")
    refute File.exists?(Path.join(root, "paused"))
    Code.compile_file(Path.join(__DIR__, "run_guard.ex"))
    RunGuard.record_failure("issue")
    assert File.exists?(Path.join(root, "paused"))
    assert %{"issue_id" => "issue", "reason" => "two_consecutive_worker_failures"} = Jason.decode!(File.read!(Path.join(root,"checkpoint.json")))
  end
  test "a successful turn clears consecutive errors and the turn cap pauses", %{root: root} do
    RunGuard.record_failure("issue")
    RunGuard.record_success("issue")
    RunGuard.record_failure("issue")
    refute File.exists?(Path.join(root, "paused"))
    RunGuard.turn_limit("issue")
    assert File.exists?(Path.join(root, "paused"))
  end
  test "killed sessions cannot bypass the automatic attempt budget", %{root: root} do
    assert :ok = RunGuard.begin_attempt("killed")
    assert :ok = RunGuard.begin_attempt("killed")
    assert {:error, :automatic_attempt_budget_exhausted} = RunGuard.begin_attempt("killed")
    assert File.exists?(Path.join(root, "paused"))
    RunGuard.record_success("recovered")
    assert :ok = RunGuard.begin_attempt("recovered")
  end

end
