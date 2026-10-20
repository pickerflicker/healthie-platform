from pathlib import Path
import shutil,sys
root=Path(sys.argv[1]); project=Path(__file__).resolve().parents[2]
p=root/'lib/symphony_elixir/linear/client.ex'
s=p.read_text()
old='do_fetch_by_states(project_slug, tracker.active_states, assignee_filter)'
new='''with {:ok, candidates} <- do_fetch_by_states(project_slug, tracker.active_states, assignee_filter) do
            SymphonyElixir.ProjectGate.filter(candidates)
          end'''
if old not in s: raise SystemExit('Expected runtime interface missing; refusing an unverified patch')
p.write_text(s.replace(old,new,1))
shutil.copyfile(project/'script/symphony/project_gate.ex', root/'lib/symphony_elixir/project_gate.ex')

shutil.copyfile(project/'script/symphony/run_guard.ex', root/'lib/symphony_elixir/run_guard.ex')
p=root/'lib/symphony_elixir/codex/app_server.ex'
s=p.read_text()
old='''        emit_turn_event(on_message, :turn_completed, payload, payload_string, port, payload)
        {:ok, :turn_completed}'''
new='''        case SymphonyElixir.RunGuard.completion_result(payload) do
          {:ok, _} = result ->
            emit_turn_event(on_message, :turn_completed, payload, payload_string, port, payload)
            result
          {:error, _} = result ->
            emit_turn_event(on_message, :turn_failed, payload, payload_string, port, payload)
            result
        end'''
if old not in s: raise SystemExit('Unknown app-server completion handler; refusing patch')
p.write_text(s.replace(old,new,1))
p=root/'lib/symphony_elixir/agent_runner.ex';s=p.read_text()
old='''      {:error, reason} ->
        Logger.error("Agent run failed'''
new='''      {:error, reason} ->
        SymphonyElixir.RunGuard.record_failure(issue.id)
        Logger.error("Agent run failed'''
if old not in s: raise SystemExit('Unknown worker error handler; refusing patch')
s=s.replace(old,new,1)
old='''      Logger.info("Completed agent run for'''
new='''      SymphonyElixir.RunGuard.record_success(issue.id)
      Logger.info("Completed agent run for'''
if old not in s: raise SystemExit('Unknown worker success handler; refusing patch')
s=s.replace(old,new,1)
old='''Logger.info("Reached agent.max_turns for #{issue_context(refreshed_issue)} with issue still active; returning control to orchestrator")'''
new=old+'''\n          SymphonyElixir.RunGuard.turn_limit(issue.id)'''
if old not in s: raise SystemExit('Unknown worker limit handler; refusing patch')
s=s.replace(old,new,1)
old="case run_on_worker_host(issue, codex_update_recipient, opts, worker_host) do"
new="case (with :ok <- SymphonyElixir.RunGuard.begin_attempt(issue.id), do: run_on_worker_host(issue, codex_update_recipient, opts, worker_host)) do"
if old not in s: raise SystemExit('Unknown worker attempt handler; refusing patch')
p.write_text(s.replace(old,new,1))
shutil.copyfile(project/'script/symphony/retry_protocol_test.exs', root/'test/symphony_elixir/healthie_retry_protocol_test.exs')
