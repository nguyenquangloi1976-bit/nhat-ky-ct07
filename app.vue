<template>
  <NuxtLayout>
    <NuxtPage />
  </NuxtLayout>
</template>

<script setup lang="ts">
const { init } = useAuth()
const { loadProjects } = useProject()
onMounted(async () => {
  await init()
  await loadProjects()
})
</script>
