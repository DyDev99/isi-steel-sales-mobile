## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

Rules:
- For codebase questions, first run `graphify query "<question>"` when graphify-out/graph.json exists. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).
- Before refactoring shared infrastructure, run `graphify affected "<symbol>" --depth 1` to get the real blast radius.

Dart-specific, and it matters:
- **Name classes, not files, in `path` queries.** Dart `package:` imports resolve to URI nodes with no outgoing edges, so file-to-file paths fail. Cross-file traversal happens via `references`. Use `graphify path "customer_repository_impl.dart" "CustomerLocalDataSource"`, not `... "customer_local_data_source.dart"`.
- Dart is extracted by regex, not tree-sitter. A missing edge means "not extracted", not "does not exist" — fall back to grep for specific lines.

Setup, ignore rules, viewing the graph, and known limitations: `docs/GRAPHIFY.md`.
Not installed? `uv tool install graphifyy && graphify install && graphify claude install` (needs Python 3.10+).
