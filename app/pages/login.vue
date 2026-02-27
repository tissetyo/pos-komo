<script setup lang="ts">
definePageMeta({
  layout: 'default'
})

const email = ref('')
const pin = ref('')
const loading = ref(false)

const handleLogin = () => {
  loading.value = true
  // Simulate network request
  setTimeout(() => {
    localStorage.setItem('isAuthenticated', 'true')
    navigateTo('/cashier')
    loading.value = false
  }, 800)
}
</script>

<template>
  <div class="max-w-md w-full p-8 bg-white dark:bg-gray-900 rounded-3xl shadow-xl flex flex-col gap-6 transform transition-all border border-gray-100 dark:border-gray-800">
    <div class="text-center">
      <div class="w-16 h-16 bg-primary/10 dark:bg-primary/20 text-primary rounded-2xl flex items-center justify-center mx-auto mb-4">
        <UIcon name="i-lucide-box" class="w-8 h-8" />
      </div>
      <h1 class="text-3xl font-bold text-gray-900 dark:text-white mb-2">Komo POS</h1>
      <p class="text-gray-500 dark:text-gray-400 text-sm">Sign in with your admin or cashier PIN</p>
    </div>
    
    <form @submit.prevent="handleLogin" class="flex flex-col gap-4 mt-2">
      <UFormGroup label="Email address or Employee ID" name="email">
        <UInput v-model="email" type="text" placeholder="admin@komopos.com" icon="i-lucide-user" size="lg" required />
      </UFormGroup>
      
      <UFormGroup label="Security PIN" name="pin">
        <UInput v-model="pin" type="password" placeholder="••••" icon="i-lucide-lock" size="lg" required />
      </UFormGroup>
      
      <UButton type="submit" color="primary" block size="lg" class="mt-4 rounded-xl font-bold text-lg h-12" :loading="loading">
        Sign In
      </UButton>
    </form>
    
    <div class="text-center text-sm text-gray-500 dark:text-gray-400 mt-2">
      Need help signing in? <a href="#" class="text-primary font-semibold hover:underline">Contact Support</a>
    </div>
  </div>
</template>
