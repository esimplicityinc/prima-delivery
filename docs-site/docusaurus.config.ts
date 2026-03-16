import {themes as prismThemes} from 'prism-react-renderer';
import type {Config} from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';

// Environment-aware configuration
const deployEnv = process.env.DEPLOY_ENV || 'local';
const siteUrl = process.env.DOCUSAURUS_URL || 'https://alvisprima.com';
const baseUrl = process.env.DOCUSAURUS_BASE_URL || '/';
const commitSha = process.env.COMMIT_SHA || '';
const commitUrl = process.env.COMMIT_URL || '';
const isDev = deployEnv === 'dev';

const config: Config = {
  title: 'Prima Delivery',
  tagline: 'Internal AI Development Toolkit - 108 Agents, 140 Skills, 72 Plugins',
  favicon: 'img/favicon.ico',

  future: {
    v4: true,
  },

  url: siteUrl,
  baseUrl: baseUrl,

  // Custom fields available to components via useDocusaurusContext()
  customFields: {
    deployEnv,
    commitSha,
    commitUrl,
    isDev,
  },

  organizationName: 'esimplicityinc',
  projectName: 'prima-delivery',
  trailingSlash: false,

  onBrokenLinks: 'warn',
  onBrokenMarkdownLinks: 'warn',

  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  markdown: {
    format: 'md',
  },

  presets: [
    [
      'classic',
      {
        docs: {
          sidebarPath: './sidebars.ts',
          editUrl: 'https://github.com/esimplicityinc/prima-delivery/tree/main/docs-site/',
          showLastUpdateTime: true,
          showLastUpdateAuthor: true,
        },
        blog: false, // Disable blog
        theme: {
          customCss: './src/css/custom.css',
        },
      } satisfies Preset.Options,
    ],
  ],

  themeConfig: {
    image: 'img/prima-delivery-social.png',
    // Dev environment banner showing deployed commit SHA
    ...(isDev && commitSha ? {
      announcementBar: {
        id: 'dev_banner',
        content: `DEV ENVIRONMENT — Deployed from <a href="${commitUrl}" target="_blank" rel="noopener noreferrer">${commitSha.slice(0, 7)}</a>`,
        backgroundColor: '#f59e0b',
        textColor: '#000000',
        isCloseable: false,
      },
    } : {}),
    colorMode: {
      defaultMode: 'dark',
      disableSwitch: false,
      respectPrefersColorScheme: true,
    },
    docs: {
      sidebar: {
        hideable: true,
        autoCollapseCategories: true,
      },
    },
    navbar: {
      title: 'Prima Delivery',
      logo: {
        alt: 'Prima Delivery Logo',
        src: 'img/logo.png',
        srcDark: 'img/logo.png',
      },
      items: [
        {
          type: 'docSidebar',
          sidebarId: 'docsSidebar',
          position: 'left',
          label: 'Documentation',
        },
        {
          to: '/docs/agents/overview',
          label: 'Agents',
          position: 'left',
        },
        {
          to: '/docs/skills/overview',
          label: 'Skills',
          position: 'left',
        },
        {
          to: '/docs/plugins/overview',
          label: 'Plugins',
          position: 'left',
        },

        {
          href: 'https://github.com/esimplicityinc/prima-delivery',
          label: 'GitHub',
          position: 'right',
        },
      ],
    },
    footer: {
      style: 'dark',
      links: [
        {
          title: 'Documentation',
          items: [
            {
              label: 'Getting Started',
              to: '/docs/intro',
            },
            {
              label: 'Agents',
              to: '/docs/agents/overview',
            },
            {
              label: 'Skills',
              to: '/docs/skills/overview',
            },
          ],
        },
        {
          title: 'Reference',
          items: [
            {
              label: 'Plugin Catalog',
              to: '/docs/plugins/overview',
            },
            {
              label: 'Usage Guide',
              to: '/docs/usage/commands',
            },
            {
              label: 'API Reference',
              to: '/docs/api/overview',
            },
          ],
        },
        {
          title: 'More',
          items: [
            {
              label: 'Architecture',
              to: '/docs/architecture/design-principles',
            },
            {
              label: 'GitHub',
              href: 'https://github.com/esimplicityinc/prima-delivery',
            },
          ],
        },
      ],
      copyright: `Copyright © ${new Date().getFullYear()} eSimplicity Inc. All Rights Reserved.`,
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
      additionalLanguages: ['bash', 'python', 'typescript', 'yaml', 'json', 'rust', 'go', 'java', 'csharp', 'ruby', 'php', 'sql'],
    },
    // Algolia search - placeholder for now
    // algolia: {
    //   appId: 'YOUR_APP_ID',
    //   apiKey: 'YOUR_SEARCH_API_KEY',
    //   indexName: 'prima-delivery',
    //   contextualSearch: true,
    // },
  } satisfies Preset.ThemeConfig,
};

export default config;
