<template>
  <Teleport to="body">
    <Transition name="toast">
      <div v-if="toast.show" class="fixed top-4 right-4 z-50 max-w-sm">
        <div :class="[
          'rounded-lg shadow-lg p-4 flex items-start space-x-3',
          toast.type === 'success' ? 'bg-green-50 text-green-800 border border-green-200' :
          toast.type === 'error' ? 'bg-red-50 text-red-800 border border-red-200' :
          'bg-blue-50 text-blue-800 border border-blue-200'
        ]">
          <span class="text-lg">
            {{ toast.type === 'success' ? '✓' : toast.type === 'error' ? '✕' : 'ℹ' }}
          </span>
          <p class="text-sm flex-1">{{ toast.message }}</p>
          <button @click="toast.show = false" class="text-gray-400 hover:text-gray-600">&times;</button>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup lang="ts">
const toast = useToast()
</script>

<style scoped>
.toast-enter-active { animation: slideIn 0.3s ease; }
.toast-leave-active { animation: slideIn 0.3s ease reverse; }
@keyframes slideIn {
  from { transform: translateX(100%); opacity: 0; }
  to { transform: translateX(0); opacity: 1; }
}
</style>
