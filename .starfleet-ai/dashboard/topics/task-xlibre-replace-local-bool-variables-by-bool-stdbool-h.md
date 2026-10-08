Title: "xlibre: replace local Bool variables by bool (stdbool.h)"
Category: active
Kind: task
Status: "open"
Created-By: "McKinley"
Created: "2026-10-08T15:52:27Z"
Assigned-To: "—"
Doc-Ref: "—"
Slug: task-xlibre-replace-local-bool-variables-by-bool-stdbool-h

replace local variables (within functions - not anywhere else) with 'Bool' by 'bool' (stdbool). 
take care of assignments between Bool and bool - might need conversion ('!!' - double-negate).
split into separate commits between subsystems (DDX'es, toplevel dirs, extensions, etc)
