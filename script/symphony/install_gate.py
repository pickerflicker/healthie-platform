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
