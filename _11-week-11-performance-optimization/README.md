# Week 11 | Performance Optimization


## Identified Issues
1. **Excessive Widget Rebuilds (Flame Chart):**
   - Unscoped provider listening on `notesSearchQueryProvider` rebuilt the entire `NotesPage` tree on every single search keystroke.
   - Top-level `authStateProvider` watch in `LoginPage` rebuilt text fields on loading status changes.
2. **Repeated API Requests Without Cache (Network Profiler):**
   - `AnnouncementRepositoryImpl` executed remote network calls on every screen visit without caching.
3. **Memory Leaks (Memory Tab Heap Growth):**
   - Undisposed `TextEditingController` instances in `ChatPage._manageApiKey()` leaked notification listeners and strings upon repeated dialog openings.
4. **Repaint Cascades (Highlight Repaints):**
   - Unbounded repaints from active text cursor and scrolling lists triggered whole-scaffold repaints.

## Applied Optimizations
1. **Riverpod `select`:**
   - Filtered subscriptions in `NotesPage` (`select((q) => q.trim().isEmpty)`) and `LoginPage` (`select((s) => s.isLoading)`).
2. **Widget Extraction & `const` Constructors:**
   - Extracted modular widgets (`AnnouncementCard`, `NotesEmptyState`, `ChatPrivacyBanner`, `_ChatQuotaSubtitle`, `_LoginSubmitButton`, `NoteListItem`).
   - Added `const` to static layout nodes and styles across the app.
3. **Repository Cache (Stale-While-Revalidate):**
   - Built in-memory TTL caching with background revalidation and immediate cache returns in `AnnouncementRepositoryImpl`.
4. **RepaintBoundary Layers:**
   - Isolated `ChatInputBar`, `NotesList`, and chat message lists inside `RepaintBoundary` layers.
5. **Memory Leak Remediation:**
   - Ensured guaranteed controller disposal with `try ... finally` block on dialog dismissal.

## Reflections
1. Which optimization had the biggest impact and why?
   - The stale-while-revalidate repository cache had the biggest impact because it completely eliminated redundant HTTP requests during navigation and reduced screen transition latency from hundreds of milliseconds to instantaneous in-memory rendering.
2. How did you verify optimizations actually work (not placebo)?
   - Verification was performed using automated cache invocation tests and Flutter DevTools profiling
3. What trade-offs did you face (for example, code complexity vs performance)?
   - The primary trade-off was increased architectural complexity and boilerplate
4. When should premature optimization be avoided?
   - Premature optimization should be avoided during early prototyping and before profiling proves a measurable bottleneck exists, as guessing performance issues adds unnecessary code complexity, hurts readability, and wastes engineering time on code paths that have negligible impact on real-world frame rates or memory
