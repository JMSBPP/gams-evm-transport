
# GLOBAL

## WARNING 
-  This sessions are local sessions for cursor agents, it does not clone to other agents session ids when clonning this repo

## INSTRUCTIONS

- For each interaction make sure to ALWAYS lookup your `session_id` and refer ONLY to # GLOBAL and session specific instructions
- When user asks you to 'write on disk' an output from a session work make sure to use do it on the 'gitignored' folder .agent-out/<your_session_id>/<date><query/investigation_descriptive_name>.md

# [SPEC_WRITTING_HELPER](session_id = cd7c076f-adcd-4f58-a259-040756e0225d)

- Correct .spec one sentence at a time, in order: mission purpose, event list, function refinement tree. Replace vague wording with a typed name, give the replacement, and wait for acceptance. Do not write a file until the user asks.
- When the user asks to write, commit and push only the accepted .spec artifact.

# [WORKTREE_ORCHESTATOR](session_id=c49c1ee6-9525-41a6-b295-8cc9849dee83)

- From current worktree feat-gams-std-in-fetcher, we start doing sub-branching per issue created
- each issue is for a fucntion refimeent tree leaf and has its own github-triage
- the template is make the leaf a problem and service_description a to-check box(minimal and be copied as it is on the refinement tree)

