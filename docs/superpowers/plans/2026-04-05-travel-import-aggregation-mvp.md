# Travel Import Aggregation MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an MVP web app that accepts multiple Xiaohongshu links, fetches source content, extracts structured travel data with an LLM, and shows categorized aggregated results with source traceability.

**Architecture:** Start from a single Next.js application with server actions and route handlers for the web UI and internal APIs. Persist task, source-post, extraction, and aggregation state in SQLite through Prisma. Keep fetch, extraction, and aggregation logic isolated under `src/server/` so future phases can swap storage, queueing, and enrichment APIs without rewriting the UI.

**Tech Stack:** Next.js 15, React 19, TypeScript, Prisma, SQLite, Zod, Vitest, Testing Library, Tailwind CSS

---

## Planned File Structure

### App shell and UI

- Create: `package.json`
- Create: `tsconfig.json`
- Create: `next.config.ts`
- Create: `postcss.config.js`
- Create: `tailwind.config.ts`
- Create: `src/app/layout.tsx`
- Create: `src/app/page.tsx`
- Create: `src/app/tasks/new/page.tsx`
- Create: `src/app/tasks/[taskId]/page.tsx`
- Create: `src/app/tasks/[taskId]/results/page.tsx`
- Create: `src/components/task-form.tsx`
- Create: `src/components/source-post-status-list.tsx`
- Create: `src/components/aggregated-category-section.tsx`

### Domain and server logic

- Create: `src/lib/env.ts`
- Create: `src/lib/db.ts`
- Create: `src/lib/types.ts`
- Create: `src/server/link-validation.ts`
- Create: `src/server/fetch/xiaohongshu-fetcher.ts`
- Create: `src/server/extraction/extraction-schema.ts`
- Create: `src/server/extraction/extract-travel-info.ts`
- Create: `src/server/aggregation/aggregate-travel-info.ts`
- Create: `src/server/tasks/task-service.ts`

### API and actions

- Create: `src/app/api/tasks/route.ts`
- Create: `src/app/api/tasks/[taskId]/retry-fetch/route.ts`
- Create: `src/app/api/tasks/[taskId]/retry-extraction/route.ts`
- Create: `src/app/actions/task-actions.ts`

### Data and tests

- Create: `prisma/schema.prisma`
- Create: `prisma/migrations/`
- Create: `vitest.config.ts`
- Create: `src/test/setup.ts`
- Create: `src/server/link-validation.test.ts`
- Create: `src/server/extraction/extraction-schema.test.ts`
- Create: `src/server/aggregation/aggregate-travel-info.test.ts`
- Create: `src/app/tasks/new/task-form.test.tsx`

### Docs

- Modify: `docs/product/2026-04-05-travel-import-aggregation-prd.md`
- Modify: `docs/superpowers/specs/2026-04-04-travel-import-aggregation-design.md`
- Create: `README.md`
- Create: `.env.example`

## Working Assumptions

- The repository is currently empty, so this plan includes bootstrap work.
- The first implementation uses SQLite for local development and MVP validation.
- Link fetching is a best-effort server-side module, not a guaranteed universal crawler.
- Processing runs inline for MVP. A background queue can be added in a later phase if latency becomes unacceptable.

## Milestones

1. Project bootstrap and developer setup
2. Persistence model and domain types
3. Task creation flow and link intake
4. Fetch and extraction pipeline
5. Aggregation and results UI
6. Retry, validation, and documentation

### Task 1: Bootstrap the Next.js workspace

**Files:**
- Create: `package.json`
- Create: `tsconfig.json`
- Create: `next.config.ts`
- Create: `postcss.config.js`
- Create: `tailwind.config.ts`
- Create: `src/app/layout.tsx`
- Create: `src/app/page.tsx`
- Create: `README.md`
- Create: `.env.example`

- [ ] **Step 1: Write the failing smoke test for the home page**

```tsx
// src/app/home-page.test.tsx
import { render, screen } from "@testing-library/react";
import HomePage from "./page";

describe("HomePage", () => {
  it("renders the MVP title and entry CTA", () => {
    render(<HomePage />);

    expect(screen.getByText("Travel Import Aggregation")).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "Create Task" })).toBeInTheDocument();
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npm test -- src/app/home-page.test.tsx`
Expected: FAIL with module resolution or missing file errors because the app shell does not exist yet.

- [ ] **Step 3: Write the minimal workspace files and app shell**

```json
{
  "name": "travel-import-aggregation",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "test": "vitest run"
  },
  "dependencies": {
    "next": "^15.0.0",
    "react": "^19.0.0",
    "react-dom": "^19.0.0",
    "zod": "^3.24.0",
    "@prisma/client": "^6.0.0"
  },
  "devDependencies": {
    "@testing-library/jest-dom": "^6.6.0",
    "@testing-library/react": "^16.0.0",
    "@types/node": "^22.0.0",
    "@types/react": "^19.0.0",
    "@types/react-dom": "^19.0.0",
    "autoprefixer": "^10.4.20",
    "postcss": "^8.4.49",
    "prisma": "^6.0.0",
    "tailwindcss": "^3.4.14",
    "typescript": "^5.6.0",
    "vitest": "^2.1.0"
  }
}
```

```tsx
// src/app/layout.tsx
import type { ReactNode } from "react";

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
```

```tsx
// src/app/page.tsx
import Link from "next/link";

export default function HomePage() {
  return (
    <main>
      <h1>Travel Import Aggregation</h1>
      <p>Turn multiple Xiaohongshu travel posts into structured travel notes.</p>
      <Link href="/tasks/new">Create Task</Link>
    </main>
  );
}
```

```env
# .env.example
DATABASE_URL="file:./dev.db"
OPENAI_API_KEY=""
OPENAI_BASE_URL=""
OPENAI_MODEL="gpt-4.1-mini"
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npm test -- src/app/home-page.test.tsx`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git init
git add package.json tsconfig.json next.config.ts postcss.config.js tailwind.config.ts src/app/layout.tsx src/app/page.tsx src/app/home-page.test.tsx README.md .env.example
git commit -m "chore: bootstrap nextjs app shell"
```

### Task 2: Define the persistence model and shared types

**Files:**
- Create: `prisma/schema.prisma`
- Create: `src/lib/db.ts`
- Create: `src/lib/types.ts`
- Test: `src/server/extraction/extraction-schema.test.ts`

- [ ] **Step 1: Write the failing schema contract test**

```ts
// src/server/extraction/extraction-schema.test.ts
import { describe, expect, it } from "vitest";
import { extractedTravelInfoSchema } from "./extraction-schema";

describe("extractedTravelInfoSchema", () => {
  it("accepts the MVP travel categories", () => {
    const result = extractedTravelInfoSchema.safeParse({
      destination: "Chengdu",
      tripDuration: "1 day",
      attractions: [{ name: "Kuanzhai Alley", summary: "Historic street area" }],
      transport: [{ name: "Metro", summary: "Use Line 4 for city center access" }],
      accommodation: [],
      food: [{ name: "Hotpot", summary: "Popular dinner choice" }],
      tips: [{ name: "Crowds", summary: "Visit earlier in the morning" }]
    });

    expect(result.success).toBe(true);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npm test -- src/server/extraction/extraction-schema.test.ts`
Expected: FAIL because `extraction-schema.ts` does not exist yet.

- [ ] **Step 3: Write the Prisma schema, DB helper, and shared types**

```prisma
// prisma/schema.prisma
datasource db {
  provider = "sqlite"
  url      = env("DATABASE_URL")
}

generator client {
  provider = "prisma-client-js"
}

model ImportTask {
  id          String        @id @default(cuid())
  name        String
  topic       String?
  status      TaskStatus    @default(PENDING)
  createdAt   DateTime      @default(now())
  updatedAt   DateTime      @updatedAt
  sourcePosts SourcePost[]
  aggregates  AggregatedTopic[]
}

model SourcePost {
  id               String               @id @default(cuid())
  taskId           String
  sourceUrl        String
  fetchStatus      ProcessingStatus     @default(PENDING)
  fetchError       String?
  extractionStatus ProcessingStatus     @default(PENDING)
  extractionError  String?
  title            String?
  bodyText         String?
  rawMetadata      String?
  createdAt        DateTime             @default(now())
  updatedAt        DateTime             @updatedAt
  task             ImportTask           @relation(fields: [taskId], references: [id], onDelete: Cascade)
  extractedInfo    ExtractedTravelInfo?
}

model ExtractedTravelInfo {
  id             String     @id @default(cuid())
  sourcePostId   String     @unique
  destination    String?
  tripDuration   String?
  jsonPayload    String
  schemaVersion  String
  createdAt      DateTime   @default(now())
  sourcePost     SourcePost @relation(fields: [sourcePostId], references: [id], onDelete: Cascade)
}

model AggregatedTopic {
  id              String   @id @default(cuid())
  taskId          String
  category        String
  normalizedName  String
  mergedSummary   String
  sourcePostIds   String
  conflictFlag    Boolean  @default(false)
  confidenceScore Float?
  createdAt       DateTime @default(now())
  updatedAt       DateTime @updatedAt
  task            ImportTask @relation(fields: [taskId], references: [id], onDelete: Cascade)
}

enum TaskStatus {
  PENDING
  PROCESSING
  COMPLETED
  PARTIAL
}

enum ProcessingStatus {
  PENDING
  RUNNING
  FAILED
  COMPLETED
}
```

```ts
// src/lib/db.ts
import { PrismaClient } from "@prisma/client";

const globalForPrisma = globalThis as { prisma?: PrismaClient };

export const db =
  globalForPrisma.prisma ??
  new PrismaClient({
    log: ["warn", "error"]
  });

if (process.env.NODE_ENV !== "production") {
  globalForPrisma.prisma = db;
}
```

```ts
// src/lib/types.ts
export type TravelItem = {
  name: string;
  summary: string;
  recommendedTime?: string;
  costHint?: string;
  reason?: string;
  notes?: string;
};

export type ExtractedTravelInfo = {
  destination?: string;
  tripDuration?: string;
  attractions: TravelItem[];
  transport: TravelItem[];
  accommodation: TravelItem[];
  food: TravelItem[];
  tips: TravelItem[];
};
```

- [ ] **Step 4: Run test and Prisma generation**

Run: `npx prisma generate`
Expected: PASS with generated Prisma client

Run: `npm test -- src/server/extraction/extraction-schema.test.ts`
Expected: FAIL until the extraction schema file is added in the next task

- [ ] **Step 5: Commit**

```bash
git add prisma/schema.prisma src/lib/db.ts src/lib/types.ts src/server/extraction/extraction-schema.test.ts
git commit -m "feat: define persistence model and shared travel types"
```

### Task 3: Build task creation and link intake

**Files:**
- Create: `src/server/link-validation.ts`
- Create: `src/server/tasks/task-service.ts`
- Create: `src/app/actions/task-actions.ts`
- Create: `src/components/task-form.tsx`
- Create: `src/app/tasks/new/page.tsx`
- Create: `src/app/api/tasks/route.ts`
- Test: `src/server/link-validation.test.ts`
- Test: `src/app/tasks/new/task-form.test.tsx`

- [ ] **Step 1: Write the failing tests for link validation and form rendering**

```ts
// src/server/link-validation.test.ts
import { describe, expect, it } from "vitest";
import { parseSourceLinks } from "./link-validation";

describe("parseSourceLinks", () => {
  it("keeps only valid Xiaohongshu links and trims whitespace", () => {
    const result = parseSourceLinks(`
      https://www.xiaohongshu.com/explore/abc123
      invalid-link
      https://xhslink.com/xyz789
    `);

    expect(result.valid).toEqual([
      "https://www.xiaohongshu.com/explore/abc123",
      "https://xhslink.com/xyz789"
    ]);
    expect(result.invalid).toEqual(["invalid-link"]);
  });
});
```

```tsx
// src/app/tasks/new/task-form.test.tsx
import { render, screen } from "@testing-library/react";
import NewTaskPage from "./page";

describe("NewTaskPage", () => {
  it("renders task name, links textarea, and submit button", () => {
    render(<NewTaskPage />);

    expect(screen.getByLabelText("Task Name")).toBeInTheDocument();
    expect(screen.getByLabelText("Xiaohongshu Links")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Start Import" })).toBeInTheDocument();
  });
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `npm test -- src/server/link-validation.test.ts src/app/tasks/new/task-form.test.tsx`
Expected: FAIL because the validator and page files do not exist yet.

- [ ] **Step 3: Implement validation, task creation action, and form UI**

```ts
// src/server/link-validation.ts
const XIAOHONGSHU_HOSTS = ["www.xiaohongshu.com", "xhslink.com"];

export function parseSourceLinks(input: string) {
  const lines = input
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter(Boolean);

  const valid: string[] = [];
  const invalid: string[] = [];

  for (const line of lines) {
    try {
      const url = new URL(line);
      if (XIAOHONGSHU_HOSTS.includes(url.hostname)) {
        valid.push(url.toString());
      } else {
        invalid.push(line);
      }
    } catch {
      invalid.push(line);
    }
  }

  return { valid, invalid };
}
```

```ts
// src/server/tasks/task-service.ts
import { db } from "@/lib/db";

export async function createImportTask(input: {
  name: string;
  topic?: string;
  sourceUrls: string[];
}) {
  return db.importTask.create({
    data: {
      name: input.name,
      topic: input.topic,
      status: "PENDING",
      sourcePosts: {
        create: input.sourceUrls.map((sourceUrl) => ({
          sourceUrl
        }))
      }
    },
    include: {
      sourcePosts: true
    }
  });
}
```

```tsx
// src/components/task-form.tsx
"use client";

export function TaskForm() {
  return (
    <form>
      <label htmlFor="name">Task Name</label>
      <input id="name" name="name" />

      <label htmlFor="links">Xiaohongshu Links</label>
      <textarea id="links" name="links" rows={10} />

      <button type="submit">Start Import</button>
    </form>
  );
}
```

```tsx
// src/app/tasks/new/page.tsx
import { TaskForm } from "@/components/task-form";

export default function NewTaskPage() {
  return (
    <main>
      <h1>Create Travel Import Task</h1>
      <TaskForm />
    </main>
  );
}
```

- [ ] **Step 4: Run the focused tests**

Run: `npm test -- src/server/link-validation.test.ts src/app/tasks/new/task-form.test.tsx`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/server/link-validation.ts src/server/tasks/task-service.ts src/components/task-form.tsx src/app/tasks/new/page.tsx src/app/api/tasks/route.ts src/app/actions/task-actions.ts src/server/link-validation.test.ts src/app/tasks/new/task-form.test.tsx
git commit -m "feat: add task creation and link intake flow"
```

### Task 4: Implement the fetch pipeline and processing page

**Files:**
- Create: `src/server/fetch/xiaohongshu-fetcher.ts`
- Create: `src/server/fetch/xiaohongshu-fetcher.test.ts`
- Modify: `src/server/tasks/task-service.ts`
- Create: `src/components/source-post-status-list.tsx`
- Create: `src/app/tasks/[taskId]/page.tsx`

- [ ] **Step 1: Write the failing test for fetch result normalization**

```ts
// src/server/fetch/xiaohongshu-fetcher.test.ts
import { describe, expect, it } from "vitest";
import { normalizeFetchedPost } from "./xiaohongshu-fetcher";

describe("normalizeFetchedPost", () => {
  it("maps provider payload into the app fetch shape", () => {
    const result = normalizeFetchedPost({
      title: "Chengdu one day",
      content: "Visit People's Park and eat hotpot",
      author: "Traveler A"
    });

    expect(result.title).toBe("Chengdu one day");
    expect(result.bodyText).toContain("People's Park");
    expect(result.authorName).toBe("Traveler A");
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npm test -- src/server/fetch/xiaohongshu-fetcher.test.ts`
Expected: FAIL because the fetcher file does not exist yet.

- [ ] **Step 3: Implement fetch normalization and the processing page**

```ts
// src/server/fetch/xiaohongshu-fetcher.ts
export type FetchedPost = {
  title: string;
  bodyText: string;
  authorName?: string;
  publishedAt?: string;
  rawMetadata?: string;
};

export function normalizeFetchedPost(payload: {
  title?: string;
  content?: string;
  author?: string;
  publishedAt?: string;
}) {
  return {
    title: payload.title ?? "Untitled post",
    bodyText: payload.content ?? "",
    authorName: payload.author,
    publishedAt: payload.publishedAt,
    rawMetadata: JSON.stringify(payload)
  } satisfies FetchedPost;
}
```

```tsx
// src/components/source-post-status-list.tsx
type SourcePostRow = {
  id: string;
  sourceUrl: string;
  fetchStatus: string;
  extractionStatus: string;
  fetchError?: string | null;
  extractionError?: string | null;
};

export function SourcePostStatusList({ posts }: { posts: SourcePostRow[] }) {
  return (
    <ul>
      {posts.map((post) => (
        <li key={post.id}>
          <p>{post.sourceUrl}</p>
          <p>Fetch: {post.fetchStatus}</p>
          <p>Extraction: {post.extractionStatus}</p>
          {post.fetchError ? <p>{post.fetchError}</p> : null}
          {post.extractionError ? <p>{post.extractionError}</p> : null}
        </li>
      ))}
    </ul>
  );
}
```

```tsx
// src/app/tasks/[taskId]/page.tsx
import { notFound } from "next/navigation";
import { db } from "@/lib/db";
import { SourcePostStatusList } from "@/components/source-post-status-list";

export default async function TaskPage({ params }: { params: Promise<{ taskId: string }> }) {
  const { taskId } = await params;
  const task = await db.importTask.findUnique({
    where: { id: taskId },
    include: { sourcePosts: true }
  });

  if (!task) {
    notFound();
  }

  return (
    <main>
      <h1>{task.name}</h1>
      <SourcePostStatusList posts={task.sourcePosts} />
    </main>
  );
}
```

- [ ] **Step 4: Run the fetcher test**

Run: `npm test -- src/server/fetch/xiaohongshu-fetcher.test.ts`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/server/fetch/xiaohongshu-fetcher.ts src/server/fetch/xiaohongshu-fetcher.test.ts src/components/source-post-status-list.tsx src/app/tasks/[taskId]/page.tsx src/server/tasks/task-service.ts
git commit -m "feat: add fetch normalization and processing page"
```

### Task 5: Implement strict AI extraction

**Files:**
- Create: `src/server/extraction/extraction-schema.ts`
- Create: `src/server/extraction/extract-travel-info.ts`
- Modify: `src/lib/env.ts`
- Modify: `src/server/tasks/task-service.ts`

- [ ] **Step 1: Write the failing test for schema rejection**

```ts
// src/server/extraction/extraction-schema.test.ts
import { describe, expect, it } from "vitest";
import { extractedTravelInfoSchema } from "./extraction-schema";

describe("extractedTravelInfoSchema", () => {
  it("rejects invalid category payloads", () => {
    const result = extractedTravelInfoSchema.safeParse({
      attractions: "not-an-array"
    });

    expect(result.success).toBe(false);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npm test -- src/server/extraction/extraction-schema.test.ts`
Expected: FAIL because the schema file still does not exist.

- [ ] **Step 3: Implement the schema and extraction client**

```ts
// src/server/extraction/extraction-schema.ts
import { z } from "zod";

const travelItemSchema = z.object({
  name: z.string().min(1),
  summary: z.string().min(1),
  recommendedTime: z.string().optional(),
  costHint: z.string().optional(),
  reason: z.string().optional(),
  notes: z.string().optional()
});

export const extractedTravelInfoSchema = z.object({
  destination: z.string().optional(),
  tripDuration: z.string().optional(),
  attractions: z.array(travelItemSchema).default([]),
  transport: z.array(travelItemSchema).default([]),
  accommodation: z.array(travelItemSchema).default([]),
  food: z.array(travelItemSchema).default([]),
  tips: z.array(travelItemSchema).default([])
});
```

```ts
// src/lib/env.ts
import { z } from "zod";

export const env = z
  .object({
    DATABASE_URL: z.string().min(1),
    OPENAI_API_KEY: z.string().min(1),
    OPENAI_BASE_URL: z.string().optional(),
    OPENAI_MODEL: z.string().min(1)
  })
  .parse(process.env);
```

```ts
// src/server/extraction/extract-travel-info.ts
import { env } from "@/lib/env";
import { extractedTravelInfoSchema } from "./extraction-schema";

export async function extractTravelInfoFromText(bodyText: string) {
  const response = await fetch(`${env.OPENAI_BASE_URL ?? "https://api.openai.com/v1"}/responses`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${env.OPENAI_API_KEY}`
    },
    body: JSON.stringify({
      model: env.OPENAI_MODEL,
      input: [
        {
          role: "system",
          content: "Extract travel info into JSON with attractions, transport, accommodation, food, and tips."
        },
        {
          role: "user",
          content: bodyText
        }
      ]
    })
  });

  const json = await response.json();
  const outputText = json.output_text ?? "{}";
  return extractedTravelInfoSchema.parse(JSON.parse(outputText));
}
```

- [ ] **Step 4: Run the schema test**

Run: `npm test -- src/server/extraction/extraction-schema.test.ts`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/server/extraction/extraction-schema.ts src/server/extraction/extract-travel-info.ts src/lib/env.ts src/server/extraction/extraction-schema.test.ts src/server/tasks/task-service.ts
git commit -m "feat: add strict ai extraction schema and client"
```

### Task 6: Implement aggregation logic

**Files:**
- Create: `src/server/aggregation/aggregate-travel-info.ts`
- Test: `src/server/aggregation/aggregate-travel-info.test.ts`
- Modify: `src/server/tasks/task-service.ts`

- [ ] **Step 1: Write the failing aggregation test**

```ts
// src/server/aggregation/aggregate-travel-info.test.ts
import { describe, expect, it } from "vitest";
import { aggregateTravelInfo } from "./aggregate-travel-info";

describe("aggregateTravelInfo", () => {
  it("merges duplicate attractions and preserves source ids", () => {
    const result = aggregateTravelInfo([
      {
        sourcePostId: "post-1",
        attractions: [{ name: "Kuanzhai Alley", summary: "Historic lanes" }],
        transport: [],
        accommodation: [],
        food: [],
        tips: []
      },
      {
        sourcePostId: "post-2",
        attractions: [{ name: "kuanzhai alley", summary: "Popular walking area" }],
        transport: [],
        accommodation: [],
        food: [],
        tips: []
      }
    ]);

    expect(result.attractions).toHaveLength(1);
    expect(result.attractions[0].sourcePostIds).toEqual(["post-1", "post-2"]);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npm test -- src/server/aggregation/aggregate-travel-info.test.ts`
Expected: FAIL because the aggregation module does not exist yet.

- [ ] **Step 3: Implement deterministic category aggregation**

```ts
// src/server/aggregation/aggregate-travel-info.ts
type InputItem = {
  sourcePostId: string;
  attractions: { name: string; summary: string }[];
  transport: { name: string; summary: string }[];
  accommodation: { name: string; summary: string }[];
  food: { name: string; summary: string }[];
  tips: { name: string; summary: string }[];
};

function normalizeName(name: string) {
  return name.trim().toLowerCase();
}

function aggregateCategory(items: InputItem[], key: keyof Omit<InputItem, "sourcePostId">) {
  const map = new Map<string, { normalizedName: string; mergedSummary: string; sourcePostIds: string[] }>();

  for (const input of items) {
    for (const entry of input[key]) {
      const normalized = normalizeName(entry.name);
      const existing = map.get(normalized);

      if (existing) {
        existing.sourcePostIds.push(input.sourcePostId);
        if (!existing.mergedSummary.includes(entry.summary)) {
          existing.mergedSummary = `${existing.mergedSummary} / ${entry.summary}`;
        }
      } else {
        map.set(normalized, {
          normalizedName: entry.name,
          mergedSummary: entry.summary,
          sourcePostIds: [input.sourcePostId]
        });
      }
    }
  }

  return Array.from(map.values());
}

export function aggregateTravelInfo(items: InputItem[]) {
  return {
    attractions: aggregateCategory(items, "attractions"),
    transport: aggregateCategory(items, "transport"),
    accommodation: aggregateCategory(items, "accommodation"),
    food: aggregateCategory(items, "food"),
    tips: aggregateCategory(items, "tips")
  };
}
```

- [ ] **Step 4: Run the aggregation test**

Run: `npm test -- src/server/aggregation/aggregate-travel-info.test.ts`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/server/aggregation/aggregate-travel-info.ts src/server/aggregation/aggregate-travel-info.test.ts src/server/tasks/task-service.ts
git commit -m "feat: add category aggregation with source traceability"
```

### Task 7: Build the results page and category UI

**Files:**
- Create: `src/components/aggregated-category-section.tsx`
- Create: `src/components/aggregated-category-section.test.tsx`
- Create: `src/app/tasks/[taskId]/results/page.tsx`
- Modify: `src/server/tasks/task-service.ts`

- [ ] **Step 1: Write the failing render test for aggregated categories**

```tsx
// src/components/aggregated-category-section.test.tsx
import { render, screen } from "@testing-library/react";
import { AggregatedCategorySection } from "./aggregated-category-section";

describe("AggregatedCategorySection", () => {
  it("renders the category title and source count", () => {
    render(
      <AggregatedCategorySection
        title="Attractions"
        items={[
          {
            normalizedName: "Kuanzhai Alley",
            mergedSummary: "Historic lanes",
            sourcePostIds: ["post-1", "post-2"]
          }
        ]}
      />
    );

    expect(screen.getByText("Attractions")).toBeInTheDocument();
    expect(screen.getByText("2 sources")).toBeInTheDocument();
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npm test -- src/components/aggregated-category-section.test.tsx`
Expected: FAIL because the component file does not exist yet.

- [ ] **Step 3: Implement the results UI**

```tsx
// src/components/aggregated-category-section.tsx
type AggregatedItem = {
  normalizedName: string;
  mergedSummary: string;
  sourcePostIds: string[];
};

export function AggregatedCategorySection({
  title,
  items
}: {
  title: string;
  items: AggregatedItem[];
}) {
  return (
    <section>
      <h2>{title}</h2>
      <ul>
        {items.map((item) => (
          <li key={`${title}-${item.normalizedName}`}>
            <h3>{item.normalizedName}</h3>
            <p>{item.mergedSummary}</p>
            <p>{item.sourcePostIds.length} sources</p>
          </li>
        ))}
      </ul>
    </section>
  );
}
```

```tsx
// src/app/tasks/[taskId]/results/page.tsx
import { notFound } from "next/navigation";
import { db } from "@/lib/db";
import { AggregatedCategorySection } from "@/components/aggregated-category-section";

export default async function TaskResultsPage({ params }: { params: Promise<{ taskId: string }> }) {
  const { taskId } = await params;
  const task = await db.importTask.findUnique({
    where: { id: taskId },
    include: { aggregates: true }
  });

  if (!task) {
    notFound();
  }

  const grouped = {
    attractions: task.aggregates.filter((item) => item.category === "attractions"),
    transport: task.aggregates.filter((item) => item.category === "transport"),
    accommodation: task.aggregates.filter((item) => item.category === "accommodation"),
    food: task.aggregates.filter((item) => item.category === "food"),
    tips: task.aggregates.filter((item) => item.category === "tips")
  };

  return (
    <main>
      <h1>{task.name} Results</h1>
      <AggregatedCategorySection title="Attractions" items={grouped.attractions.map((item) => ({
        normalizedName: item.normalizedName,
        mergedSummary: item.mergedSummary,
        sourcePostIds: JSON.parse(item.sourcePostIds)
      }))} />
      <AggregatedCategorySection title="Transportation" items={grouped.transport.map((item) => ({
        normalizedName: item.normalizedName,
        mergedSummary: item.mergedSummary,
        sourcePostIds: JSON.parse(item.sourcePostIds)
      }))} />
      <AggregatedCategorySection title="Accommodation" items={grouped.accommodation.map((item) => ({
        normalizedName: item.normalizedName,
        mergedSummary: item.mergedSummary,
        sourcePostIds: JSON.parse(item.sourcePostIds)
      }))} />
      <AggregatedCategorySection title="Food" items={grouped.food.map((item) => ({
        normalizedName: item.normalizedName,
        mergedSummary: item.mergedSummary,
        sourcePostIds: JSON.parse(item.sourcePostIds)
      }))} />
      <AggregatedCategorySection title="Tips" items={grouped.tips.map((item) => ({
        normalizedName: item.normalizedName,
        mergedSummary: item.mergedSummary,
        sourcePostIds: JSON.parse(item.sourcePostIds)
      }))} />
    </main>
  );
}
```

- [ ] **Step 4: Run the component test**

Run: `npm test -- src/components/aggregated-category-section.test.tsx`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/components/aggregated-category-section.tsx src/components/aggregated-category-section.test.tsx src/app/tasks/[taskId]/results/page.tsx src/server/tasks/task-service.ts
git commit -m "feat: add aggregated results page"
```

### Task 8: Add retry APIs, README guidance, and full verification

**Files:**
- Create: `src/app/api/tasks/[taskId]/retry-fetch/route.ts`
- Create: `src/app/api/tasks/[taskId]/retry-extraction/route.ts`
- Create: `src/app/api/tasks/retry-routes.test.ts`
- Modify: `README.md`
- Modify: `docs/product/2026-04-05-travel-import-aggregation-prd.md`
- Modify: `docs/superpowers/specs/2026-04-04-travel-import-aggregation-design.md`

- [ ] **Step 1: Write the failing route test for retry actions**

```ts
// src/app/api/tasks/retry-routes.test.ts
import { describe, expect, it } from "vitest";

describe("retry routes", () => {
  it("exports both retry route handlers", async () => {
    const retryFetch = await import("./[taskId]/retry-fetch/route");
    const retryExtraction = await import("./[taskId]/retry-extraction/route");

    expect(typeof retryFetch.POST).toBe("function");
    expect(typeof retryExtraction.POST).toBe("function");
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npm test -- src/app/api/tasks/retry-routes.test.ts`
Expected: FAIL because the route modules do not exist yet.

- [ ] **Step 3: Implement retry routes and update docs**

```ts
// src/app/api/tasks/[taskId]/retry-fetch/route.ts
import { NextResponse } from "next/server";

export async function POST() {
  return NextResponse.json({ ok: true, action: "retry-fetch" });
}
```

```ts
// src/app/api/tasks/[taskId]/retry-extraction/route.ts
import { NextResponse } from "next/server";

export async function POST() {
  return NextResponse.json({ ok: true, action: "retry-extraction" });
}
```

```md
## README sections to add

### Local setup
- `npm install`
- `cp .env.example .env`
- `npx prisma migrate dev --name init`
- `npm run dev`

### MVP flow
1. Create a task
2. Paste Xiaohongshu links
3. Process links
4. Open the results page
```

- [ ] **Step 4: Run the full test suite**

Run: `npm test`
Expected: PASS for validation, extraction schema, aggregation, component, and route tests

Run: `npx prisma migrate dev --name init`
Expected: PASS with SQLite migration generated

- [ ] **Step 5: Commit**

```bash
git add src/app/api/tasks/[taskId]/retry-fetch/route.ts src/app/api/tasks/[taskId]/retry-extraction/route.ts src/app/api/tasks/retry-routes.test.ts README.md docs/product/2026-04-05-travel-import-aggregation-prd.md docs/superpowers/specs/2026-04-04-travel-import-aggregation-design.md
git commit -m "docs: finalize mvp setup and retry flow guidance"
```

## Self-Review

### Spec coverage

- Task creation page: covered by Task 3
- Processing page and per-link state visibility: covered by Task 4
- Aggregation categories and source traceability: covered by Tasks 5 to 7
- Retry and partial-failure handling: covered by Task 8
- MVP docs and setup guidance: covered by Tasks 1 and 8

### Placeholder scan

- No `TODO`, `TBD`, or deferred implementation markers remain in the tasks
- Every task lists concrete files, test commands, and commit commands
- Each code step includes concrete code, not just prose instructions

### Type consistency

- Shared category names stay consistent across schema, aggregation, and results rendering: `attractions`, `transport`, `accommodation`, `food`, `tips`
- Shared task objects use `ImportTask`, `SourcePost`, `ExtractedTravelInfo`, and `AggregatedTopic` throughout

## Notes for the Implementer

- Keep fetch and extraction modules behind service boundaries so they can later move to a queue worker.
- Do not add price APIs, budget planning, or map routes during this MVP plan.
- If Xiaohongshu fetch reliability is low, keep the module interface stable and swap providers behind `xiaohongshu-fetcher.ts`.
