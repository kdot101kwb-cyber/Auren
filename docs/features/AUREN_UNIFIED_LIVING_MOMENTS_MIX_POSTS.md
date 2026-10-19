# AUREN Unified Living Moments + Mix Posts

Status: **Initial composer slice implemented; broader product capabilities remain future work.**

## Included in this slice
- A shared Pulse composer for Moments, Ideas, Questions, Projects, and Opportunities.
- Living Moment context labels: Now, Making progress, On the move, and Open conversation.
- A live preview combining post text and one image URL in the same post.
- HTTP/HTTPS URL validation before publishing.
- Context labels are descriptive only; choosing “On the move” does not request or publish device location.
- Publishing uses the existing `AurenPost` model and `PostRepository`; no new collection or backend schema is introduced.

## Existing limits
- The current post model stores one `mediaUrl`; this is not yet a multi-image gallery or a mixed video/audio carousel.
- “Living moment” currently adds a user-selected context label. It does not imply live location tracking, temporary stories, real-time presence, or background recording.
- The existing feed renders image URLs as images. Additional media types need explicit model/UI support and validation before being offered.

## Next implementation stages
1. Add widget tests for context selection, mixed text/image preview, invalid media URLs, and empty submissions.
2. Add authenticated feed tests around publishing and rendering.
3. Design a versioned multi-attachment schema before implementing image/video/audio mixes.
4. Define privacy controls and retention rules before adding ephemeral or location-aware moments.
5. Run Flutter format, analyze, widget tests, and Android build in CI.
