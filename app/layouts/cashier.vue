<script setup lang="ts">
const client = useSupabaseClient()
const user = useSupabaseUser()
const outlet = ref<any>(null)

onMounted(async () => {
  if (user.value) {
    const { data } = await client.from('profiles').select('*, outlets(*)').eq('id', user.value.id).single()
    outlet.value = data?.outlets || null
  }
})

const handleLogout = async () => {
  await client.auth.signOut()
  navigateTo('/login')
}
</script>

<template>
  <div class="h-screen w-screen bg-gray-100 flex flex-col overflow-hidden font-sans">
    <!-- Top Navigation Bar -->
    <header class="h-14 bg-[#1E293B] flex items-center justify-between px-4 shrink-0 z-20">
      <!-- Left: Logo + Store Name + Search -->
      <div class="flex items-center gap-4">
        <div class="flex items-center gap-2 cursor-pointer" @click="navigateTo('/cashier')">
          <UIcon name="i-lucide-box" class="w-6 h-6 text-white" />
          <div class="flex flex-col leading-tight">
            <span class="font-bold text-white text-sm">{{ outlet?.name || 'My Store' }}</span>
            <span class="text-gray-400 text-[10px]">Point of Sale</span>
          </div>
        </div>
        <div class="relative ml-4">
          <UIcon name="i-lucide-search" class="w-4 h-4 text-gray-400 absolute left-3 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            placeholder="Search menu..."
            class="bg-white/10 text-white placeholder-gray-400 rounded-lg pl-10 pr-4 py-2 text-sm w-64 focus:outline-none focus:ring-2 focus:ring-white/30 border border-white/10"
          />
        </div>
      </div>

      <!-- Right: User + Icons -->
      <div class="flex items-center gap-3">
        <div class="flex items-center gap-2 ml-2">
          <span class="text-white text-sm font-medium">{{ user?.email?.split('@')[0] || 'Cashier' }}</span>
          <UAvatar :alt="user?.email || 'Cashier'" size="sm" class="ring-2 ring-white/20" />
        </div>
        <UButton icon="i-lucide-bell" color="neutral" variant="ghost" class="text-white hover:bg-white/10" />
        <NuxtLink to="/backoffice">
          <UButton icon="i-lucide-settings" color="neutral" variant="ghost" class="text-white hover:bg-white/10" />
        </NuxtLink>
      </div>
    </header>

    <!-- Main Content Area -->
    <main class="flex-1 flex min-w-0 overflow-hidden">
      <slot />
    </main>
  </div>
</template>
