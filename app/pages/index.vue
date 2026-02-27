<script setup lang="ts">
import { onMounted } from 'vue'

const isAuthenticated = ref(false)

onMounted(() => {
  isAuthenticated.value = localStorage.getItem('isAuthenticated') === 'true'
})
</script>

<template>
  <div class="min-h-screen bg-gray-50 flex flex-col items-center justify-center p-4">
    <div class="absolute top-6 right-6">
      <ThemeToggle />
    </div>

    <div class="text-center mb-10">
      <div class="w-20 h-20 bg-primary/10 text-primary rounded-3xl flex items-center justify-center mx-auto mb-6">
        <UIcon name="i-lucide-box" class="w-10 h-10" />
      </div>
      <h1 class="text-4xl font-extrabold text-gray-900 mb-4 tracking-tight">Komo POS Portal</h1>
      <p class="text-lg text-gray-500 max-w-md mx-auto">Select a module to continue to your workspace.</p>
    </div>

    <!-- Portal Options -->
    <div class="grid md:grid-cols-2 gap-6 max-w-3xl w-full">
      
      <!-- Cashier Card -->
      <NuxtLink to="/cashier" class="group relative bg-white rounded-3xl p-8 shadow-sm hover:shadow-xl hover:-translate-y-1 overflow-hidden transition-all duration-300 border border-gray-100 flex flex-col items-center text-center">
        <div class="absolute inset-x-0 bottom-0 h-1 bg-gradient-to-r from-primary to-green-400 transform scale-x-0 group-hover:scale-x-100 transition-transform origin-left"></div>
        <div class="w-16 h-16 bg-gray-50 text-gray-700 rounded-2xl flex items-center justify-center mb-6 group-hover:bg-primary/10 group-hover:text-primary transition-colors">
          <UIcon name="i-lucide-monitor" class="w-8 h-8" />
        </div>
        <h2 class="text-2xl font-bold text-gray-900 mb-2">Cashier POS</h2>
        <p class="text-gray-500 text-sm">Lightning fast order processing, touch-friendly interface, and offline mode.</p>
      </NuxtLink>

      <!-- Backoffice Card -->
      <NuxtLink to="/backoffice" class="group relative bg-white rounded-3xl p-8 shadow-sm hover:shadow-xl hover:-translate-y-1 overflow-hidden transition-all duration-300 border border-gray-100 flex flex-col items-center text-center">
        <div class="absolute inset-x-0 bottom-0 h-1 bg-gradient-to-r from-gray-800 to-gray-600 transform scale-x-0 group-hover:scale-x-100 transition-transform origin-left"></div>
        <div class="w-16 h-16 bg-gray-50 text-gray-700 rounded-2xl flex items-center justify-center mb-6 group-hover:bg-gray-900 group-hover:text-white transition-colors">
          <UIcon name="i-lucide-layout-dashboard" class="w-8 h-8" />
        </div>
        <h2 class="text-2xl font-bold text-gray-900 mb-2">Backoffice</h2>
        <p class="text-gray-500 text-sm">Manage products, inventory, employees, and view sales analytics in real-time.</p>
      </NuxtLink>

    </div>

    <!-- Contextual Login/Logout -->
    <div class="mt-16 text-center">
      <div v-if="!isAuthenticated" class="space-y-4">
        <p class="text-sm text-gray-500">Don't have an account or need to sign in?</p>
        <div class="flex items-center justify-center gap-4">
          <UButton to="/login" color="neutral" variant="solid" class="rounded-xl px-6 py-2 font-semibold">Sign In</UButton>
          <UButton to="/register" color="primary" variant="soft" class="rounded-xl px-6 py-2 font-semibold">Register Store</UButton>
        </div>
      </div>
    </div>
  </div>
</template>
