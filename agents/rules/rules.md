# Rules - Agent Behavior (MANDATORY)

## Rule: Flutter Migration Must Replicate SwiftUI 1:1

This rule is **MANDATORY** and has priority over stylistic preferences.

1. The agent **MUST** replicate screens from SwiftUI exactly as defined in:
   - `ios/AppGestaoServicos/Views.swift`
   - `ios/AppGestaoServicos/Theme.swift`
   - `ios/AppGestaoServicos/SplashView.swift`
   - `ios/AppGestaoServicos/EmployeesView.swift`
   - `ios/AppGestaoServicos/AgendaCalendar.swift`
   - `ios/AppGestaoServicos/ActivityView.swift`

2. The agent **MUST NOT** invent, redesign, simplify, modernize, or reinterpret:
   - layout structure
   - navigation flow
   - components
   - copy/text labels
   - interactions
   - visual hierarchy

3. If any Flutter implementation detail is missing, the agent **MUST**:
   - stop,
   - report the exact missing Swift reference,
   - ask for explicit approval before any deviation.

4. Temporary placeholders are **FORBIDDEN** unless explicitly requested by the user.

5. New UI behaviors not present in Swift are **FORBIDDEN** unless explicitly requested by the user.

6. Before delivering any screen migration, the agent **MUST** verify parity against Swift sources and report what was matched.

7. If this rule conflicts with any generic UI preference, this rule **WINS**.
