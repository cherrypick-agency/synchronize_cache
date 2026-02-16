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
  return frontmatter.value.library ?? libraryDirName.value
})

const category = computed(() => frontmatter.value.category ?? null)

const pageTitle = computed(() => frontmatter.value.title ?? null)

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
</script>

<template>
  <!-- Library overview page: PackageName › LibraryName -->
  <div v-if="isLibraryOverview && libraryDirName" class="api-breadcrumb">
    <a :href="withBase('/api/')" class="breadcrumb-link">{{ packageName }}</a>
    <span class="breadcrumb-separator">›</span>
    <span class="breadcrumb-current">{{ libraryDisplayName }}</span>
  </div>

  <!-- Element page: PackageName › LibraryName › Category › ElementTitle -->
  <div v-else-if="libraryDirName && category" class="api-breadcrumb">
    <a :href="withBase('/api/')" class="breadcrumb-link">{{ packageName }}</a>
    <span class="breadcrumb-separator">›</span>
    <a :href="withBase(`/api/${libraryDirName}/`)" class="breadcrumb-link">{{ libraryDisplayName }}</a>
    <span class="breadcrumb-separator">›</span>
    <span class="breadcrumb-category">{{ category }}</span>
    <template v-if="pageTitle">
      <span class="breadcrumb-separator">›</span>
      <span class="breadcrumb-current">{{ pageTitle }}</span>
    </template>
  </div>
</template>

<style scoped>
.api-breadcrumb {
  font-size: 0.85em;
  margin-bottom: 0.5em;
  color: var(--vp-c-text-3);
  line-height: 1.5;
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
</style>
