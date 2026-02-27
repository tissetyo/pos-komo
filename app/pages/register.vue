<script setup lang="ts">
definePageMeta({
  layout: 'default'
})

const form = ref({
  storeName: '',
  ownerName: '',
  email: '',
  password: ''
})

const loading = ref(false)

const handleRegister = () => {
  loading.value = true
  // Simulate network request
  setTimeout(() => {
    localStorage.setItem('isAuthenticated', 'true')
    // Clear onboarding flag so it shows up for the new user
    localStorage.removeItem('hasSeenOnboarding') 
    navigateTo('/backoffice')
    loading.value = false
  }, 800)
}
</script>

<template>
  <div class="max-w-md w-full p-8 bg-white rounded-3xl shadow-xl flex flex-col gap-6 transform transition-all my-8">
    <div class="text-center">
      <div class="w-16 h-16 bg-primary/10 text-primary rounded-2xl flex items-center justify-center mx-auto mb-4">
        <UIcon name="i-lucide-store" class="w-8 h-8" />
      </div>
      <h1 class="text-3xl font-bold text-gray-900 mb-2">Create your Store</h1>
      <p class="text-gray-500 text-sm">Join Komo POS and start managing your business today</p>
    </div>
    
    <form @submit.prevent="handleRegister" class="flex flex-col gap-4 mt-2">
      <UFormGroup label="Business Name" name="storeName">
        <UInput v-model="form.storeName" type="text" placeholder="e.g. Komo Coffee Shop" icon="i-lucide-building" size="lg" required />
      </UFormGroup>

      <UFormGroup label="Your Full Name" name="ownerName">
        <UInput v-model="form.ownerName" type="text" placeholder="e.g. John Doe" icon="i-lucide-user" size="lg" required />
      </UFormGroup>
      
      <UFormGroup label="Email address" name="email">
        <UInput v-model="form.email" type="email" placeholder="owner@store.com" icon="i-lucide-mail" size="lg" required />
      </UFormGroup>
      
      <UFormGroup label="Password" name="password">
        <UInput v-model="form.password" type="password" placeholder="••••••••" icon="i-lucide-lock" size="lg" required />
      </UFormGroup>
      
      <UButton type="submit" color="primary" block size="lg" class="mt-4 rounded-xl font-bold text-lg h-12" :loading="loading">
        Create Account
      </UButton>
    </form>
    
    <div class="text-center text-sm text-gray-500 mt-2">
      Already have an account? <NuxtLink to="/login" class="text-primary font-semibold hover:underline">Sign In here</NuxtLink>
    </div>
  </div>
</template>
