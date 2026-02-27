<script setup lang="ts">
// Layout for the main POS Cashier interface
</script>

<template>
  <div class="h-screen w-screen bg-gray-100 flex overflow-hidden font-sans">
    <!-- Left Sidebar / Navigation (Icon only or minimal) -->
    <aside class="w-16 md:w-20 bg-white border-r border-gray-200 flex flex-col items-center py-4 shrink-0 shadow-sm z-10">
      <div class="bg-primary/10 p-2 rounded-xl mb-6 text-primary">
        <UIcon name="i-lucide-box" class="w-6 h-6 md:w-8 md:h-8" />
      </div>
      
      <nav class="flex-1 flex flex-col gap-4 w-full px-2">
        <UButton
          icon="i-lucide-layout-grid"
          color="gray"
          variant="ghost"
          class="w-full h-12 justify-center rounded-xl"
        />
        <UButton
          icon="i-lucide-list-ordered"
          color="gray"
          variant="ghost"
          class="w-full h-12 justify-center rounded-xl text-gray-400 hover:text-gray-900"
        />
        <UButton
          icon="i-lucide-clock"
          color="gray"
          variant="ghost"
          class="w-full h-12 justify-center rounded-xl text-gray-400 hover:text-gray-900"
        />
      </nav>

      <div class="mt-auto px-2 w-full flex flex-col gap-4">
        <UButton
          icon="i-lucide-wifi"
          color="green"
          variant="ghost"
          class="w-full h-12 justify-center rounded-xl"
        />
        <UButton
          icon="i-lucide-settings"
          color="gray"
          variant="ghost"
          class="w-full h-12 justify-center rounded-xl"
        />
        <UAvatar src="https://avatars.githubusercontent.com/u/739984?v=4" alt="Cashier" class="cursor-pointer mx-auto" size="sm" />
      </div>
    </aside>

    <!-- Main Content Area -->
    <main class="flex-1 flex flex-col min-w-0 bg-gray-50/50">
      <slot />
    </main>

  </div>
</template>
