---
name: northwind-pr
description: Write a pull request description for the current branch in the Northwind team's required format (title, what changed, how I verified it, acceptance criteria, deliberately not done). Use when the user asks to write, draft, or fill in a PR description for Northwind work, or invokes /northwind-pr.
---

# /northwind-pr

Write the pull request description for the work in this branch, in the team's required format.

## What to do

### 1. Read before you write

Gather all of these before drafting a single line:

- `git diff main...HEAD --stat`, then the diff itself, to see what actually changed.
- `git log main..HEAD --oneline`, to see how the work was sequenced.
- The ticket in `docs/tickets/`. Take the ticket ID from the branch name or the commit subjects (for example `NWP-101`), then read that ticket's acceptance criteria and out-of-scope notes word for word.

If the ticket can't be found, or the diff is empty, stop and say so. Don't write a description from guesses.

### 2. Collect the verification that actually happened

List the verification steps that were really run in this session or that the user reports running: test runs, lint, builds, requests, and what was clicked in the browser. For each one, keep the command and its real output, such as the test summary line or the status code.

Anything that wasn't run is not verification. If nothing was run, say so in the description and offer to run the checks. Never fill the gap with what probably would have happened.

### 3. Check each acceptance criterion against the diff

Go through the criteria one at a time. For each, find the code that satisfies it, or establish that nothing does.

- Tick it only when the diff meets it.
- If it is partly met, leave it unticked and add a note saying what is done and what isn't.
- If it isn't met, leave it unticked and say so.

### 4. Write the description

Use exactly these sections, in this order:

```markdown
Title: <TICKET-ID>: <what it does>

## What changed
One plain-language paragraph: what the app can do now that it could not
do before. Not a file list; the diff already is one.

## How I verified it
- `<command>`: <the output it actually produced>
- <what was clicked> → <what appeared>

## Acceptance criteria
- [x] <criterion, copied from the ticket>
- [ ] <criterion> (partial: <what is done, what is not>)

## Deliberately not done
- <out-of-scope item, follow-up, or known rough edge, and why>
```

The title is the ticket ID, a colon, and a short statement of what the change does, for example `NWP-101: add export options`.

If the repository also has a `.github/pull_request_template.md`, keep its required sections too, and put the team's sections inside it.

### 5. Offer to open it

Print the finished title and description. Then offer the command:

```bash
gh pr create --title "<TICKET-ID>: <what it does>" --body-file <file>
```

Ask before running it. Opening a pull request is the user's call.

## Rules

- **Never claim a verification step that was not run.** If you didn't see its output, it doesn't go under "How I verified it". Paraphrased or expected output counts as invented.
- **Read first, write second.** No section is drafted before the diff, the log and the ticket have been read.
- **Tick honestly.** An unmet criterion reported plainly is better than one ticked or left out.
- **Plain language.** "Ops can choose which columns to export" beats "implemented configurable export functionality".
- **"Deliberately not done" is never empty by omission.** If there truly is nothing, write "Nothing deliberately left out."
