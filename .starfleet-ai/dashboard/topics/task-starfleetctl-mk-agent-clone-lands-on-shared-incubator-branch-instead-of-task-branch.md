Title: "starfleetctl: mk-agent-clone lands on shared incubator branch instead of task branch"
Category: active
Kind: task
Status: "assigned"
Created-By: "Laforge"
Created: "2026-10-02T00:32:16Z"
Assigned-To: "Laforge"
Doc-Ref: "—"
Slug: task-starfleetctl-mk-agent-clone-lands-on-shared-incubator-branch-instead-of-task-branch

mk-agent-clone <release> <name> creates branch rfc/backport-<release> tracking origin/rfc/backport-<release> (shared incubator), not rfc/backport-<rel>-<name> from origin/release/<rel>. Cherry-picks from there bring 6-32 foreign commits into release PRs. Fix: create rfc/backport-<rel>-<name> from origin/release/<rel> with -u origin/release/<rel>. Add pre-check: git rev-list --count origin/release/<branch>..HEAD must be 0.
