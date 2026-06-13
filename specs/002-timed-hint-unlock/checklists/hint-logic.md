# Feature Review Checklist: Timed Hint Unlock

**Purpose**: Domain-specific requirements quality review for the hint state machine, timer behaviour,
and settings configuration. Complements the general spec quality checklist (`requirements.md`).
**Created**: 2026-06-10
**Feature**: [spec.md](../spec.md) · [plan.md](../plan.md) · [data-model.md](../data-model.md)
**Audience**: PR reviewer / implementer before starting tasks
**Depth**: Standard

---

## Hint State Machine Requirements Quality

- [ ] CHK001 - Is the full HintSlotState lifecycle (waiting → available → used) specified with every permitted transition explicitly documented and no transitions left implied? [Completeness, Spec §FR-001]
- [ ] CHK002 - Is the initial state of all 3 hint slots at game start defined for both timed mode AND immediate mode without ambiguity? [Completeness, Spec §FR-002, FR-003]
- [ ] CHK003 - Does the spec define what "visible but inactive" means for the waiting state in a way that is testable without relying on visual judgement? (e.g., is reduced opacity or a disabled-tap criterion specified?) [Clarity, Ambiguity, Spec §FR-001]
- [ ] CHK004 - Is the requirement that the hint button is *hidden* (removed from layout) after use clearly distinguished from *disabled* (still occupying space)? [Clarity, Spec §FR-007, FR-009]
- [ ] CHK005 - Is the sequential-unlock rule (hint 2 timer starts only after hint 1's piece is placed) explicitly stated as a requirement, or is it only present in the Clarifications section? [Completeness, Spec §FR-008, FR-008a]
- [ ] CHK006 - Does the spec state whether the 3 hint slots are processed in a fixed order (slot 1 always first) or in any order? [Clarity, Ambiguity, Spec §FR-004]
- [ ] CHK007 - Is the requirement that the entire hint button area disappears when all 3 hints are used (FR-009) consistent with the per-button hiding rule in FR-007, or could they be read as conflicting? [Consistency, Spec §FR-007, FR-009]

---

## Timer Behaviour Requirements Quality

- [ ] CHK008 - Is "piece-placement attempt" defined precisely enough to write an unambiguous automated test? (FR-005 says "player releasing a dragged piece" — is this consistent with the distinction made in the Assumptions section between holding and releasing?) [Clarity, Spec §FR-005, Assumptions]
- [ ] CHK009 - Does FR-006 ("any piece-placement attempt resets the idle timer") remain applicable after a hint has been used and the hinted piece is still unplaced? Or does FR-008 suspend FR-006 during that interval? [Consistency, Conflict, Spec §FR-006, FR-008]
- [x] CHK010 - Is the fallback behaviour (next timer starts after idle timeout even when hinted piece is never placed) formally captured as a requirement, or does it exist only as a planning assumption? [Gap, Spec §Edge Cases, plan.md §Unresolved Spec Gap] ✅ Resolved 2026-06-10: FR-018 explicitly prohibits any fallback — next hint locked until hinted piece is correctly placed.
- [ ] CHK011 - Are the timer-pause requirements for app backgrounding stated in terms observable by the player (e.g., "no hint unlocks due to background time") rather than as an implementation directive? [Clarity, Measurability, Spec §FR-010, SC-007]
- [ ] CHK012 - Is the requirement for timer behaviour during a mid-puzzle restart (all timers reset) specified completely, including whether the restarted session picks up settings that may have changed since the session started? [Coverage, Spec §Edge Cases, FR-017]
- [ ] CHK013 - Does SC-001 (timer fires within a ±1 s window) provide enough precision to write a passing/failing automated test criterion? [Measurability, Spec §SC-001]

---

## Settings Configuration Requirements Quality

- [ ] CHK014 - Is the scope of the Immediate-mode checkbox disabling the timeout input defined for all states: initial screen load with saved value, live toggle, and after an app restart? [Completeness, Spec §FR-014, FR-015]
- [ ] CHK015 - Is the validation rule for the timeout field (reject blank/zero, revert to last valid value) specified with enough precision to cover the edge case where the field was *never* set (default 10 used as fallback)? [Clarity, Spec §FR-012, FR-013]
- [ ] CHK016 - Does the spec define whether the user sees an error message, a silent revert, or both when invalid input is submitted? [Clarity, Gap, Spec §FR-012]
- [ ] CHK017 - Is "persists across app restarts" (FR-016) defined in a way that distinguishes force-kill restarts from home-button exits, or is any re-launch covered? [Clarity, Spec §FR-016]
- [ ] CHK018 - Is there a requirement specifying that the Hints settings section is accessible through the existing adult math-gate, and not through a separate or new access mechanism? [Completeness, Gap, Spec §US-2]
- [ ] CHK019 - Is the upper bound (or absence of upper bound) for `unlockDelaySeconds` specified explicitly as a requirement, not just as an implementation assumption? [Clarity, Spec §Assumptions, FR-012]
- [ ] CHK020 - Does the spec state whether the settings screen must show the current saved hint delay value when re-opened after a previous save, or only on first open? [Completeness, Spec §FR-016]

---

## Consistency & Conflict Analysis

- [ ] CHK021 - Is FR-003 (immediate mode → all hints active from session start) consistent with FR-017 (settings changes apply next session)? If a parent enables immediate mode mid-game, does the current session update or not? [Consistency, Spec §FR-003, FR-017]
- [ ] CHK022 - Does acceptance scenario 3 ("hint used and hinted piece placed → next timer starts") align with FR-008a, and do both consistently use "correctly placed" as the trigger (not "any placement attempt")? [Consistency, Spec §US-1 scenario 3, FR-008a]
- [x] CHK023 - Is the wording of FR-008 ("must NOT start until the piece has been correctly placed") logically consistent with the fallback assumption in the Unresolved Gap — or does the fallback contradict FR-008 as written? [Conflict, Spec §FR-008, plan.md §Unresolved Spec Gap] ✅ Resolved 2026-06-10: FR-018 eliminates the conflict — there is no fallback; FR-008 and FR-018 are fully consistent.
- [ ] CHK024 - Are the button-state terms used in User Story 1 acceptance scenarios ("inactive", "hidden", "active") the same canonical terms used throughout the FR section, or are synonyms used inconsistently? [Consistency, Terminology, Spec §US-1, FR-001]

---

## Edge Case & Recovery Coverage

- [ ] CHK025 - Is the behavior when the puzzle is *won* while a hint timer is mid-countdown (or a hint is actively highlighting a piece) defined in the spec? [Gap, Edge Case]
- [ ] CHK026 - Is the scenario where the child rapidly taps the hint button multiple times while it is active addressed — specifically whether multiple activations of the same slot are possible? [Coverage, Gap, Spec §FR-007]
- [ ] CHK027 - Does the spec address the case where the child places a piece correctly that happens to match *another* unplaced piece's target (if such ambiguity is possible in the puzzle model)? If not, is it explicitly out of scope? [Coverage, Gap]
- [ ] CHK028 - Are the edge cases for the settings screen (entering maximum integer value, copy-pasting non-numeric text into the delay field) covered in the requirements? [Coverage, Edge Case, Spec §FR-012]
- [ ] CHK029 - Is the scenario "app resumes from background while a hint is actively highlighting a piece" addressed — does the hint glow persist or reset? [Gap, Edge Case, Spec §FR-010]

---

## Non-Functional Requirements Coverage

- [ ] CHK030 - Are minimum touch target size requirements for the hint button (all 3 states) specified for child users — or are they deferred to the UI design phase? [Gap, Accessibility, Constitution §I]
- [ ] CHK031 - Is colour contrast for the inactive (waiting) hint button state defined, given that disabled or greyed-out elements are a known accessibility risk for young children? [Gap, Accessibility]
- [ ] CHK032 - Are there requirements specifying that the timer accuracy criterion (SC-001: ±1 s) must hold after the device has been backgrounded and resumed, not only during uninterrupted gameplay? [Completeness, Spec §SC-001, SC-007]
- [ ] CHK033 - Is there a requirement preventing the hint settings from being reset when the adult uses the "Reset Progress" function, or is that relationship left undefined? [Gap, Spec §US-2, FR-012]

---

## Notes

- Items marked `[Gap]` indicate missing requirements — these should be resolved in the spec before implementation begins.
- Items marked `[Conflict]` require a ruling from the spec owner before tasks are written.
- CHK010 and CHK023 are resolved (2026-06-10): FR-018 explicitly prohibits any fallback, aligning plan.md and spec.md. No implementation fallback path should exist.
- Check items off as completed: `- [x]`
