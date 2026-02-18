<script setup lang="ts">
import { computed } from 'vue'
import { useData, withBase } from 'vitepress'

const { frontmatter, page, site } = useData()

const libraryDirName = computed(() => {
  const parts = page.value.relativePath.split('/')
  if (parts.length >= 2 && parts[0] === 'api') {
    return parts[1]
  }
  return null
})

const libraryDisplayName = computed(() => {
  return frontmatter.value.library ?? frontmatter.value.title ?? libraryDirName.value
})

const category = computed(() => frontmatter.value.category ?? null)

const pageTitle = computed(() => frontmatter.value.title ?? null)

const sourceUrl = computed(() => frontmatter.value.sourceUrl ?? null)

const isLibraryOverview = computed(() => {
  return page.value.relativePath.endsWith('/index.md') &&
    page.value.relativePath.startsWith('api/') &&
    page.value.relativePath.split('/').length === 3
})

const packageName = computed(() => {
  // Site title is "PackageName API" — extract just the name.
  const title = site.value.title ?? ''
  return title.replace(/ API$/, '') || title
})

// Skip duplicate: when package name == library name, show only one
const isDuplicateName = computed(() => {
  return packageName.value === libraryDisplayName.value
})
</script>

<template>
  <!-- Library overview page: API › LibraryName -->
  <div v-if="isLibraryOverview && libraryDirName" class="api-breadcrumb">
    <div class="breadcrumb-trail">
      <a :href="withBase('/api/')" class="breadcrumb-link">API</a>
      <span class="breadcrumb-separator">›</span>
      <span class="breadcrumb-current">{{ libraryDisplayName }}</span>
    </div>
    <a v-if="sourceUrl" :href="sourceUrl" target="_blank" rel="noopener" class="source-link" title="View source">
      <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="16 18 22 12 16 6"/><polyline points="8 6 2 12 8 18"/><line x1="14" y1="4" x2="10" y2="20"/></svg>
    </a>
  </div>

  <!-- Element page: LibraryName › Category › ElementTitle -->
  <div v-else-if="libraryDirName && category" class="api-breadcrumb">
    <div class="breadcrumb-trail">
      <a :href="withBase(`/api/${libraryDirName}/`)" class="breadcrumb-link">{{ libraryDisplayName }}</a>
      <span class="breadcrumb-separator">›</span>
      <span class="breadcrumb-category">{{ category }}</span>
      <template v-if="pageTitle">
        <span class="breadcrumb-separator">›</span>
        <span class="breadcrumb-current">{{ pageTitle }}</span>
      </template>
    </div>
    <a v-if="sourceUrl" :href="sourceUrl" target="_blank" rel="noopener" class="source-link" title="View source">
      <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="16 18 22 12 16 6"/><polyline points="8 6 2 12 8 18"/><line x1="14" y1="4" x2="10" y2="20"/></svg>
    </a>
  </div>
</template>

<style scoped>
.api-breadcrumb {
  display: flex;
  align-items: center;
  justify-content: space-between;
  font-size: 0.85em;
  margin-bottom: 0.5em;
  color: var(--vp-c-text-3);
  line-height: 1.5;
}

.breadcrumb-trail {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 0;
}

.breadcrumb-link {
  color: var(--vp-c-brand-1);
  text-decoration: none;
  transition: color 0.2s;
}

.breadcrumb-link:hover {
  color: var(--vp-c-brand-2);
  text-decoration: underline;
}

.breadcrumb-separator {
  margin: 0 0.4em;
  color: var(--vp-c-text-3);
}

.breadcrumb-category {
  color: var(--vp-c-text-2);
}

.breadcrumb-current {
  color: var(--vp-c-text-1);
}

.source-link {
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--vp-c-text-3);
  padding: 6px;
  border-radius: 6px;
  transition: color 0.2s, background-color 0.2s;
  flex-shrink: 0;
}

.source-link:hover {
  color: var(--vp-c-brand-1);
  background-color: var(--vp-c-bg-soft);
}
</style>
