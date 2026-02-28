<script setup lang="ts">
definePageMeta({ layout: 'default' })

const client = useSupabaseClient()
const form = ref({ storeName: '', ownerName: '', email: '', password: '' })
const loading = ref(false)
const errorMsg = ref('')

const handleRegister = async () => {
  loading.value = true
  errorMsg.value = ''
  try {
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
  <div class="w-full max-w-[480px] mx-4">
    <div class="bg-white dark:bg-gray-900 rounded-3xl shadow-xl border border-gray-100 dark:border-gray-800 p-10">

      <div class="text-center mb-8">
        <div class="w-14 h-14 bg-primary/10 dark:bg-primary/20 text-primary rounded-2xl flex items-center justify-center mx-auto mb-4">
          <UIcon name="i-lucide-store" class="w-7 h-7" />
        </div>
        <h1 class="text-2xl font-bold text-gray-900 dark:text-white">Create your Store</h1>
        <p class="text-gray-500 dark:text-gray-400 text-sm mt-1">Join Komo POS and start managing your business today</p>
      </div>

      <UAlert v-if="errorMsg" color="error" variant="soft" :title="errorMsg" icon="i-lucide-alert-circle" class="rounded-xl mb-6" />

      <form @submit.prevent="handleRegister" class="space-y-5">
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1.5">Store Name</label>
          <UInput v-model="form.storeName" type="text" placeholder="e.g. Komo Coffee Shop" icon="i-lucide-building" class="w-full" size="xl" required />
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1.5">Owner Name</label>
          <UInput v-model="form.ownerName" type="text" placeholder="e.g. John Doe" icon="i-lucide-user" class="w-full" size="xl" required />
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1.5">Email Address</label>
          <UInput v-model="form.email" type="email" placeholder="owner@store.com" icon="i-lucide-mail" class="w-full" size="xl" required />
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1.5">Password</label>
          <UInput v-model="form.password" type="password" placeholder="Min 6 characters" icon="i-lucide-lock" class="w-full" size="xl" required />
        </div>

        <UButton type="submit" color="primary" block size="xl" class="rounded-xl font-bold mt-2" :loading="loading">
          Create Account
        </UButton>
      </form>

      <p class="text-center text-sm text-gray-500 dark:text-gray-400 mt-6">
        Already have an account?
        <NuxtLink to="/login" class="text-primary font-semibold hover:underline">Sign In here</NuxtLink>
      </p>

    </div>
  </div>
</template>
