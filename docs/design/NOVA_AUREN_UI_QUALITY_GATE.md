# NOVA / AUREN UI Quality Gate

This checklist converts design guidance into reviewable criteria for Flutter/Android. It is a manual review aid, not an automated test suite.

## Design identity
- [ ] Screen has one clear primary task and a visible hierarchy.
- [ ] Visual choices fit NOVA's private AI executive-workspace identity or AUREN's social/opportunity identity.
- [ ] Avoids generic repeated cards, unnecessary labels, decorative gradients, and motion without purpose.
- [ ] Uses existing theme tokens/components where available; no duplicate design system introduced.

## Mobile resilience
- [ ] Works on a narrow Android phone without horizontal overflow.
- [ ] Long Arabic and English labels wrap without clipping.
- [ ] RTL and LTR layout use directional alignment/padding correctly.
- [ ] Safe areas, keyboard insets, scrolling, and system navigation are respected.
- [ ] Text scaling and empty/loading/error/offline states are usable.

## Accessibility and interaction
- [ ] Meaningful controls have accessible labels/semantics.
- [ ] Contrast and touch target sizes are adequate.
- [ ] Focus and keyboard behavior are sensible where applicable.
- [ ] Motion is restrained and state changes are communicated.
- [ ] Every visible control performs the action its label promises.
- [ ] External or consequential actions retain explicit user approval.

## Evidence required for completion
- [ ] Changed Dart files formatted.
- [ ] Relevant targeted widget tests pass.
- [ ] Flutter analyze result recorded.
- [ ] Broader tests/build run when feasible; any skipped checks are explicitly listed.
- [ ] Screenshots inspected when a visual test environment is available.
- [ ] No merge into main without owner approval.

## Upstream guidance
- [Anthropic Frontend Design](https://github.com/anthropics/skills/tree/main/skills/frontend-design)
- [UI/UX Pro Max](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill)
- [Vercel Web Design Guidelines](https://github.com/vercel-labs/agent-skills/tree/main/skills/web-design-guidelines) — primarily web-focused; adapt principles for Flutter.
