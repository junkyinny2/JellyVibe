import { execSync } from "node:child_process";
import { existsSync, readFileSync, writeFileSync } from "node:fs";
import path from "node:path";

const nowIso = new Date().toISOString();

/* ------------------------------
   Utility: run shell commands
--------------------------------*/
function run(command) {
    try {
        const output = execSync(command, {
            encoding: "utf8",
            stdio: ["ignore", "pipe", "pipe"]
        });

        return output
            .replace(/\r\n/g, "\n")
            .split("\n")
            .filter((line) => !line.startsWith("warning: in the working copy of"))
            .join("\n")
            .trim();
    } catch (error) {
        const stdout = error?.stdout ? String(error.stdout) : "";
        const stderr = error?.stderr ? String(error.stderr) : "";
        const details = `${stdout}\n${stderr}`.trim();
        throw new Error(`Command failed: ${command}${details ? `\n${details}` : ""}`);
    }
}

/* ------------------------------
   NEW: Auto-detect baseline ref
--------------------------------*/
function detectBaseRef() {
    // User override always wins
    if (process.env.DIFF_BASE) {
        return process.env.DIFF_BASE.trim();
    }

    // Try most recent tag
    try {
        const tag = run("git describe --tags --abbrev=0");
        if (tag) return tag.trim();
    } catch {
        // ignore
    }

    // Fallback: first commit in repo
    const firstCommit = run("git rev-list --max-parents=0 HEAD").trim();
    return firstCommit;
}

const baseRef = detectBaseRef();
console.log(`Using baseline: ${baseRef}`);

/* ------------------------------
   Parse diff status lines
--------------------------------*/
function parseStatusLine(line) {
    const parts = line.split("\t");
    const statusToken = parts[0] || "";
    const statusCode = statusToken.charAt(0);

    if ((statusCode === "R" || statusCode === "C") && parts.length >= 3) {
        return {
            statusCode,
            rawStatus: statusToken,
            oldPath: parts[1],
            filePath: parts[2],
            display: `${parts[1]} -> ${parts[2]}`
        };
    }

    return {
        statusCode,
        rawStatus: statusToken,
        oldPath: "",
        filePath: parts[1] || "",
        display: parts[1] || ""
    };
}

function safeSectionList(entries, formatter) {
    if (entries.length === 0) return "- None";
    return entries.map(formatter).join("\n");
}

/* ------------------------------
   Auto-summary block builder
--------------------------------*/
function buildAutoSummaryBlock(data) {
    const topAreas = data.topAreas.slice(0, 10);
    const areaLines = topAreas.length
        ? topAreas.map((item, idx) => `${idx + 1}. ${item.area}: ${item.count} files`).join("\n")
        : "1. (none): 0 files";

    return [
        "<!-- AUTO_DIFF_SUMMARY_START -->",
        "## Upstream Difference Snapshot",
        "",
        `- Baseline: ${data.baseRef}`,
        `- Generated: ${data.generatedAt}`,
        `- Total changed files: ${data.totalFiles}`,
        `- Line delta: +${data.insertions} / -${data.deletions}`,
        `- Status counts: A ${data.statusCounts.A}, M ${data.statusCounts.M}, D ${data.statusCounts.D}, R ${data.statusCounts.R}, C ${data.statusCounts.C}`,
        "",
        "Top changed areas:",
        "",
        areaLines,
        "",
        "<!-- AUTO_DIFF_SUMMARY_END -->"
    ].join("\n");
}

function upsertAutoSummaryBlock(existingText, autoBlock) {
    const markerPattern = /<!-- AUTO_DIFF_SUMMARY_START -->[\s\S]*?<!-- AUTO_DIFF_SUMMARY_END -->/;

    if (markerPattern.test(existingText)) {
        return existingText.replace(markerPattern, autoBlock);
    }

    if (existingText.trim().length === 0) {
        return `${autoBlock}\n`;
    }

    const lines = existingText.split("\n");
    if (lines[0].startsWith("# ")) {
        return [lines[0], "", autoBlock, "", ...lines.slice(1)].join("\n");
    }

    return `${autoBlock}\n\n${existingText}`;
}

/* ------------------------------
   Collect git diff data
--------------------------------*/
const statusOutput = run(`git diff --name-status ${baseRef}`);
const numstatOutput = run(`git diff --numstat ${baseRef}`);
const untrackedOutput = run("git ls-files --others --exclude-standard");

const statusEntries = statusOutput
    ? statusOutput
        .split("\n")
        .filter((line) => line.trim().length > 0)
        .map(parseStatusLine)
        .filter((entry) => entry.filePath.length > 0)
    : [];

const trackedDiffPaths = new Set(statusEntries.map((entry) => entry.filePath));

if (untrackedOutput) {
    for (const filePath of untrackedOutput.split("\n").filter((line) => line.trim().length > 0)) {
        if (!trackedDiffPaths.has(filePath)) {
            statusEntries.push({
                statusCode: "A",
                rawStatus: "A",
                oldPath: "",
                filePath,
                display: filePath
            });
            trackedDiffPaths.add(filePath);
        }
    }
}

/* ------------------------------
   Bucket status codes
--------------------------------*/
const statusBuckets = {
    A: [], M: [], D: [], R: [], C: [],
    T: [], U: [], X: [], B: [], OTHER: []
};

for (const entry of statusEntries) {
    if (statusBuckets[entry.statusCode]) {
        statusBuckets[entry.statusCode].push(entry);
    } else {
        statusBuckets.OTHER.push(entry);
    }
}

for (const key of Object.keys(statusBuckets)) {
    statusBuckets[key].sort((a, b) => a.display.localeCompare(b.display));
}

/* ------------------------------
   Count insertions/deletions
--------------------------------*/
let insertions = 0;
let deletions = 0;

if (numstatOutput) {
    for (const line of numstatOutput.split("\n")) {
        const parts = line.split("\t");
        if (parts.length < 3) continue;

        const add = parts[0] === "-" ? 0 : Number.parseInt(parts[0], 10);
        const del = parts[1] === "-" ? 0 : Number.parseInt(parts[1], 10);

        if (!Number.isNaN(add)) insertions += add;
        if (!Number.isNaN(del)) deletions += del;
    }
}

/* ------------------------------
   Area breakdown
--------------------------------*/
const areaCounts = new Map();
for (const entry of statusEntries) {
    const slashIdx = entry.filePath.indexOf("/");
    const area = slashIdx > -1 ? entry.filePath.slice(0, slashIdx) : "(root)";
    areaCounts.set(area, (areaCounts.get(area) || 0) + 1);
}

const topAreas = [...areaCounts.entries()]
    .map(([area, count]) => ({ area, count }))
    .sort((a, b) => b.count - a.count || a.area.localeCompare(b.area));

/* ------------------------------
   Status counts
--------------------------------*/
const statusCounts = {
    A: statusBuckets.A.length,
    M: statusBuckets.M.length,
    D: statusBuckets.D.length,
    R: statusBuckets.R.length,
    C: statusBuckets.C.length,
    T: statusBuckets.T.length,
    U: statusBuckets.U.length,
    X: statusBuckets.X.length,
    B: statusBuckets.B.length,
    OTHER: statusBuckets.OTHER.length
};

/* ------------------------------
   Write changelog.md
--------------------------------*/
const changelogPath = path.resolve(process.cwd(), "changelog.md");
const featuresPath = path.resolve(process.cwd(), "features.md");

const summaryTableRows = [
    `| Added | ${statusCounts.A} |`,
    `| Modified | ${statusCounts.M} |`,
    `| Deleted | ${statusCounts.D} |`,
    `| Renamed | ${statusCounts.R} |`,
    `| Copied | ${statusCounts.C} |`
];

if (statusCounts.OTHER > 0) {
    summaryTableRows.push(`| Other | ${statusCounts.OTHER} |`);
}

const areaTableRows = topAreas.length
    ? topAreas.map((item) => `| ${item.area} | ${item.count} |`)
    : ["| (none) | 0 |"];

const changelogContent = [
    "# Changelog",
    "",
    "Difference tracker between this fork and upstream Jellyfin Roku source.",
    "",
    `- Baseline: ${baseRef}`,
    `- Generated: ${nowIso}`,
    "- Refresh command: npm run docs:update-diff",
    "",
    "## Summary",
    "",
    `- Total changed files: ${statusEntries.length}`,
    `- Total line delta: +${insertions} / -${deletions}`,
    "",
    "| Status | Count |",
    "| --- | ---: |",
    ...summaryTableRows,
    "",
    "## Changed Areas",
    "",
    "| Area | Files Changed |",
    "| --- | ---: |",
    ...areaTableRows,
    "",
    `## Added Files (${statusBuckets.A.length})`,
    "",
    safeSectionList(statusBuckets.A, (entry) => `- ${entry.filePath}`),
    "",
    `## Modified Files (${statusBuckets.M.length})`,
    "",
    safeSectionList(statusBuckets.M, (entry) => `- ${entry.filePath}`),
    "",
    `## Deleted Files (${statusBuckets.D.length})`,
    "",
    safeSectionList(statusBuckets.D, (entry) => `- ${entry.filePath}`),
    "",
    `## Renamed Files (${statusBuckets.R.length})`,
    "",
    safeSectionList(statusBuckets.R, (entry) => `- ${entry.oldPath} -> ${entry.filePath}`),
    "",
    `## Copied Files (${statusBuckets.C.length})`,
    "",
    safeSectionList(statusBuckets.C, (entry) => `- ${entry.oldPath} -> ${entry.filePath}`),
    ""
].join("\n");

writeFileSync(changelogPath, changelogContent, "utf8");

/* ------------------------------
   Write features.md with auto-block
--------------------------------*/
const featureAutoBlock = buildAutoSummaryBlock({
    baseRef,
    generatedAt: nowIso,
    totalFiles: statusEntries.length,
    insertions,
    deletions,
    statusCounts,
    topAreas
});

if (existsSync(featuresPath)) {
    const existingFeatures = readFileSync(featuresPath, "utf8");
    const updated = upsertAutoSummaryBlock(existingFeatures, featureAutoBlock);
    writeFileSync(featuresPath, updated.endsWith("\n") ? updated : `${updated}\n`, "utf8");
} else {
    const defaultFeatures = [
        "# Features",
        "",
        "Functional additions and UX changes in this fork versus upstream Jellyfin Roku source.",
        "",
        featureAutoBlock,
        "",
        "## Feature Additions",
        "",
        "(Add your feature notes here)",
        ""
    ].join("\n");

    writeFileSync(featuresPath, defaultFeatures, "utf8");
}

console.log(`Updated changelog.md and features.md against baseline '${baseRef}'.`);
console.log(`Changed files: ${statusEntries.length}, line delta: +${insertions} / -${deletions}`);
