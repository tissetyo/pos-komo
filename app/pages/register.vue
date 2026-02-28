<script setup lang="ts">
definePageMeta({
  layout: 'default'
})

const client = useSupabaseClient()
const form = ref({
  storeName: '',
  ownerName: '',
  email: '',
  password: ''
})
const loading = ref(false)
const errorMsg = ref('')

const handleRegister = async () => {
  loading.value = true
  errorMsg.value = ''

  try {
    // Sign up — pass store_name in metadata so the DB trigger creates outlet + profile
    const { data: authData, error: authError } = await client.auth.signUp({
      email: form.value.email,
      password: form.value.password,
      options: {
        data: {
          full_name: form.value.ownerName,
          role: 'admin',
          store_name: form.value.storeName
        }
      }
    })

    if (authError) throw authError
    if (!authData.user) throw new Error('Registration failed. Please try again.')

    // Small delay to let trigger complete
    await new Promise(resolve => setTimeout(resolve, 500))

    navigateTo('/onboarding')
  } catch (err: any) {
    errorMsg.value = err.message || 'An unexpected error occurred.'
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="w-full max-w-md p-8 bg-white dark:bg-gray-900 rounded-[2rem] shadow-xl flex flex-col gap-5 border border-gray-100 dark:border-gray-800 transition-all duration-300">

    <div class="text-center mt-2">
      <div class="w-14 h-14 bg-primary/10 dark:bg-primary/20 text-primary rounded-2xl flex items-center justify-center mx-auto mb-4">
        <UIcon name="i-lucide-store" class="w-7 h-7" />
      </div>
      <h1 class="text-2xl font-bold text-gray-900 dark:text-white mb-1">Create your Store</h1>
      <p class="text-gray-500 dark:text-gray-400 text-sm">Join Komo POS and start managing your business today</p>
    </div>

    <UAlert v-if="errorMsg" color="error" variant="soft" :title="errorMsg" icon="i-lucide-alert-circle" class="rounded-xl" />

    <form @submit.prevent="handleRegister" class="flex flex-col gap-4">

      <UFormGroup label="Store Name" name="storeName">
        <UInput v-model="form.storeName" type="text" placeholder="e.g. Komo Coffee Shop" icon="i-lucide-building" required />
      </UFormGroup>

      <UFormGroup label="Owner Name" name="ownerName">
        <UInput v-model="form.ownerName" type="text" placeholder="e.g. John Doe" icon="i-lucide-user" required />
      </UFormGroup>

      <UFormGroup label="Email Address" name="email">
        <UInput v-model="form.email" type="email" placeholder="owner@store.com" icon="i-lucide-mail" required />
      </UFormGroup>

      <UFormGroup label="Password" name="password">
        <UInput v-model="form.password" type="password" placeholder="Min 6 characters" icon="i-lucide-lock" required />
      </UFormGroup>

      <UButton type="submit" color="primary" block size="lg" class="mt-2 rounded-xl font-bold text-base h-12" :loading="loading">
        Create Account
      </UButton>
    </form>

    <div class="text-center text-sm text-gray-500 dark:text-gray-400">
      Already have an account?
      <NuxtLink to="/login" class="text-primary font-semibold hover:underline">Sign In here</NuxtLink>
    </div>

  </div>
</template>
