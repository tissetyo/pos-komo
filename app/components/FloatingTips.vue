<script setup lang="ts">
const props = defineProps<{
  tips: string[]
}>()

const isOpen = ref(false)
</script>

<template>
  <div class="fixed bottom-6 right-6 z-50">
    <!-- Floating button -->
    <button
      class="w-12 h-12 rounded-full bg-[#162456] text-white shadow-lg hover:shadow-xl flex items-center justify-center transition-all hover:scale-105"
      :class="{ 'ring-2 ring-[#162456]/30 ring-offset-2': isOpen }"
      @click="isOpen = !isOpen"
      title="Tips & Help"
    >
      <UIcon :name="isOpen ? 'i-lucide-x' : 'i-lucide-lightbulb'" class="w-5 h-5" />
    </button>

    <!-- Tips panel -->
    <Transition
      enter-active-class="transition duration-200 ease-out"
      enter-from-class="opacity-0 translate-y-2 scale-95"
      enter-to-class="opacity-100 translate-y-0 scale-100"
      leave-active-class="transition duration-150 ease-in"
      leave-from-class="opacity-100 translate-y-0 scale-100"
      leave-to-class="opacity-0 translate-y-2 scale-95"
    >
      <div
        v-show="isOpen"
        class="absolute bottom-16 right-0 w-80 bg-white rounded-2xl shadow-2xl border border-gray-200 overflow-hidden"
      >
        <div class="px-4 py-3 bg-[#162456] text-white">
          <div class="flex items-center gap-2">
            <UIcon name="i-lucide-lightbulb" class="w-4 h-4 text-amber-300" />
            <span class="font-semibold text-sm">Tips & Help</span>
          </div>
        </div>
        <div class="p-4 space-y-3 max-h-64 overflow-y-auto">
          <div v-for="(tip, i) in props.tips" :key="i" class="flex gap-2.5 text-sm text-gray-600">
            <span class="text-amber-500 mt-0.5 flex-shrink-0">💡</span>
            <span>{{ tip }}</span>
          </div>
          <p v-if="!props.tips?.length" class="text-sm text-gray-400 text-center py-2">No tips for this page</p>
        </div>
      </div>
    </Transition>
  </div>
</template>
