<script setup lang="ts">
const handleLogout = () => {
  localStorage.removeItem('isAuthenticated')
  navigateTo('/login')
}
</script>

<template>
  <div class="h-screen w-screen bg-gray-100 dark:bg-gray-950 flex overflow-hidden font-sans">
    <!-- Left Sidebar / Navigation (Icon only or minimal) -->
    <aside class="w-16 md:w-20 bg-white dark:bg-gray-900 border-r border-gray-200 dark:border-gray-800 flex flex-col items-center py-4 shrink-0 shadow-sm z-10">
      <div class="bg-primary/10 p-2 rounded-xl mb-6 text-primary cursor-pointer hover:bg-primary/20 transition-colors" title="Reload Dashboard" @click="navigateTo('/cashier')">
        <UIcon name="i-lucide-box" class="w-6 h-6 md:w-8 md:h-8" />
      </div>
      
      <nav class="flex-1 flex flex-col gap-4 w-full px-2">
        <UButton
          to="/cashier"
          icon="i-lucide-layout-grid"
          color="neutral"
          variant="ghost"
          class="w-full h-12 justify-center rounded-xl"
          title="Cashier Dashboard"
        />
        <UButton
          icon="i-lucide-list-ordered"
          color="neutral"
          variant="ghost"
          class="w-full h-12 justify-center rounded-xl text-gray-400 hover:text-gray-900"
          title="Active Orders"
        />
        <UButton
          icon="i-lucide-clock"
          color="neutral"
          variant="ghost"
          class="w-full h-12 justify-center rounded-xl text-gray-400 hover:text-gray-900"
          title="Shift History"
        />
      </nav>

      <div class="mt-auto px-2 w-full flex flex-col gap-4">
        <UButton
          icon="i-lucide-wifi"
          color="green"
          variant="ghost"
          class="w-full h-12 justify-center rounded-xl"
          title="Online"
        />
        <UButton
          to="/backoffice"
          icon="i-lucide-settings"
          color="neutral"
          variant="ghost"
          class="w-full h-12 justify-center rounded-xl hover:text-primary transition-colors"
          title="Backoffice Settings"
        />
        <ThemeToggle class="mx-auto" />
        <div class="relative group mx-auto cursor-pointer" @click="handleLogout" title="Click to Logout">
           <UAvatar src="https://avatars.githubusercontent.com/u/739984?v=4" alt="Cashier" size="sm" class="group-hover:opacity-75 transition-opacity" />
           <div class="absolute inset-0 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity bg-black/50 rounded-full">
             <UIcon name="i-lucide-log-out" class="text-white w-4 h-4" />
           </div>
        </div>
      </div>
    </aside>

    <!-- Main Content Area -->
    <main class="flex-1 flex flex-col min-w-0 bg-gray-50/50 dark:bg-gray-900/50">
      <slot />
    </main>

  </div>
</template>
