# 04 — Game Systems and Mechanics

[Back to table of contents](00-table-of-contents.md)

**Owner:** [Name] · **Status:** [Draft / in review / approved] · **Updated:** [YYYY-MM-DD]

## System inventory

| System ID | System | Purpose | Dependencies | Prototype priority |
| --- | --- | --- | --- | --- |
| SYS-001 | [Combat / building / puzzles / crafting / other] | [Player benefit] | [IDs] | [Priority] |

## Mechanic specification — [MEC-001: Name]

Duplicate this block for each mechanic.

- **Purpose and linked pillar:** [Why this mechanic exists]
- **Trigger and preconditions:** [Input or event; eligibility]
- **Inputs and resources consumed:** [Amounts, units, and timing]
- **Resolution rules:** [Ordered steps; formulas; rounding; random selection]
- **Outputs:** [State changes, rewards, and events]
- **Feedback:** [Visual, audio, interface, and haptic signals]
- **Restrictions:** [Cooldowns, caps, exclusions, and interaction priority]
- **Failure / cancellation:** [Refunds, interruption, invalid targets, retries]

| Current state | Trigger / guard | Next state | Side effects |
| --- | --- | --- | --- |
| [State] | [Condition] | [State] | [Effects] |

| Parameter | Initial value | Unit / range | Reason | Tuning owner |
| --- | --- | --- | --- | --- |
| [Parameter] | [Value or TBD] | [Unit / bounds] | [Hypothesis] | [Name] |

**Worked example:** [Starting values → rule application → expected result]

**Acceptance criteria:** [Given a state, when an action occurs, then the expected outcome is…]

## AI and autonomous behavior

[For each actor type, define goals, perception, decision priorities, states, difficulty changes, and fair information limits. Include stuck / unreachable behavior.]

## System interactions and exploits

| Systems involved | Interaction rule | Potential exploit or conflict | Resolution / test |
| --- | --- | --- | --- |
| [IDs] | [Rule] | [Risk] | [Expected behavior] |
