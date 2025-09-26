/**
 * MCP WordPress.com Remote Proxy for MCPB
 *
 * This wraps @automattic/mcp-wordpress-remote with WordPress.com specific
 * default configurations for seamless WordPress.com integration in MCPB.
 */

import { join } from 'node:path';

// Import logger for consistent logging with the underlying library
let logger: any;
try {
  // Try to import logger from the library for consistent logging
  const lib = await import('@automattic/mcp-wordpress-remote/lib');
  logger = lib.logger;
} catch (error) {
  // Fallback to console if library not available
  logger = {
    info: (msg: string, context?: string) => console.error(`[${context || 'WPCOM-PROXY'}] ${msg}`),
    error: (msg: string, context?: string, err?: any) => console.error(`[${context || 'WPCOM-PROXY'}] ${msg}`, err || ''),
    warn: (msg: string, context?: string, err?: any) => console.error(`[${context || 'WPCOM-PROXY'}] WARNING: ${msg}`, err || ''),
    debug: (msg: string, context?: string, data?: any) => console.error(`[${context || 'WPCOM-PROXY'}] DEBUG: ${msg}`, data || '')
  };
}

// Enhanced error handling for MCPB compatibility
process.on('uncaughtException', (error) => {
  logger.error('Uncaught Exception:', 'WPCOM-PROXY', error);
  logger.error('Stack:', 'WPCOM-PROXY', error.stack);
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  logger.error('Unhandled Rejection at:', 'WPCOM-PROXY', promise);
  logger.error('Reason:', 'WPCOM-PROXY', reason);
  process.exit(1);
});

// Handle SIGTERM gracefully for MCPB
process.on('SIGTERM', () => {
  logger.info('Received SIGTERM, shutting down gracefully...', 'WPCOM-PROXY');
  process.exit(0);
});

process.on('SIGINT', () => {
  logger.info('Received SIGINT, shutting down gracefully...', 'WPCOM-PROXY');
  process.exit(0);
});

// WordPress.com specific default configuration
const WPCOM_DEFAULTS = {
  // WordPress.com public API endpoint
  WP_API_URL: 'https://public-api.wordpress.com/wpcom/v2/mcp/v1',

  // OAuth configuration optimized for WordPress.com
  WP_OAUTH_CLIENT_ID: '121755', // Default WordPress.com MCP client ID
  OAUTH_ENABLED: 'true',
  OAUTH_FLOW_TYPE: 'implicit',
  OAUTH_SCOPES: 'global',
  OAUTH_USE_PKCE: 'false',
  OAUTH_RESOURCE_INDICATOR: 'false',
  OAUTH_CALLBACK_PORT: '3000',
  OAUTH_HOST: '127.0.0.1',
  OAUTH_AUTHORIZE_ENDPOINT: 'https://public-api.wordpress.com/oauth2/authorize',
  OAUTH_TOKEN_ENDPOINT: 'https://public-api.wordpress.com/oauth2/token',

  // WordPress.com specific config directory
  WPCOM_MCP_CONFIG_DIR:
    process.env.WPCOM_MCP_CONFIG_DIR ||
    join(process.env.HOME || process.env.USERPROFILE || '.', '.mcp-auth'),
};

/**
 * Set up environment with WordPress.com defaults while preserving user overrides
 */
function setupWordPressComEnvironment(): void {
  // Apply WordPress.com defaults only if not already set by user
  Object.entries(WPCOM_DEFAULTS).forEach(([key, defaultValue]) => {
    if (!process.env[key]) {
      process.env[key] = defaultValue;
    }
  });

  // Log the configuration being used
  logger.info(`Using WordPress.com API: ${process.env.WP_API_URL}`, 'WPCOM-PROXY');
  logger.info(`OAuth enabled: ${process.env.OAUTH_ENABLED}`, 'WPCOM-PROXY');
  logger.info(`Callback port: ${process.env.OAUTH_CALLBACK_PORT}`, 'WPCOM-PROXY');

  if (process.env.JWT_TOKEN) {
    logger.info('Using JWT token authentication', 'WPCOM-PROXY');
  } else if (process.env.OAUTH_ENABLED === 'true') {
    logger.info(
      `Using OAuth authentication (client ID: ${process.env.WP_OAUTH_CLIENT_ID})`,
      'WPCOM-PROXY'
    );
    logger.info(`OAuth flow type: ${process.env.OAUTH_FLOW_TYPE}`, 'WPCOM-PROXY');
    logger.info(`OAuth scopes: ${process.env.OAUTH_SCOPES}`, 'WPCOM-PROXY');
  }
}

/**
 * Main execution function
 */
async function main(): Promise<void> {
  try {
    logger.info('Starting WordPress.com MCP Remote Proxy for MCPB', 'WPCOM-PROXY');
    logger.info(`Node.js version: ${process.version}`, 'WPCOM-PROXY');
    logger.info(`Working directory: ${process.cwd()}`, 'WPCOM-PROXY');

    // Set up WordPress.com specific environment
    setupWordPressComEnvironment();

    // Note: cleanupExpiredTokens is not exported from the public lib API
    // This is handled internally by the WordPress proxy when it starts
    logger.info('Token cleanup will be handled by the WordPress proxy internally', 'WPCOM-PROXY');

    // Import and run the WordPress proxy directly (like proxy.ts does)
    logger.info('Launching WordPress Remote proxy...', 'WPCOM-PROXY');

    try {
      // Import the entire WordPress proxy module (bundled)
      // The module will execute its main function automatically
      await import('@automattic/mcp-wordpress-remote');
      logger.info('WordPress Remote proxy launched successfully', 'WPCOM-PROXY');
    } catch (importError: any) {
      logger.error(`Failed to import @automattic/mcp-wordpress-remote: ${importError.message}`, 'WPCOM-PROXY');
      logger.error('Please ensure @automattic/mcp-wordpress-remote is installed', 'WPCOM-PROXY');
      
      // More detailed error information for debugging
      logger.debug('Import error details:', 'WPCOM-PROXY', {
        message: importError.message,
        code: importError.code,
        stack: importError.stack
      });
      
      process.exit(1);
    }

  } catch (error: any) {
    logger.error(`Error in main function: ${error.message}`, 'WPCOM-PROXY', error);
    logger.error(`Stack trace: ${error.stack}`, 'WPCOM-PROXY');
    process.exit(1);
  }
}

// Run the proxy with enhanced error handling
main().catch(error => {
  logger.error(`Fatal error in main(): ${error.message}`, 'WPCOM-PROXY', error);
  logger.error(`Fatal error stack: ${error.stack}`, 'WPCOM-PROXY');
  process.exit(1);
});
