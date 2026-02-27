<script setup lang="ts">
const handleLogout = () => {
  localStorage.removeItem('isAuthenticated')
  navigateTo('/login')
}
</script>

<template>
  <div class="h-screen w-screen bg-gray-50 dark:bg-gray-950 flex font-sans overflow-hidden">
    <!-- Sidebar -->
    <aside class="w-64 bg-white dark:bg-gray-900 border-r border-gray-200 dark:border-gray-800 flex flex-col shadow-sm z-10 flex-shrink-0">
      <div class="h-16 flex items-center px-6 border-b border-gray-100 dark:border-gray-800">
        <div class="flex items-center gap-3 font-semibold text-lg text-gray-900 cursor-pointer" @click="navigateTo('/cashier')">
          <UIcon name="i-lucide-box" class="w-6 h-6 text-primary" />
          Komo POS
        </div>
      </div>
      
      <div class="flex-1 overflow-y-auto py-4 px-3 space-y-1">
        <div class="text-xs font-medium text-gray-400 px-3 uppercase tracking-wider mb-2 mt-2">Overview</div>
        <UButton to="/backoffice" label="Dashboard" icon="i-lucide-layout-dashboard" color="neutral" variant="ghost" class="w-full justify-start rounded-lg" />
        <UButton to="/backoffice/sales-report" label="Analytics" icon="i-lucide-line-chart" color="neutral" variant="ghost" class="w-full justify-start rounded-lg text-gray-500" />
        <UButton to="/backoffice/transactions" label="Transactions" icon="i-lucide-receipt" color="neutral" variant="ghost" class="w-full justify-start rounded-lg text-gray-500" />
        
        <div class="text-xs font-medium text-gray-400 px-3 uppercase tracking-wider mb-2 mt-6">Management</div>
        <UButton to="/backoffice/products" label="Products" icon="i-lucide-package" color="neutral" variant="ghost" class="w-full justify-start rounded-lg text-gray-500" />
        <UButton to="/backoffice/customers" label="Customers" icon="i-lucide-users" color="neutral" variant="ghost" class="w-full justify-start rounded-lg text-gray-500" />
        <UButton to="/backoffice/employees" label="Employees" icon="i-lucide-user-cog" color="neutral" variant="ghost" class="w-full justify-start rounded-lg text-gray-500" />
        
        <div class="text-xs font-medium text-gray-400 px-3 uppercase tracking-wider mb-2 mt-6">System</div>
        <UButton to="/cashier" label="Back to POS" icon="i-lucide-monitor" color="primary" variant="soft" class="w-full justify-start rounded-lg font-semibold" />
        <UButton to="/backoffice/settings" label="Settings" icon="i-lucide-settings" color="neutral" variant="ghost" class="w-full justify-start rounded-lg text-gray-500" />
      </div>

      <div class="p-4 border-t border-gray-100 dark:border-gray-800">
        <div class="flex items-center gap-3">
          <UAvatar src="https://avatars.githubusercontent.com/u/739984?v=4" alt="Owner" size="sm" />
          <div class="flex-1 min-w-0">
            <p class="text-sm font-medium text-gray-900 truncate">Owner Account</p>
            <p class="text-xs text-gray-500 truncate">Admin</p>
          </div>
          <UButton icon="i-lucide-log-out" color="neutral" variant="ghost" size="xs" @click="handleLogout" />
        </div>
      </div>
    </aside>

    <!-- Main Content Area -->
    <main class="flex-1 overflow-auto flex flex-col min-w-0">
      <header class="h-16 bg-white/80 dark:bg-gray-900/80 backdrop-blur-md border-b border-gray-200 dark:border-gray-800 flex items-center justify-between px-6 sticky top-0 z-10">
        <h1 class="text-lg font-semibold text-gray-800">Backoffice</h1>
        <div class="flex items-center gap-4">
          <ThemeToggle />
          <UButton icon="i-lucide-bell" color="neutral" variant="ghost" />
          <USelectMenu 
            :options="['Central Park', 'Mall Kelapa Gading', 'Senayan City']" 
            placeholder="All Outlets"
            class="w-48"
          />
        </div>
      </header>
      <div class="p-6 flex-1 max-w-7xl mx-auto w-full">
        <slot />
      </div>
    </main>
  </div>
</template>
