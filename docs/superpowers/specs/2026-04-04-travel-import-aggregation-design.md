# Travel Import Aggregation Design

Date: 2026-04-04
Topic: Travel app MVP - Xiaohongshu link import, AI extraction, and categorized aggregation
Status: Draft approved in conversation, written for user review

## 1. Goal

Build the first MVP as a web console or H5 experience that lets a user paste multiple Xiaohongshu travel post links, automatically fetch each post's content, extract travel-related information with an LLM, and present the combined results in a categorized aggregation page.

This MVP exists to validate one core product value:

The user can quickly turn several messy travel posts about the same destination into one structured, readable, traceable information hub.

## 2. MVP Scope

### In scope

- Create an import task for a destination or travel topic
- Paste 1 to 10 Xiaohongshu links into the task
- Fetch content from each link on the server side
- Track per-link processing state
- Send fetched text to an LLM for structured travel information extraction
- Aggregate extracted information from multiple posts by category
- Show information sources for each aggregated item
- Surface failures and allow retry at the per-link or per-extraction level

### Out of scope

- Budget-based itinerary generation
- Real-time hotel, ticket, or transportation price APIs
- Map route planning
- Auto-generated final travel plan
- Native mobile app implementation
- Full support for all possible Xiaohongshu link formats and anti-bot scenarios

## 3. Product Direction

The MVP will use a link-first experience, because that best matches the intended user flow. However, the system should be built internally around normalized structured data instead of raw AI summaries. This keeps the first version simple for users while preserving a solid foundation for future phases such as budget planning, map display, and external price enrichment.

The first version accepts that not every pasted link will parse successfully. The system should optimize for a smooth batch workflow, not a perfect fetch rate.

## 4. Primary User Flow

1. The user creates a task, such as "Chengdu one-day trip".
2. The user pastes several Xiaohongshu links.
3. The system validates and stores the links.
4. The system processes each link independently.
5. For each successful fetch, the system extracts title, body text, and available metadata.
6. The system sends the fetched text to an LLM and asks for structured travel information in a strict schema.
7. The system aggregates the extracted information across posts into unified categories.
8. The user opens the aggregation page and reviews combined travel insights with source traceability.

## 5. Key Pages

### 5.1 Task Creation Page

Purpose: create a new aggregation task and submit multiple links.

Required elements:

- Task name input
- Destination or topic hint, if desired
- Multi-link input area
- Link validation feedback
- Submit action

Success condition:

The user can clearly define one travel topic and submit a batch of related Xiaohongshu links for processing.

### 5.2 Processing Page

Purpose: show progress and failures at the link level.

Required states per link:

- Pending
- Fetching
- Fetch failed
- Extracting
- Extraction failed
- Completed

Required actions:

- Retry fetch
- Retry extraction
- View raw fetched content if available

Success condition:

The user always understands which links succeeded, which failed, and whether the batch is still making progress.

### 5.3 Aggregation Page

Purpose: present normalized travel information from multiple posts in one organized view.

Required category sections:

- Attractions
- Transportation
- Accommodation
- Food
- Notes and tips

Each aggregated item should show:

- Normalized title or name
- Consolidated summary
- Source count
- Source post references
- Conflict indicator when sources disagree
- Confidence hint if available

Success condition:

The user can quickly understand what places to visit, what to eat, how to move around, where to stay, and what to watch out for, while still being able to inspect the original source trail.

## 6. System Architecture

The MVP should be split into five modules with clear boundaries.

### 6.1 Link Intake Module

Responsibilities:

- Accept user-submitted task metadata and link list
- Validate link format
- Create import records
- Queue or trigger processing

Output:

- Import task
- Source post records in pending state

### 6.2 Content Fetch Module

Responsibilities:

- Resolve each Xiaohongshu link
- Attempt to fetch title, body, and useful metadata
- Record fetch success or failure independently per link

Design note:

This module must be failure-tolerant. One bad link must not block the rest of the task.

### 6.3 AI Extraction Module

Responsibilities:

- Build a structured extraction prompt
- Send fetched content to the LLM
- Require a strict JSON schema response
- Validate and persist structured output
- Mark extraction failures separately from fetch failures

Design note:

Do not store only a plain language AI summary. The output must be structured enough for deterministic aggregation and future enrichment.

### 6.4 Aggregation Module

Responsibilities:

- Group extracted items by category
- Normalize obvious duplicates such as repeated attraction names
- Merge source-backed summaries
- Flag conflicting claims instead of hiding them

Design note:

The first version should prefer transparent aggregation over aggressive deduplication. If the system is unsure whether two items are the same, it should keep them separate or flag them for later review.

### 6.5 Presentation Module

Responsibilities:

- Render progress states
- Render category-based aggregation
- Provide source traceability
- Support retry and inspection actions

## 7. Data Model

The system should maintain three layers of information: raw source content, structured extraction output, and aggregated travel entities.

### 7.1 ImportTask

Represents a user-created batch of related links.

Suggested fields:

- `id`
- `name`
- `topic`
- `status`
- `created_at`
- `updated_at`

### 7.2 SourcePost

Represents a single Xiaohongshu link inside a task.

Suggested fields:

- `id`
- `task_id`
- `source_url`
- `fetch_status`
- `fetch_error`
- `title`
- `body_text`
- `author_name` if available
- `published_at` if available
- `raw_metadata`
- `extraction_status`
- `extraction_error`
- `created_at`
- `updated_at`

### 7.3 ExtractedTravelInfo

Represents the structured LLM output for one source post.

Suggested top-level fields:

- `id`
- `source_post_id`
- `destination`
- `trip_duration`
- `attractions`
- `transport`
- `accommodation`
- `food`
- `tips`
- `raw_model_output`
- `schema_version`
- `created_at`

Suggested item structure within category arrays:

- `name`
- `summary`
- `recommended_time`
- `cost_hint`
- `reason`
- `notes`

### 7.4 AggregatedTopic

Represents one merged item shown on the aggregation page.

Suggested fields:

- `id`
- `task_id`
- `category`
- `normalized_name`
- `merged_summary`
- `source_post_ids`
- `conflict_flag`
- `confidence_score`
- `enrichment_data`
- `created_at`
- `updated_at`

## 8. Extraction Schema Guidance

The extraction prompt should instruct the LLM to return only travel-relevant content. The schema should be constrained enough to reduce output drift.

Suggested categories:

- Attractions: places to visit, scenic spots, landmarks, neighborhoods
- Transportation: transit suggestions, route hints, taxi or subway guidance, transfer advice
- Accommodation: hotels, hostels, district stay suggestions, lodging recommendations
- Food: restaurants, snacks, local specialties, food streets
- Tips: time advice, crowd warnings, reservation reminders, budget notes, packing reminders

The extraction layer should ignore unrelated social content unless it directly affects travel planning.

## 9. Aggregation Rules

The aggregation module should follow these rules:

1. Group items by category first.
2. Normalize names when there is high confidence that two items refer to the same place or concept.
3. Preserve source references for every merged item.
4. When sources disagree, show the disagreement as a conflict flag or conflict note.
5. Avoid inventing unified facts when the source data is inconsistent.

Examples:

- If three posts mention the same attraction, merge them into one attraction card with three sources.
- If two posts recommend visiting at night and one recommends daytime, keep the item merged but surface the timing difference as a conflict note.
- If two similar names may or may not refer to the same food shop, do not force a merge unless confidence is high.

## 10. Failure Handling

Failure handling is a core product requirement for this MVP.

### 10.1 Fetch Failures

- A single fetch failure must not fail the whole task.
- The user should see the failure state and a readable reason if one is available.
- The user should be able to retry that link.

### 10.2 Extraction Failures

- If content fetch succeeds but schema validation fails, mark extraction as failed.
- Allow the user or system to retry extraction without re-fetching when the source text is still usable.

### 10.3 Ambiguous or Conflicting Data

- Do not force a single truth when sources disagree.
- Keep source traceability visible.
- Prefer transparency over overconfident cleanup.

## 11. Non-Functional Requirements

### 11.1 Traceability

Every aggregated item must be traceable back to one or more source posts.

### 11.2 Partial Progress

Users should see incremental progress instead of waiting for the entire batch to finish.

### 11.3 Extensibility

The architecture should allow later integration of:

- Hotel price APIs
- Ticket APIs
- Transport pricing
- Budget planning
- Map and route display

This means the aggregation layer should remain structured and category-aware rather than becoming a one-off AI-generated markdown report.

### 11.4 Compliance and Platform Risk Awareness

Because the MVP depends on link fetching, the system should assume that some content may be inaccessible, rate-limited, or unstable. The product copy and internal expectations should reflect that this is a best-effort import flow, not a guaranteed universal crawler.

## 12. MVP Success Criteria

The MVP is successful if a user can:

- Create a task with 3 to 5 related Xiaohongshu travel links
- Obtain structured travel extraction results from the links that do fetch successfully
- View combined information by category on one page
- Understand where each aggregated item came from
- Continue using the task even if one or more links fail

## 13. Recommended Implementation Priorities

Build in this order:

1. Task creation and source post persistence
2. Per-link processing state model
3. Content fetch pipeline
4. Strict LLM extraction pipeline
5. Category aggregation and source traceability
6. Basic web UI for processing and results

This order validates the product core before any future itinerary generation or external pricing integrations.

## 14. Explicit Phase Separation

To keep scope healthy, the following future features should remain outside this MVP and enter later specs:

- Price enrichment from hotel or ticket providers
- Budget-constrained travel planning
- Auto-generated itineraries
- Map-based route visualization
- Final plan recommendation engine

These features depend on the structured travel dataset produced by this MVP. They should be layered on top after the import and aggregation workflow is stable.
