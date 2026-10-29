---
name: nova-ui-quality
description: Apply distinctive, accessible, production-minded UI design and visual QA to NOVA and AUREN Flutter screens. Use when creating, refactoring, or reviewing mobile UI.
---

# NOVA UI Quality Skill

## Goal
Create a recognizable product interface, not a generic AI-generated screen. This repository is Flutter-first and Android-first. Prefer native Flutter widgets and existing project conventions; do not introduce a web-only stack into mobile code.

## Before changing code
1. Inspect the target screen, its state/controller, shared theme, routing, localization, and tests.
2. Search for an existing component or design token before adding another.
3. State the user problem, screen hierarchy, and intended behavior before implementation.
4. Keep changes scoped. Do not rewrite unrelated files or duplicate existing systems.
5. Do not claim implementation or test success unless the relevant command actually ran and passed.

## NOVA visual direction
- Personality: capable private AI partner and executive workspace; calm, precise, warm, trustworthy.
- Palette starting point (validate against existing theme before use): deep ink #11152B, midnight violet #29245B, electric lilac #8B7CFF, sky accent #62C7F2, soft surface #F5F6FC, readable text #20243A.
- Use one memorable visual signature per screen; avoid decorating every component.
- Use clear hierarchy, deliberate spacing, restrained gradients, and consistent iconography.
- Use sentence case and user language. Prefer clear action labels such as “Review plan” over vague labels such as “Submit”.
- Do not render every feature as an identical rounded card. Use grouping, lists, sections, and whitespace according to information priority.
- Support Arabic RTL and English LTR where the screen supports localization; do not hardcode directional padding or alignment when directional APIs are appropriate.

## Flutter implementation standards
- Prefer ThemeData, ColorScheme, TextTheme, shared spacing/radius tokens, and existing components over scattered literal values.
- Respect safe areas, keyboard insets, system bars, and Android back navigation.
- Use Semantics and accessible labels for meaningful controls; keep touch targets comfortably usable.
- Ensure contrast, scalable text, focus behavior where relevant, and reduced-motion/system animation preferences.
- Use responsive constraints rather than fixed screen dimensions.
- Every interactive control must have a real behavior, loading state where needed, and clear success/error feedback.
- Every async UI flow should handle loading, empty, error, and populated states.
- Preserve existing architecture, permissions, offline behavior, and user approval boundaries for external actions.

## Review checklist
For each changed screen, inspect:
- first-glance hierarchy and primary action;
- narrow Android screen, large text, long Arabic/English labels, and RTL;
- empty, loading, error, offline, and long-content states;
- keyboard overlap, scrolling, safe areas, and bottom navigation;
- accessibility semantics, contrast, and touch targets;
- motion restraint and state-change feedback;
- consistency with neighboring screens and existing design tokens.

## Validation
1. Run formatter on changed Dart files.
2. Run targeted widget tests first.
3. Run Flutter analyze and the relevant broader test suite when feasible.
4. If visual tooling is available, capture and inspect screenshots at a narrow phone size and a larger size.
5. Report exact commands and outcomes. Clearly distinguish tests not run from passing tests.

## Upstream references
- Anthropic Frontend Design: https://github.com/anthropics/skills/tree/main/skills/frontend-design
- UI/UX Pro Max: https://github.com/nextlevelbuilder/ui-ux-pro-max-skill
- Vercel Web Interface Guidelines (web-focused; adapt principles, do not treat as Flutter implementation): https://github.com/vercel-labs/agent-skills/tree/main/skills/web-design-guidelines

These references are guidance, not proof that the application has been tested. Review upstream files and licenses before copying or installing external code.
