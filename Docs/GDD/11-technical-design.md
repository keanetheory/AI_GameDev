# 11 — Technical Design and Platforms

[Back to table of contents](00-table-of-contents.md)

**Owner:** [Name] · **Status:** [Draft / in review / approved] · **Updated:** [YYYY-MM-DD]

## Technical context

| Area | Choice / target | Rationale | Uncertainty to resolve |
| --- | --- | --- | --- |
| Engine and version | [Choice] | [Reason] | [Risk] |
| Languages and tooling | [Choice] | [Reason] | [Risk] |
| Target platforms / minimum hardware | [Targets] | [Reason] | [Risk] |
| External services / dependencies | [Choices and versions] | [Reason] | [Risk] |

## Architecture and data

[Link an architecture diagram. Identify major components, responsibilities, authoritative state, configuration data, and system interfaces.]

## Performance budgets

| Metric | Target | Hardware / scenario | Measurement method | Owner |
| --- | --- | --- | --- | --- |
| Frame time / frame rate | [ms / fps] | [Device / peak scene] | [Profiler / capture] | [Name] |
| Memory | [MB / GB] | [Scenario] | [Method] | [Name] |
| Loading / startup | [Seconds] | [Scenario] | [Method] | [Name] |
| Build / download size | [MB / GB] | [Platform] | [Method] | [Name] |

## Saves and lifecycle

- **Saved data and frequency:** [What, when, and where]
- **Compatibility:** [Schema versioning and migration]
- **Failure handling:** [Corruption, interrupted writes, full storage]
- **Cloud / offline behavior:** [Conflicts, unavailable service, local fallback]
- **Lifecycle:** [Pause, suspend, resume, controller loss, shutdown]

## Development and release pipeline

[Define source control, asset workflow, automated builds, configuration, environments, debugging tools, dependency updates, and rollback capability.]

## Security and platform requirements

[Record applicable permissions, sensitive-data handling, trust boundaries, platform requirements, responsible owners, and verification sources. Link multiplayer specifics to Section 12.]

## Technical prototypes

| Question | Smallest experiment | Pass / fail evidence | Deadline |
| --- | --- | --- | --- |
| [Feasibility concern] | [Prototype] | [Threshold] | [Date] |
