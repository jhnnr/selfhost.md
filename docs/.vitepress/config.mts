import { defineConfig } from 'vitepress'
import { withMermaid } from 'vitepress-plugin-mermaid'

export default withMermaid(
  defineConfig({
    title: 'selfhost.md',
    description: 'Homelab Infrastructure & Selfhosting Documentation',
    base: '/selfhost.md/',
    cleanUrls: true,
    themeConfig: {
      siteTitle: 'selfhost.md',
      nav: [
        { text: 'Home', link: '/' },
        { text: 'Architecture', link: '/infrastructure-map' },
        { text: 'Inventory', link: '/inventory' },
        { text: 'Network', link: '/network/topology' },
        { text: 'Storage', link: '/storage/architecture' },
        { text: 'Nodes', link: '/nodes/pve01' }
      ],
      sidebar: [
        {
          text: 'Architecture & Inventory',
          items: [
            { text: 'Infrastructure Map', link: '/infrastructure-map' },
            { text: 'Inventory & Registry', link: '/inventory' },
            { text: 'Storage Architecture', link: '/storage/architecture' }
          ]
        },
        {
          text: 'Network & Security',
          items: [
            { text: 'Network Topology', link: '/network/topology' }
          ]
        },
        {
          text: 'Compute & Workloads',
          items: [
            { text: 'Proxmox Host (pve01)', link: '/nodes/pve01' },
            { text: 'qBittorrent (CT 105)', link: '/containers/ct105-qbit' }
          ]
        },
        {
          text: 'Automation & Hooks',
          items: [
            { text: 'Discord Notification', link: '/scripts/discord-notification' },
            { text: 'qBittorrent Relocate', link: '/scripts/qbit-relocate' }
          ]
        }
      ],
      socialLinks: [
        { icon: 'github', link: 'https://github.com/jhnnr/selfhost.md' }
      ],
      search: {
        provider: 'local'
      },
      footer: {
        message: 'Zero Secrets Policy strictly enforced.',
        copyright: 'Copyright © jhnnr'
      }
    },
    mermaid: {
      // Mermaid configuration
    }
  })
)
