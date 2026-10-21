ExUnit.start()
defmodule SymphonyElixir.HealthieRetryProtocolTest do
  use ExUnit.Case, async: false
  alias SymphonyElixir.Codex.AppServer
  alias SymphonyElixir.Linear.Issue
  alias SymphonyElixir.Workflow

  test "failed status inside turn/completed reaches the worker as an error" do
    root = Path.join(System.tmp_dir!(), "healthie-protocol-#{System.unique_integer([:positive])}")
    workspace = Path.join(root, "workspaces/PIC-test")
    File.mkdir_p!(workspace)
    on_exit(fn ->
      Workflow.clear_workflow_file_path()
      File.rm_rf!(root)
    end)
    fake = Path.join(root, "fake-codex")
    File.write!(fake, """
    #!/usr/bin/env python3
    import sys,json
    for line in sys.stdin:
        request=json.loads(line)
        if 'id' not in request: continue
        method=request.get('method')
        result={'thread':{'id':'thread-test'}} if method=='thread/start' else {'turn':{'id':'turn-test'}} if method=='turn/start' else {}
        print(json.dumps({'id':request['id'],'result':result}),flush=True)
        if method=='turn/start':
            print(json.dumps({'method':'turn/completed','params':{'turn':{'id':'turn-test','status':'failed','error':{'message':'fixture transport failure'}}}}),flush=True)
    """)
    File.chmod!(fake, 0o755)
    workflow = Path.join(root, "WORKFLOW.md")
    File.write!(workflow, """
    ---
    tracker:
      kind: memory
    workspace:
      root: #{Jason.encode!(Path.join(root, "workspaces"))}
    codex:
      command: #{Jason.encode!(fake)}
      read_timeout_ms: 5000
      turn_timeout_ms: 5000
    ---
    Fixture prompt.
    """)
    Workflow.set_workflow_file_path(workflow)
    issue=%Issue{id: "fixture", identifier: "PIC-test", title: "fixture", state: "In Progress", description: "fixture", url: "https://example.test"}
    assert {:error, {:turn_failed, %{status: "failed"}}} = AppServer.run(workspace,"fixture",issue)
  end
end
