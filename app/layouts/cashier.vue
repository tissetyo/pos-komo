<script setup lang="ts">
const client = useSupabaseClient()
const user = useSupabaseUser()
const outlet = ref<any>(null)
const { loadCurrency } = useCurrency()

onMounted(async () => {
  if (user.value) {
    const { data } = await (client as any)
      .from('profiles')
      .select('*, outlets(*)')
      .eq('id', user.value.id)
      .single()
    outlet.value = data?.outlets || null
    if (outlet.value?.id) {
      await loadCurrency(outlet.value.id)
    }
  }
})

const handleLogout = async () => {
  const onboardingDone = useCookie('onboarding_done')
  onboardingDone.value = null
  await client.auth.signOut()
  navigateTo('/login')
}
</script>

<template>
  <div class="h-screen w-screen bg-gray-50 flex flex-col font-sans overflow-hidden">
    <!-- Top Navigation Bar -->
    <header class="h-14 bg-[#162456] flex items-center justify-between px-5 flex-shrink-0">
      <div class="flex items-center gap-3">
        <UIcon name="i-lucide-monitor" class="w-5 h-5 text-white" />
        <span class="font-bold text-white text-sm">{{ outlet?.name || 'POS System' }}</span>
      </div>
      <div class="flex items-center gap-3">
        <div class="relative">
          <input
            type="text"
            placeholder="Search menu..."
            class="w-64 h-8 pl-8 pr-3 rounded-lg bg-white/10 text-white text-sm placeholder-white/50 border border-white/10 focus:bg-white/20 focus:outline-none transition-colors"
          />
          <UIcon name="i-lucide-search" class="absolute left-2.5 top-1/2 -translate-y-1/2 w-4 h-4 text-white/50" />
        </div>
      </div>
      <div class="flex items-center gap-4">
        <NuxtLink to="/kitchen" class="text-white/70 hover:text-white transition-colors text-xs font-medium flex items-center gap-1">
          <UIcon name="i-lucide-chef-hat" class="w-4 h-4" />
          Kitchen
        </NuxtLink>
        <NuxtLink to="/backoffice" class="text-white/70 hover:text-white transition-colors text-xs font-medium flex items-center gap-1">
          <UIcon name="i-lucide-layout-dashboard" class="w-4 h-4" />
          Backoffice
        </NuxtLink>
        <UButton icon="i-lucide-bell" color="neutral" variant="ghost" class="text-white" />
        <button @click="handleLogout" class="flex items-center gap-2 text-white/70 hover:text-white transition-colors">
          <div class="w-7 h-7 rounded-full bg-white/20 flex items-center justify-center text-white text-xs font-bold">
            {{ (user?.email || 'U').charAt(0).toUpperCase() }}
          </div>
        </button>
      </div>
    </header>

    <!-- Main Content -->
    <main class="flex-1 overflow-hidden">
      <slot />
    </main>
  </div>
</template>
