✅ Agent Instructions: “Roku‑Safe Coding Protocol”
(You can paste this directly into your agent’s system prompt or prepend it to every task.)

1. Never mutate global state
Do not create or modify global variables.

Do not rely on implicit globals.

Wrap all shared data in functions or objects.

If a global must exist, treat it as read‑only.

Rule:

All new variables must be local (m. or function‑scoped) unless explicitly instructed otherwise.

2. Never modify existing SceneGraph nodes unless explicitly told to
SceneGraph is extremely sensitive to side effects.

Rules:

Do not add observers to existing nodes unless the user requests it.

Do not change fields on nodes outside the feature you’re implementing.

Do not modify parent/child relationships unless explicitly instructed.

Safe pattern:

Create new nodes for new features.
Do not reuse nodes unless the user explicitly says so.

3. Fail loudly — never silently
Roku swallows errors. Your agent must not.

Rules:

Always check for invalid before accessing fields.

Always log errors with print or m.logger.

Wrap risky operations in explicit guards.

Example:

brightscript
if node = invalid
    print "ERROR: node is invalid in <function>"
    return invalid
end if
4. Never block the render thread
Avoid long loops, heavy JSON, or synchronous operations.

Rules:

Break long loops into chunks.

Offload heavy work to tasks.

Use roSGNode tasks for network or parsing.

5. Treat all associative arrays as immutable
BrightScript passes AAs by reference, so mutation is dangerous.

Rules:

Never modify an AA passed into a function.

Always clone before editing:

brightscript
copy = original.clone(true)
6. Never rely on file load order
Roku loads files alphabetically.

Rules:

Do not depend on side effects in init() of other files.

Do not assume another file has run first.

Always explicitly import or call what you need.

7. Every new feature must be sandboxed
This is the most important rule.

Rules:

New features must live in new files or new functions.

No touching unrelated code paths.

No modifying existing logic unless the user explicitly instructs it.

Pattern:

Code
Feature/
    FeatureController.brs
    FeatureView.xml
    FeatureView.brs
8. When editing existing code, follow the “surgical patch” rule
Only modify the exact lines required.
Never refactor unrelated logic.
Never reorder code.
Never rename variables.

9. Before writing code, the agent must output a “Safety Impact Plan”
This is a pre‑flight check that prevents breakage.

The plan must include:

What files will be touched

What nodes will be created

What observers will be added

What global state will be read

What existing logic will remain untouched

The agent must wait for user approval before writing code.

10. After writing code, the agent must output a “Regression Risk Report”
This forces the agent to think about what it might break.

Include:

Possible side effects

Node interactions

Timing changes

Event‑loop risks

Shared AA risks

Load‑order risks


When modifying or adding BrightScript or SceneGraph code, follow these rules strictly:

Never mutate shared objects.  
Always clone arrays and AA’s using Clone() before modifying.

Never reuse SceneGraph nodes across screens.  
Always create new nodes with m.top.createChild() or CreateObject("roSGNode", "ComponentName").

Every new field must be namespaced.  
Example: myFeature_isReady instead of isReady.

Every observer must be unique.  
Before adding an observer, check if one already exists.

Never block the render thread.  
Heavy work must go in a Task node.

Log every failure.  
Wrap all node creation, parsing, and network calls in try/catch style checks with if invalid.

Do not rely on alphabetical load order.  
Use main.brs as the single entry point and explicitly import dependencies.

When adding a feature, run a dependency scan:

Which nodes does it touch

Which fields does it modify

Which observers does it add

Which global state does it rely on

Never modify existing logic without explaining the side effects.  
Add comments describing what other components depend on.

All new features must be sandboxed.  
Put them in their own component unless absolutely impossible.