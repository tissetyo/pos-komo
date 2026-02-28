<script setup lang="ts">
const client = useSupabaseClient()
const user = useSupabaseUser()
const profile = ref<any>(null)
const outlets = ref<any[]>([])
const selectedOutlet = ref('')
const reportsOpen = ref(false)

onMounted(async () => {
  if (user.value) {
    const { data } = await client
      .from('profiles')
      .select('*, outlets(*)')
      .eq('id', user.value.id)
      .single()
    profile.value = data

    const { data: outletList } = await client
      .from('outlets')
      .select('id, name')
      .order('created_at')
    outlets.value = outletList || []
    if (outlets.value.length > 0) {
      selectedOutlet.value = outlets.value[0].name
    }
  }
})

const handleLogout = async () => {
  await client.auth.signOut()
  navigateTo('/login')
}

const route = useRoute()

const breadcrumb = computed(() => {
  const path = route.path.replace('/backoffice', '').replace(/^\//, '')
  if (!path) return 'Dashboard'
  return path.split('/').map(s => s.charAt(0).toUpperCase() + s.slice(1).replace(/-/g, ' ')).join(' / ')
})

const navItems = [
  { label: 'Dashboard', icon: 'i-lucide-layout-dashboard', to: '/backoffice' },
  { label: 'Transactions', icon: 'i-lucide-receipt', to: '/backoffice/transactions' },
  { label: 'Customers', icon: 'i-lucide-users', to: '/backoffice/customers' },
  { label: 'Products', icon: 'i-lucide-package', to: '/backoffice/products' },
  { label: 'Employeess', icon: 'i-lucide-user-cog', to: '/backoffice/employees' },
  { label: 'Settings', icon: 'i-lucide-settings', to: '/backoffice/settings' },
]

const reportItems = [
  { label: 'Sales Report', to: '/backoffice/sales-report' },
  { label: 'Employee Report', to: '/backoffice/employees' },
]
</script>

<template>
  <div class="h-screen w-screen bg-gray-50 flex font-sans overflow-hidden">
    <!-- Sidebar — always dark navy -->
    <aside class="w-56 bg-[#1E293B] flex flex-col flex-shrink-0 z-10">
      <!-- Branding -->
      <div class="h-16 flex items-center px-5 border-b border-white/10">
        <div class="flex items-center gap-2 cursor-pointer" @click="navigateTo('/')">
          <UIcon name="i-lucide-box" class="w-6 h-6 text-white" />
          <span class="font-bold text-white text-lg">May POS</span>
          <span class="text-gray-400 text-sm font-normal ml-0.5">Backoffice</span>
        </div>
      </div>

      <!-- Navigation -->
      <nav class="flex-1 overflow-y-auto py-4 px-3 space-y-1">
        <NuxtLink
          v-for="item in navItems"
          :key="item.to"
          :to="item.to"
          class="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-colors"
          :class="[
            route.path === item.to
              ? 'bg-white/10 text-white'
              : 'text-gray-400 hover:bg-white/5 hover:text-white'
          ]"
        >
          <UIcon :name="item.icon" class="w-5 h-5 flex-shrink-0" />
          {{ item.label }}
        </NuxtLink>

        <!-- Reports with sub-menu -->
        <div>
          <button
            class="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-colors w-full text-left"
            :class="[
              route.path.includes('sales-report') ? 'bg-white/10 text-white' : 'text-gray-400 hover:bg-white/5 hover:text-white'
            ]"
            @click="reportsOpen = !reportsOpen"
          >
            <UIcon name="i-lucide-bar-chart-3" class="w-5 h-5 flex-shrink-0" />
            Reports
            <UIcon
              name="i-lucide-chevron-down"
              class="w-4 h-4 ml-auto transition-transform"
              :class="{ 'rotate-180': reportsOpen }"
            />
          </button>
          <div v-show="reportsOpen" class="ml-8 mt-1 space-y-1">
            <NuxtLink
              v-for="sub in reportItems"
              :key="sub.to"
              :to="sub.to"
              class="block px-3 py-2 rounded-lg text-sm transition-colors"
              :class="[
                route.path === sub.to ? 'text-white bg-white/10' : 'text-gray-500 hover:text-gray-300'
              ]"
            >
              {{ sub.label }}
            </NuxtLink>
          </div>
        </div>
      </nav>

      <!-- User / Logout at bottom -->
      <div class="p-4 border-t border-white/10">
        <NuxtLink to="/cashier" class="flex items-center gap-2 px-3 py-2 rounded-lg text-sm font-medium text-emerald-400 hover:bg-white/5 transition-colors mb-2">
          <UIcon name="i-lucide-monitor" class="w-5 h-5" />
          Back to POS
        </NuxtLink>
      </div>
    </aside>

    <!-- Main Content Area -->
    <main class="flex-1 overflow-auto flex flex-col min-w-0">
      <!-- Top Header Bar -->
      <header class="h-16 bg-white border-b border-gray-200 flex items-center justify-between px-6 sticky top-0 z-10 flex-shrink-0">
        <div class="flex items-center gap-2 text-sm text-gray-500">
          <NuxtLink to="/backoffice" class="hover:text-gray-700 transition-colors">Home</NuxtLink>
          <span v-if="breadcrumb !== 'Dashboard'">/</span>
          <span v-if="breadcrumb !== 'Dashboard'" class="text-gray-900 font-medium">{{ breadcrumb }}</span>
        </div>
        <div class="flex items-center gap-4">
          <UButton icon="i-lucide-bell" color="neutral" variant="ghost" />
          <div class="flex items-center gap-2 cursor-pointer" @click="handleLogout" title="Click to Logout">
            <UIcon name="i-lucide-user" class="w-4 h-4 text-gray-400" />
            <span class="text-sm font-medium text-gray-700">{{ profile?.full_name || user?.email || 'Hiro Saleh' }}</span>
            <UIcon name="i-lucide-chevron-down" class="w-4 h-4 text-gray-400" />
          </div>
        </div>
      </header>

      <!-- Page Content -->
      <div class="p-6 flex-1 max-w-[1400px] w-full mx-auto">
        <slot />
      </div>

      <!-- Footer -->
      <footer class="py-4 text-center text-xs text-gray-400 border-t border-gray-100">
        © 2026 May POS Systems. All rights reserved.
      </footer>
    </main>
  </div>
</template>
