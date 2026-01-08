# WordPress.com MCP Bundle

An [MCPB (MCP Bundle)](https://github.com/anthropics/mcpb) that connects AI assistants to WordPress.com's hosted MCP server.

## What it does

This bundle connects AI assistants like Claude Desktop, Cursor, and VS Code to WordPress.com's hosted MCP server, enabling:

- **Account Management**: Access profile, sites, and notifications
- **Site Analytics**: View statistics, traffic, and performance data  
- **Content Operations**: Search posts, comments, and site content
- **Site Administration**: Manage settings, plugins, and users

## How it works

This bundle connects to WordPress.com's hosted MCP server at `https://public-api.wordpress.com/wpcom/v2/mcp/v1`, which:

- Uses OAuth 2.1 for secure authentication (PKCE, dynamic client registration, token rotation)
- Handles all MCP protocol communication
- Provides all WordPress.com MCP tools
- Requires no local Node.js process or server

## Requirements

- A WordPress.com account with a paid plan
- MCP enabled on your WordPress.com account ([Enable MCP](https://developer.wordpress.com/docs/mcp/))
- An MCP-enabled AI client such as:
  - [Claude Desktop](https://claude.ai/download)
  - [Cursor](https://cursor.sh/)
  - [VS Code](https://code.visualstudio.com/)
  - [ChatGPT](https://chat.openai.com/)

## Installation

1. Download the [MCPB file](https://github.com/Automattic/wpcom-mcp-bundle/raw/refs/heads/trunk/wordpress-com-mcp.mcpb)
2. Double-click to install in your MCP-enabled AI client
3. Complete the OAuth 2.1 authentication flow in your browser when prompted
4. Grant access to your WordPress.com account

The OAuth 2.1 flow will automatically guide you through browser-based authorization. Your WordPress.com credentials are never stored locally; only secure, expiring access tokens are used.

## Usage Examples

Once connected, ask your AI assistant things like:

- "Show me my WordPress.com sites and visitor stats"
- "What are my most popular posts this month?"
- "Search for posts about 'technology' across my sites"
- "What plugins are installed on my site?"
- "Show me comments that need moderation"

## Authentication

The WordPress.com MCP server uses OAuth 2.1 for secure authentication. When you first connect:

1. Your browser will automatically open to the WordPress.com authorization page
2. Log in to your WordPress.com account (if you aren't already logged in)
3. Review and authorize the connection
4. You'll be redirected back to your AI client, which can now access your WordPress.com sites

### Managing Connections

You can disconnect your AI client at any time through your WordPress.com account:

1. Go to **Security → Connected Apps** in your WordPress.com account
2. Find your AI client in the list
3. Click **Disconnect** to revoke access

## MCP Tool Access

Access to specific MCP tools is restricted by the same restrictions applied to user roles on your WordPress.com sites. See the [WordPress.com MCP documentation](https://developer.wordpress.com/docs/mcp/) for details on tool access permissions.

## Troubleshooting

### Connection Issues

If you're having trouble connecting:

1. **Verify MCP is enabled**: Check that MCP is enabled on your WordPress.com account at [MCP Settings](https://wordpress.com/me/security/mcp)
2. **Check the URL**: The bundle connects to `https://public-api.wordpress.com/wpcom/v2/mcp/v1`
3. **Review authorization**: Make sure you completed the OAuth authorization flow in your browser
4. **Check connected apps**: Visit [Connected Apps](https://wordpress.com/me/security/connected-applications) to verify your client is connected
5. **Restart your client**: Try restarting your AI client application

### Disabling tools

If you disable any tools on your account or disable MCP on any sites, you will need to restart the MCP server connection in your AI client to refresh the list of available tools.

## Development

### Build from source

```bash
./build.sh
```

The build script will:
1. Validate `manifest.json`
2. Create the `.mcpb` bundle file with `manifest.json`, `README.md`, and `icon.png`

No Node.js or other dependencies are required to build the bundle.

## Documentation

For more information about WordPress.com MCP, see the [WordPress.com MCP documentation](https://developer.wordpress.com/docs/mcp/).

## License

GPL-2.0-or-later
