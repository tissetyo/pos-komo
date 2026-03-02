<script setup lang="ts">
definePageMeta({ layout: 'default' })

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
    const { data: profile } = await (client as any)
      .from('profiles')
      .select('onboarding_completed, role')
      .eq('id', data.user.id)
      .single()
    if (profile && !profile.onboarding_completed) {
      navigateTo('/onboarding')
    } else if (profile?.role === 'cashier') {
      // Set onboarding cookie since they're past it
      const onboardingDone = useCookie('onboarding_done')
      onboardingDone.value = 'true'
      navigateTo('/cashier')
    } else if (profile?.role === 'kitchen') {
      const onboardingDone = useCookie('onboarding_done')
      onboardingDone.value = 'true'
      navigateTo('/kitchen')
    } else {
      // Set onboarding cookie since they're past it
      const onboardingDone = useCookie('onboarding_done')
      onboardingDone.value = 'true'
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
  <div class="w-full max-w-[480px] mx-4">
    <div class="bg-white dark:bg-gray-900 rounded-3xl shadow-xl border border-gray-100 dark:border-gray-800 p-10">

      <div class="text-center mb-8">
        <div class="w-14 h-14 bg-primary/10 dark:bg-primary/20 text-primary rounded-2xl flex items-center justify-center mx-auto mb-4">
          <UIcon name="i-lucide-box" class="w-7 h-7" />
        </div>
        <h1 class="text-2xl font-bold text-gray-900 dark:text-white">Komo POS</h1>
        <p class="text-gray-500 dark:text-gray-400 text-sm mt-1">Sign in to your account</p>
      </div>

      <UAlert v-if="errorMsg" color="error" variant="soft" :title="errorMsg" icon="i-lucide-alert-circle" class="rounded-xl mb-6" />

      <form @submit.prevent="handleLogin" class="space-y-5">
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1.5">Email Address</label>
          <UInput v-model="email" type="email" placeholder="admin@komopos.com" icon="i-lucide-mail" class="w-full" size="xl" required />
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1.5">Password</label>
          <UInput v-model="password" type="password" placeholder="••••••••" icon="i-lucide-lock" class="w-full" size="xl" required />
        </div>

        <UButton type="submit" color="primary" block size="xl" class="rounded-xl font-bold mt-2" :loading="loading">
          Sign In
        </UButton>
      </form>

      <p class="text-center text-sm text-gray-500 dark:text-gray-400 mt-6">
        Don't have an account?
        <NuxtLink to="/register" class="text-primary font-semibold hover:underline">Register here</NuxtLink>
      </p>

    </div>
  </div>
</template>
