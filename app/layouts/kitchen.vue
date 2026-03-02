<script setup lang="ts">
const client = useSupabaseClient()
const user = useSupabaseUser()
const outlet = ref<any>(null)

onMounted(async () => {
  if (user.value) {
    const { data } = await (client as any)
      .from('profiles')
      .select('*, outlets(*)')
      .eq('id', user.value.id)
      .single()
    outlet.value = data?.outlets || null
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
  <div class="h-screen w-screen bg-gray-100 flex flex-col font-sans overflow-hidden">
    <!-- Top Navigation Bar -->
    <header class="h-16 bg-amber-600 flex items-center justify-between px-6 flex-shrink-0 shadow-md z-10">
      <div class="flex items-center gap-3">
        <UIcon name="i-lucide-chef-hat" class="w-6 h-6 text-white" />
        <span class="font-bold text-white text-lg tracking-wide uppercase">{{ outlet?.name || 'Kitchen Portal' }}</span>
        <span class="ml-2 bg-white/20 text-white text-[10px] font-bold px-2 py-0.5 rounded-full uppercase tracking-widest hidden sm:inline-block">KDS Station</span>
      </div>
      
      <div class="flex items-center gap-4">
        <!-- Optional Date/Time Display (could add full clock later if requested) -->
        <span class="text-white/80 text-sm font-medium font-mono hidden md:inline-block">
          {{ new Date().toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric' }) }}
        </span>
        
        <div class="w-px h-6 bg-white/20 mx-2"></div>
        
        <NuxtLink to="/cashier" class="text-white/80 hover:text-white transition-colors text-sm font-medium flex items-center gap-2 px-3 py-1.5 rounded-lg hover:bg-white/10">
          <UIcon name="i-lucide-monitor" class="w-4 h-4" />
          <span class="hidden sm:inline">POS</span>
        </NuxtLink>
        <NuxtLink to="/backoffice" class="text-white/80 hover:text-white transition-colors text-sm font-medium flex items-center gap-2 px-3 py-1.5 rounded-lg hover:bg-white/10">
          <UIcon name="i-lucide-layout-dashboard" class="w-4 h-4" />
          <span class="hidden sm:inline">Backoffice</span>
        </NuxtLink>
        
        <div class="w-px h-6 bg-white/20 mx-2"></div>

        <button @click="handleLogout" class="flex items-center gap-2 text-white/80 hover:text-white transition-colors group">
          <span class="text-sm font-medium hidden md:inline group-hover:underline">Logout</span>
          <div class="w-8 h-8 rounded-full bg-white/20 flex items-center justify-center text-white text-sm font-bold shadow-inner">
            {{ (user?.email || 'U').charAt(0).toUpperCase() }}
          </div>
        </button>
      </div>
    </header>

    <!-- Main Content Area -->
    <main class="flex-1 overflow-hidden relative">
      <!-- Dark gradient background for better contrast against white order tickets -->
      <div class="absolute inset-0 bg-gradient-to-br from-gray-100 to-gray-200 pointer-events-none"></div>
      <div class="absolute inset-0 flex">
        <slot />
      </div>
    </main>
  </div>
</template>
