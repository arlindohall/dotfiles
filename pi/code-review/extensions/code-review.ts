/**
 * Code Review Extension
 *
 * Registers a suite of lightweight tools for structured code review.
 * Each tool wraps a focused git/grep/find operation and returns concise,
 * pre-filtered output so the LLM context stays small.
 *
 * Tools are designed to be called in sequence by the code-review skill,
 * but work independently for ad-hoc use as well.
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import {
  truncateHead,
  DEFAULT_MAX_BYTES,
  DEFAULT_MAX_LINES,
  formatSize,
} from "@mariozechner/pi-coding-agent";
import { Type } from "@sinclair/typebox";

export default function (pi: ExtensionAPI) {
  // ── /review command ─────────────────────────────────────────────────
  pi.registerCommand("review", {
    description: "Run a structured code review of HEAD (or pass a base ref, e.g. /review main)",
    handler: async (args, ctx) => {
      const base = args?.trim() || "HEAD~1";
      pi.sendUserMessage(
        base === "HEAD~1"
          ? "Please do a code review of HEAD."
          : `Please do a code review using \`${base}\` as the base ref.`,
        { deliverAs: "followUp" }
      );
    },
  });

  // ── commit_info ──────────────────────────────────────────────────────
  pi.registerTool({
    name: "commit_info",
    label: "Commit Info",
    description:
      "Get structured metadata for a commit: hash, author, date, subject, body.",
    promptSnippet: "Show commit metadata (hash, author, date, subject, body)",
    parameters: Type.Object({
      ref: Type.Optional(
        Type.String({ description: "Commit ref (default: HEAD)" })
      ),
    }),
    async execute(_id, params, signal) {
      const ref = params.ref || "HEAD";
      const { stdout, stderr, code } = await pi.exec(
        "git",
        [
          "log",
          "--format=hash:    %H%nauthor:  %an <%ae>%ndate:    %ad%nsubject: %s%n---body---%n%b",
          `${ref}~1..${ref}`,
        ],
        { signal, timeout: 10000 }
      );
      if (code !== 0) throw new Error(stderr.trim() || `git log failed (exit ${code})`);
      return {
        content: [{ type: "text", text: stdout.trim() }],
        details: {},
      };
    },
  });

  // ── diff_stat ────────────────────────────────────────────────────────
  pi.registerTool({
    name: "diff_stat",
    label: "Diff Stat",
    description:
      "Show a file-level summary of what changed between two refs.",
    promptSnippet: "File-level change summary (--stat)",
    parameters: Type.Object({
      base: Type.Optional(
        Type.String({ description: "Base ref (default: HEAD~1)" })
      ),
    }),
    async execute(_id, params, signal) {
      const base = params.base || "HEAD~1";
      const { stdout, stderr, code } = await pi.exec(
        "git",
        ["diff", base, "HEAD", "--stat"],
        { signal, timeout: 10000 }
      );
      if (code !== 0) throw new Error(stderr.trim() || `git diff --stat failed`);
      return {
        content: [{ type: "text", text: stdout.trim() }],
        details: {},
      };
    },
  });

  // ── diff_full ────────────────────────────────────────────────────────
  pi.registerTool({
    name: "diff_full",
    label: "Full Diff",
    description:
      "Show the full unified diff of a change. Output is truncated if very large.",
    promptSnippet: "Full unified diff between two refs",
    parameters: Type.Object({
      base: Type.Optional(
        Type.String({ description: "Base ref (default: HEAD~1)" })
      ),
    }),
    async execute(_id, params, signal) {
      const base = params.base || "HEAD~1";
      const { stdout, stderr, code } = await pi.exec(
        "git",
        ["diff", base, "HEAD"],
        { signal, timeout: 30000 }
      );
      if (code !== 0) throw new Error(stderr.trim() || `git diff failed`);

      const truncation = truncateHead(stdout, {
        maxLines: DEFAULT_MAX_LINES,
        maxBytes: DEFAULT_MAX_BYTES,
      });
      let text = truncation.content;
      if (truncation.truncated) {
        text += `\n\n[Diff truncated: showing ${truncation.outputLines} of ${truncation.totalLines} lines (${formatSize(truncation.outputBytes)} of ${formatSize(truncation.totalBytes)}). Use \`read\` on individual files for the rest.]`;
      }
      return {
        content: [{ type: "text", text: text.trim() }],
        details: { truncated: truncation.truncated },
      };
    },
  });

  // ── changed_files ────────────────────────────────────────────────────
  pi.registerTool({
    name: "changed_files",
    label: "Changed Files",
    description:
      "List file paths changed between two refs, one per line.",
    promptSnippet: "List paths touched by the change",
    parameters: Type.Object({
      base: Type.Optional(
        Type.String({ description: "Base ref (default: HEAD~1)" })
      ),
    }),
    async execute(_id, params, signal) {
      const base = params.base || "HEAD~1";
      const { stdout, stderr, code } = await pi.exec(
        "git",
        ["diff", base, "HEAD", "--name-only"],
        { signal, timeout: 10000 }
      );
      if (code !== 0) throw new Error(stderr.trim() || `git diff --name-only failed`);
      return {
        content: [{ type: "text", text: stdout.trim() }],
        details: {},
      };
    },
  });

  // ── prior_version ────────────────────────────────────────────────────
  pi.registerTool({
    name: "prior_version",
    label: "Prior Version",
    description:
      "Show the contents of a file before the change, via git show.",
    promptSnippet: "Read a file as it was before the change",
    parameters: Type.Object({
      file: Type.String({ description: "Path to the file (repo-relative)" }),
      base: Type.Optional(
        Type.String({ description: "Base ref (default: HEAD~1)" })
      ),
    }),
    async execute(_id, params, signal) {
      const base = params.base || "HEAD~1";
      const { stdout, stderr, code } = await pi.exec(
        "git",
        ["show", `${base}:${params.file}`],
        { signal, timeout: 10000 }
      );
      if (code !== 0) {
        return {
          content: [
            {
              type: "text",
              text: `(file did not exist at ${base})`,
            },
          ],
          details: {},
        };
      }

      const truncation = truncateHead(stdout, {
        maxLines: DEFAULT_MAX_LINES,
        maxBytes: DEFAULT_MAX_BYTES,
      });
      let text = truncation.content;
      if (truncation.truncated) {
        text += `\n\n[Output truncated: showing ${truncation.outputLines} of ${truncation.totalLines} lines.]`;
      }
      return {
        content: [{ type: "text", text }],
        details: { truncated: truncation.truncated },
      };
    },
  });

  // ── find_callers ─────────────────────────────────────────────────────
  pi.registerTool({
    name: "find_callers",
    label: "Find Callers",
    description:
      "Find non-test source lines that reference a pattern. Excludes node_modules, vendor, sorbet, and test files.",
    promptSnippet: "Grep for a symbol in non-test source code",
    parameters: Type.Object({
      pattern: Type.String({ description: "Search pattern (fixed string or regex)" }),
      root: Type.Optional(
        Type.String({ description: "Search root directory (default: .)" })
      ),
    }),
    async execute(_id, params, signal) {
      const root = params.root || ".";
      const { stdout } = await pi.exec(
        "bash",
        [
          "-c",
          `grep -rn "${params.pattern.replace(/"/g, '\\"')}" "${root}" \
  --include="*.rb" --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" \
  --include="*.py" --include="*.go" --include="*.rs" --include="*.erb" --include="*.haml" \
  --exclude-dir=node_modules --exclude-dir=vendor --exclude-dir=sorbet \
  --exclude-dir=.git --exclude-dir=tmp --exclude-dir=log \
  | grep -v '_test\\.|_spec\\.|[.]test\\.|[.]spec\\.|/test/\\|/spec/\\|/tests/' \
  || true`,
        ],
        { signal, timeout: 30000 }
      );

      const text = stdout.trim() || "(no matches)";
      const truncation = truncateHead(text, {
        maxLines: DEFAULT_MAX_LINES,
        maxBytes: DEFAULT_MAX_BYTES,
      });
      return {
        content: [{ type: "text", text: truncation.content }],
        details: { truncated: truncation.truncated },
      };
    },
  });

  // ── find_tests ───────────────────────────────────────────────────────
  pi.registerTool({
    name: "find_tests",
    label: "Find Tests",
    description:
      "Find test files that reference a pattern. Returns file paths only.",
    promptSnippet: "Find test files referencing a symbol",
    parameters: Type.Object({
      pattern: Type.String({ description: "Search pattern" }),
      root: Type.Optional(
        Type.String({ description: "Search root directory (default: .)" })
      ),
    }),
    async execute(_id, params, signal) {
      const root = params.root || ".";
      const { stdout } = await pi.exec(
        "bash",
        [
          "-c",
          `grep -rln "${params.pattern.replace(/"/g, '\\"')}" "${root}" \
  --include="*.rb" --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" \
  --include="*.py" --include="*.go" --include="*.rs" \
  --exclude-dir=node_modules --exclude-dir=vendor --exclude-dir=sorbet \
  --exclude-dir=.git --exclude-dir=tmp --exclude-dir=log \
  | grep -E '_test[.]|_spec[.]|[.]test[.]|[.]spec[.]|/test/|/spec/|/tests/' \
  || true`,
        ],
        { signal, timeout: 30000 }
      );

      return {
        content: [{ type: "text", text: stdout.trim() || "(no test files found)" }],
        details: {},
      };
    },
  });

  // ── include_chain ────────────────────────────────────────────────────
  pi.registerTool({
    name: "include_chain",
    label: "Include Chain",
    description:
      "Extract include/extend/import/require lines from a file to show its dependency chain.",
    promptSnippet: "Show a file's include/import/extend dependency lines",
    parameters: Type.Object({
      file: Type.String({ description: "Path to the source file" }),
    }),
    async execute(_id, params, signal) {
      const { stdout } = await pi.exec(
        "bash",
        [
          "-c",
          `grep -nE '^\\s*(include|extend|import|require|from|use |requires_ancestor)' "${params.file}" || true`,
        ],
        { signal, timeout: 10000 }
      );

      return {
        content: [
          { type: "text", text: stdout.trim() || "(no include/import lines found)" },
        ],
        details: {},
      };
    },
  });

  // ── count_calls ──────────────────────────────────────────────────────
  pi.registerTool({
    name: "count_calls",
    label: "Count Calls",
    description:
      "Count how many non-test source lines reference a pattern. Useful for gauging how hot a code path is.",
    promptSnippet: "Count non-test references to a symbol",
    parameters: Type.Object({
      pattern: Type.String({ description: "Search pattern" }),
      root: Type.Optional(
        Type.String({ description: "Search root directory (default: .)" })
      ),
    }),
    async execute(_id, params, signal) {
      const root = params.root || ".";
      const { stdout } = await pi.exec(
        "bash",
        [
          "-c",
          `matches=$(grep -rn "${params.pattern.replace(/"/g, '\\"')}" "${root}" \
  --include="*.rb" --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" \
  --include="*.py" --include="*.go" --include="*.rs" --include="*.erb" --include="*.haml" \
  --exclude-dir=node_modules --exclude-dir=vendor --exclude-dir=sorbet \
  --exclude-dir=.git --exclude-dir=tmp --exclude-dir=log \
  | grep -v '_test\\.|_spec\\.|[.]test\\.|[.]spec\\.|/test/\\|/spec/\\|/tests/')
count=$(echo "$matches" | grep -c . || true)
echo "Total: $count"
echo "---"
echo "$matches"`,
        ],
        { signal, timeout: 30000 }
      );

      return {
        content: [{ type: "text", text: stdout.trim() }],
        details: {},
      };
    },
  });

  // ── memoization_check ────────────────────────────────────────────────
  pi.registerTool({
    name: "memoization_check",
    label: "Memoization Check",
    description:
      "Scan a file for method definitions and highlight which ones use memoization (||=) and which don't.",
    promptSnippet: "Check which methods in a file are/aren't memoized",
    parameters: Type.Object({
      file: Type.String({ description: "Path to the source file" }),
    }),
    async execute(_id, params, signal) {
      const { stdout } = await pi.exec(
        "bash",
        [
          "-c",
          `echo "=== Methods with memoization (||=) ==="
grep -n '||=' "${params.file}" || echo "(none)"
echo ""
echo "=== All method definitions ==="
grep -n '^\\s*def ' "${params.file}" || echo "(none)"`,
        ],
        { signal, timeout: 10000 }
      );

      return {
        content: [{ type: "text", text: stdout.trim() }],
        details: {},
      };
    },
  });
}
