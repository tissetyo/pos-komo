<script setup lang="ts">
const { client, profile, outlet, user } = useUserProfile()
const reportsOpen = ref(false)
const userMenuOpen = ref(false)
const { loadCurrency } = useCurrency()

watch(outlet, (val) => {
  if (val?.id) loadCurrency(val.id)
}, { immediate: true })

const handleLogout = async () => {
  // Clear onboarding cache
  const onboardingDone = useCookie('onboarding_done')
  onboardingDone.value = null
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
  { label: 'Products', icon: 'i-lucide-package', to: '/backoffice/products' },
  { label: 'Customers', icon: 'i-lucide-users', to: '/backoffice/customers' },
  { label: 'Employees', icon: 'i-lucide-user-cog', to: '/backoffice/employees' },
  { label: 'Settings', icon: 'i-lucide-settings', to: '/backoffice/settings' },
]

const reportItems = [
  { label: 'Sales Report', to: '/backoffice/sales-report' },
  { label: 'Employee Report', to: '/backoffice/employees' },
]
</script>

<template>
  <div class="h-screen w-screen bg-gray-50 flex font-sans overflow-hidden">
    <!-- Sidebar -->
    <aside class="w-56 bg-[#162456] flex flex-col flex-shrink-0 z-10">
      <!-- Branding -->
      <div class="h-16 flex items-center px-5 border-b border-white/10">
        <div class="flex items-center gap-2 cursor-pointer" @click="navigateTo('/')">
          <UIcon name="i-lucide-box" class="w-6 h-6 text-white" />
          <div class="flex flex-col leading-tight min-w-0">
            <span class="font-bold text-white text-sm truncate">{{ outlet?.name || 'My Store' }}</span>
            <span class="text-blue-300/60 text-[10px] font-normal">Backoffice</span>
          </div>
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
            route.path === item.to || (item.to !== '/backoffice' && route.path.startsWith(item.to))
              ? 'bg-white/15 text-white'
              : 'text-blue-200/70 hover:bg-white/5 hover:text-white'
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
              route.path.includes('sales-report') ? 'bg-white/15 text-white' : 'text-blue-200/70 hover:bg-white/5 hover:text-white'
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
                route.path === sub.to ? 'text-white bg-white/10' : 'text-blue-300/50 hover:text-blue-200'
              ]"
            >
              {{ sub.label }}
            </NuxtLink>
          </div>
        </div>
      </nav>

      <!-- Bottom -->
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
          <!-- User dropdown menu -->
          <div class="relative">
            <div
              class="flex items-center gap-2 cursor-pointer hover:bg-gray-50 rounded-lg px-2 py-1.5 transition-colors"
              @click="userMenuOpen = !userMenuOpen"
            >
              <div class="w-8 h-8 rounded-full bg-[#162456] flex items-center justify-center text-white text-xs font-bold">
                {{ (profile?.full_name || user?.email || 'U').charAt(0).toUpperCase() }}
              </div>
              <span class="text-sm font-medium text-gray-700">{{ profile?.full_name || user?.email || 'User' }}</span>
              <UIcon name="i-lucide-chevron-down" class="w-4 h-4 text-gray-400" />
            </div>
            <!-- Dropdown -->
            <div
              v-show="userMenuOpen"
              class="absolute right-0 top-full mt-1 w-48 bg-white rounded-xl shadow-lg border border-gray-200 py-1 z-50"
              @mouseleave="userMenuOpen = false"
            >
              <div class="px-4 py-2 border-b border-gray-100">
                <p class="text-sm font-medium text-gray-900 truncate">{{ profile?.full_name || 'User' }}</p>
                <p class="text-xs text-gray-500 truncate">{{ user?.email }}</p>
              </div>
              <NuxtLink to="/backoffice/settings" class="flex items-center gap-2 px-4 py-2.5 text-sm text-gray-700 hover:bg-gray-50 transition-colors" @click="userMenuOpen = false">
                <UIcon name="i-lucide-settings" class="w-4 h-4 text-gray-400" />
                Settings
              </NuxtLink>
              <button class="flex items-center gap-2 px-4 py-2.5 text-sm text-red-600 hover:bg-red-50 transition-colors w-full text-left" @click="handleLogout">
                <UIcon name="i-lucide-log-out" class="w-4 h-4" />
                Logout
              </button>
            </div>
          </div>
        </div>
      </header>

      <!-- Page Content -->
      <div class="p-6 flex-1 max-w-[1400px] w-full mx-auto">
        <slot />
      </div>

      <!-- Footer -->
      <footer class="py-4 text-center text-xs text-gray-400 border-t border-gray-100">
        © 2026 {{ outlet?.name || 'POS' }} Systems. All rights reserved.
      </footer>
    </main>
  </div>
</template>
