import { defineConfig } from 'vitepress'

let apiSidebar: any[] = []
try {
  apiSidebar = (await import('./generated/api-sidebar.js')).default
} catch {
  // Generated API sidebar not yet available — will be created by dartdoc_vitepress
}

let guideSidebar: any[] = []
try {
  guideSidebar = (await import('./generated/guide-sidebar.js')).default
} catch {
  // Generated guide sidebar not yet available
}

export default defineConfig({
  title: 'offline_first_sync_drift',
  description: 'Offline-first synchronization library for Dart/Flutter built on Drift ORM',
  themeConfig: {
    nav: [
      { text: 'Guide', link: '/guide/quick-start' },
      { text: 'API Reference', link: '/api/' },
      {
        text: 'GitHub',
        link: 'https://github.com/cherrypick-agency/synchronize_cache'
      }
    ],
    sidebar: {
      '/guide/': guideSidebar.length > 0 ? guideSidebar : [
        {
          text: 'Getting Started',
          items: [
            { text: 'Quick Start', link: '/guide/quick-start' },
            { text: 'Database & Tables', link: '/guide/database-tables' },
          ]
        },
        {
          text: 'Guides',
          items: [
            { text: 'Simple Cache', link: '/guide/simple-cache' },
            { text: 'Advanced Cache', link: '/guide/advanced-cache' },
            { text: 'Flutter Integration', link: '/guide/flutter-integration' },
            { text: 'Backend & Transport', link: '/guide/backend-transport' },
            { text: 'Testing', link: '/guide/testing' },
          ]
        },
        {
          text: 'Deep Dive',
          items: [
            { text: 'SyncEngine Lifecycle', link: '/guide/sync-engine' },
            { text: 'Events & Exceptions', link: '/guide/events-exceptions' },
            { text: 'Architecture & Internals', link: '/guide/architecture' },
            { text: 'Performance & Optimization', link: '/guide/performance' },
            { text: 'Migration & Schema', link: '/guide/migration' },
          ]
        },
        {
          text: 'Reference',
          items: [
            { text: 'Troubleshooting & FAQ', link: '/guide/troubleshooting' },
          ]
        }
      ],
      '/api/': apiSidebar
    },
    socialLinks: [
      { icon: 'github', link: 'https://github.com/cherrypick-agency/synchronize_cache' }
    ],
    search: {
      provider: 'local'
    },
    footer: {
      message: 'Built with VitePress',
      copyright: 'Copyright © 2025-present Cherrypick Agency'
    }
  }
})
