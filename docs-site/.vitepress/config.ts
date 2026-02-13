import { defineConfig } from 'vitepress'
import { apiSidebar } from './generated/api-sidebar'
import { guideSidebar } from './generated/guide-sidebar'

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
})
