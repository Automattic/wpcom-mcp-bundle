# WordPress.com MCP Bundle

An [MCPB (MCP Bundle)](https://github.com/anthropics/mcpb) implementation that provides AI assistants with access to WordPress.com tools and data.

## What it does

This bundle connects AI assistants like Claude Desktop to WordPress.com, enabling:

- **Account Management**: Access profile, sites, and notifications
- **Site Analytics**: View statistics, traffic, and performance data  
- **Content Operations**: Search posts, comments, and site content
- **Site Administration**: Manage settings, plugins, and users

## Installation

1. Download the [MCPB file](https://github.com/Automattic/wpcom-mcp-bundle/raw/refs/heads/trunk/wordpress-com-mcp.mcpb)
2. Double-click to install in Claude Desktop
3. Configure settings as needed

## Configuration

- **Log File Path** (optional): Specify the path to save logs; leave empty to disable logging.

## Usage Examples

Ask Claude things like:
- "Show me my WordPress.com sites and visitor stats"
- "What are my most popular posts this month?"
- "Search for posts about 'technology' across my sites"
- "What plugins are installed on my site?"

## Development

### Build from source
```bash
npm ci && npm run build
```

### Requirements
- Node.js ≥18.0.0

## License

GPL-2.0-or-later