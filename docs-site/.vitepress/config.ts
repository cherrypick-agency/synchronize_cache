import { defineConfig } from 'vitepress'
import { withMermaid } from 'vitepress-plugin-mermaid'
import { apiSidebar } from './generated/api-sidebar'
import { guideSidebar } from './generated/guide-sidebar'

export default withMermaid(defineConfig({
  title: 'offline_first_sync_drift',
  description: 'Offline-first synchronization library for Dart/Flutter built on Drift ORM',
  themeConfig: {
    nav: [
      { text: 'Guide', link: '/guide/_generated/offline_first_sync_drift_workspace/quick-start' },
      { text: 'API Reference', link: '/api/' },
      { text: 'vs Alternatives', link: '/comparison' },
      {
        text: 'GitHub',
        link: 'https://github.com/cherrypick-agency/synchronize_cache'
      }
    ],
    sidebar: {
      ...apiSidebar,
      ...guideSidebar,
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
}))
