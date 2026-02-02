import type {ReactNode} from 'react';
import clsx from 'clsx';
import Link from '@docusaurus/Link';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import Layout from '@theme/Layout';
import Heading from '@theme/Heading';
import { 
  CpuChipIcon, 
  BookOpenIcon, 
  BoltIcon, 
  ArrowPathIcon, 
  Square3Stack3DIcon, 
  WrenchScrewdriverIcon 
} from '@heroicons/react/24/outline';

import styles from './index.module.css';

function HomepageHeader() {
  const {siteConfig} = useDocusaurusContext();
  return (
    <header className={clsx('hero', styles.heroBanner)}>
      <div className="container">
        <img 
          src="/prima-delivery/img/logo.png" 
          alt="Prima Delivery" 
          className={styles.heroLogo}
        />
        <Heading as="h1" className={styles.heroTitle}>
          {siteConfig.title}
        </Heading>
        <p className={styles.heroSubtitle}>{siteConfig.tagline}</p>
        <div className={styles.buttons}>
          <Link
            className="button button--primary button--lg"
            to="/docs/intro">
            Get Started
          </Link>
          <Link
            className="button button--secondary button--lg"
            to="/docs/agents/overview">
            Browse Agents
          </Link>
        </div>
      </div>
    </header>
  );
}

function StatsSection() {
  return (
    <section className={styles.statsSection}>
      <div className="container">
        <div className={styles.statsGrid}>
          <div className={styles.statItem}>
            <div className={styles.statNumber}>108</div>
            <div className={styles.statLabel}>AI Agents</div>
          </div>
          <div className={styles.statItem}>
            <div className={styles.statNumber}>140</div>
            <div className={styles.statLabel}>Skills</div>
          </div>
          <div className={styles.statItem}>
            <div className={styles.statNumber}>72</div>
            <div className={styles.statLabel}>Plugins</div>
          </div>
        </div>
      </div>
    </section>
  );
}

type FeatureItem = {
  title: string;
  description: string;
  link: string;
  icon: ReactNode;
};

const FeatureList: FeatureItem[] = [
  {
    title: 'Specialized Agents',
    description: 'Domain experts for architecture, languages, infrastructure, security, AI/ML, and more.',
    link: '/docs/agents/overview',
    icon: <CpuChipIcon className={styles.featureIconSvg} />,
  },
  {
    title: 'Modular Skills',
    description: 'Knowledge packages with progressive disclosure - load expertise only when needed.',
    link: '/docs/skills/overview',
    icon: <BookOpenIcon className={styles.featureIconSvg} />,
  },
  {
    title: 'Workflow Plugins',
    description: 'Pre-configured bundles for full-stack development, security, ML pipelines, and incident response.',
    link: '/docs/plugins/overview',
    icon: <BoltIcon className={styles.featureIconSvg} />,
  },
  {
    title: 'Dual Platform',
    description: 'Works with both OpenCode and Claude Code for maximum flexibility.',
    link: '/docs/getting-started/installation',
    icon: <ArrowPathIcon className={styles.featureIconSvg} />,
  },
  {
    title: 'Model Tiers',
    description: 'Strategic model assignment (Opus, Sonnet, Haiku) for optimal performance and cost.',
    link: '/docs/architecture/model-tiers',
    icon: <Square3Stack3DIcon className={styles.featureIconSvg} />,
  },
  {
    title: 'Fully Customizable',
    description: 'Override agents, add custom skills, and extend with your own domain expertise.',
    link: '/docs/getting-started/configuration',
    icon: <WrenchScrewdriverIcon className={styles.featureIconSvg} />,
  },
];

function Feature({title, description, link, icon}: FeatureItem) {
  return (
    <div className={clsx('col col--4', styles.featureCol)}>
      <Link to={link} className={styles.featureCard}>
        <div className={styles.featureIcon}>
          {icon}
        </div>
        <Heading as="h3" className={styles.featureTitle}>{title}</Heading>
        <p className={styles.featureDescription}>{description}</p>
      </Link>
    </div>
  );
}

function FeaturesSection() {
  return (
    <section className={styles.features}>
      <div className="container">
        <Heading as="h2" className={styles.sectionTitle}>Features</Heading>
        <div className="row">
          {FeatureList.map((props, idx) => (
            <Feature key={idx} {...props} />
          ))}
        </div>
      </div>
    </section>
  );
}

function QuickStartSection() {
  return (
    <section className={styles.quickStart}>
      <div className="container">
        <Heading as="h2" className={styles.sectionTitle}>Quick Start</Heading>
        <div className={styles.codeBlocks}>
          <div className={styles.codeBlock}>
            <h3>OpenCode</h3>
            <pre><code>cp -r .opencode/ ~/your-project/</code></pre>
            <pre><code>@python-pro Help me optimize this function</code></pre>
          </div>
          <div className={styles.codeBlock}>
            <h3>Claude Code</h3>
            <pre><code>/plugin marketplace add prima-delivery</code></pre>
            <pre><code>/plugin install python-development</code></pre>
          </div>
        </div>
        <div className={styles.ctaButtons}>
          <Link
            className="button button--primary button--lg"
            to="/docs/getting-started/installation">
            Installation Guide
          </Link>
          <Link
            className="button button--secondary button--lg"
            to="/docs/getting-started/quick-start">
            Quick Start Tutorial
          </Link>
        </div>
      </div>
    </section>
  );
}

export default function Home(): ReactNode {
  const {siteConfig} = useDocusaurusContext();
  return (
    <Layout
      title="Home"
      description="Prima Delivery - Internal AI Development Toolkit with 108 Agents, 140 Skills, and 72 Plugins">
      <a href="#main-content" className="skip-link">Skip to main content</a>
      <HomepageHeader />
      <main id="main-content">
        <StatsSection />
        <FeaturesSection />
        <QuickStartSection />
      </main>
    </Layout>
  );
}
