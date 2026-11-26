# Roles

<!--
Only for a project where more than one Claude session works at once, each with its own job.
A project without this file has no roles, and /rsd:handoff and /rsd:pickup work on .rsd/HANDOFF.md as always.

One line per role: name · commits: yes or no · what the role does.
- The name is one lowercase word. It is what you type: /rsd:handoff <name>, /rsd:pickup <name>.
- Each role gets its own handoff, .rsd/HANDOFF-<name>.md. .rsd/FACTS.md is shared by every role.
- commits: yes  this role's handoff commits and pushes, sweeping in every other role's files.
- commits: no   this role never changes git. Its handoff only writes files, and a committing role's next commit saves them.
At least one role must be commits: yes, or nothing is ever saved in git.
-->

- {{role}} · commits: yes · {{what_this_role_does}}
- {{role}} · commits: no · {{what_this_role_does}}
