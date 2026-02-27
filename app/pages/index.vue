<script setup lang="ts">
import { onMounted } from 'vue'

onMounted(() => {
  const isAuth = localStorage.getItem('isAuthenticated')
  if (isAuth) {
    navigateTo('/cashier')
  } else {
    navigateTo('/login')
  }
})
</script>
<template>
  <div class="flex items-center justify-center h-screen w-screen bg-gray-50 text-gray-500">
    <UIcon name="i-lucide-loader-2" class="w-8 h-8 animate-spin text-primary" />
  </div>
</template>
