<script setup lang="ts">
definePageMeta({
  layout: 'default'
})

const client = useSupabaseClient()
const email = ref('')
const password = ref('')
const loading = ref(false)
const errorMsg = ref('')

const handleLogin = async () => {
  loading.value = true
  errorMsg.value = ''

  try {
    const { data, error } = await client.auth.signInWithPassword({
      email: email.value,
      password: password.value
    })

    if (error) throw error

    // Fetch profile to determine redirect
    const { data: profile } = await client
      .from('profiles')
      .select('onboarding_completed, role')
      .eq('id', data.user.id)
      .single()

    if (profile && !profile.onboarding_completed) {
      navigateTo('/onboarding')
    } else if (profile?.role === 'cashier') {
      navigateTo('/cashier')
    } else {
      navigateTo('/backoffice')
    }
  } catch (err: any) {
    errorMsg.value = err.message || 'Invalid email or password.'
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="max-w-[400px] w-full p-8 bg-white dark:bg-gray-900 rounded-[2rem] shadow-xl flex flex-col gap-6 border border-gray-100 dark:border-gray-800 transition-all duration-300">
    <div class="text-center">
      <div class="w-16 h-16 bg-primary/10 dark:bg-primary/20 text-primary rounded-2xl flex items-center justify-center mx-auto mb-4">
        <UIcon name="i-lucide-box" class="w-8 h-8" />
      </div>
      <h1 class="text-3xl font-bold text-gray-900 dark:text-white mb-2">Komo POS</h1>
      <p class="text-gray-500 dark:text-gray-400 text-sm">Sign in to your account</p>
    </div>

    <UAlert v-if="errorMsg" color="error" variant="soft" :title="errorMsg" icon="i-lucide-alert-circle" class="rounded-xl" />

    <form @submit.prevent="handleLogin" class="flex flex-col gap-4 mt-2">
      <UFormGroup label="Email Address" name="email">
        <UInput v-model="email" type="email" placeholder="admin@komopos.com" icon="i-lucide-mail" size="lg" required />
      </UFormGroup>

      <UFormGroup label="Password" name="password">
        <UInput v-model="password" type="password" placeholder="••••••••" icon="i-lucide-lock" size="lg" required />
      </UFormGroup>

      <UButton type="submit" color="primary" block size="lg" class="mt-4 rounded-xl font-bold text-lg h-12" :loading="loading">
        Sign In
      </UButton>
    </form>

    <div class="text-center text-sm text-gray-500 dark:text-gray-400 mt-2">
      Don't have an account?
      <NuxtLink to="/register" class="text-primary font-semibold hover:underline">Register here</NuxtLink>
    </div>
  </div>
</template>
