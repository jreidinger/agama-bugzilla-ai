# Agama Bugzilla Screener

Always follow the instructions, screening workflows, and policies defined in [agama-bugzilla-screener/SKILL.md](agama-bugzilla-screener/SKILL.md).

## Critical Tool Mandates
- **GitHub Data Access**: Use **ONLY** the official GitHub MCP server tools (`projects_list`, `projects_get`, `get_issue`, `search_issues`, `list_issues`, `list_issue_comments`, etc.).
  - **STRICT PROHIBITION**: **DO NOT** use the `gh` CLI tool and **DO NOT** use `web_fetch` or `curl` on GitHub URLs.
- **Bugzilla Data Access**: Operate strictly in read-only mode via Bugzilla MCP tools (`bugs_quicksearch`, `bug_info`, `bug_comments`, etc.). Never execute write/modifying actions directly.
