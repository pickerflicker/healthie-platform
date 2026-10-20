defmodule SymphonyElixir.HealthieRetryProtocolTest do
  use SymphonyElixir.TestSupport

  test "failed status inside turn/completed reaches the worker as an error" do
    root = Path.join(System.tmp_dir!(), "healthie-protocol-#{System.unique_integer([:positive])}")
    workspace = Path.join(root, "workspaces/PIC-test")
    File.mkdir_p!(workspace)
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
    write_workflow_file!(Workflow.workflow_file_path(), workspace_root: Path.join(root,"workspaces"), codex_command: fake)
    issue=%Issue{id: "fixture", identifier: "PIC-test", title: "fixture", state: "In Progress", description: "fixture", url: "https://example.test"}
    try do
      assert {:error, {:turn_failed, %{status: "failed"}}} = AppServer.run(workspace,"fixture",issue)
    after
      File.rm_rf!(root)
    end
  end
end
