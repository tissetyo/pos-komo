<script setup lang="ts">
import { ref } from 'vue'

const isModalOpen = ref(true)

const close = () => {
    isModalOpen.value = false;
}
</script>

<template>
    <UModal v-model="isModalOpen" prevent-close>
      <UCard :ui="{ ring: '', divide: 'divide-y divide-gray-100 dark:divide-gray-800' }">
        <template #header>
          <div class="flex items-center justify-between">
            <h3 class="text-base font-semibold leading-6 text-gray-900 dark:text-white">
              Initial Setup
            </h3>
            <UButton color="gray" variant="ghost" icon="i-heroicons-x-mark-20-solid" class="-my-1" @click="close" />
          </div>
        </template>

        <Placeholder class="h-32" />
      </UCard>
    </UModal>
</template>
