<template>
  <div class="p-8 text-center text-gray-400">Đang chuyển tới trang ghi nhật ký...</div>
</template>

<script setup lang="ts">
// Trang tạo nhật ký cũ đã gộp vào /diary (một giao diện duy nhất để ghi và sửa)
definePageMeta({ middleware: 'auth' })
const route = useRoute()
await navigateTo({ path: '/diary', query: route.query }, { replace: true })
</script>
