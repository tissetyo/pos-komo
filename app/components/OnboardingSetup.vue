<script setup lang="ts">
import { ref, onMounted } from 'vue'

const isModalOpen = ref(false)
const storeName = ref('')
const currency = ref('IDR - Indonesian Rupiah')

onMounted(() => {
  // Check if user has already seen onboarding
  if (!localStorage.getItem('hasSeenOnboarding')) {
    isModalOpen.value = true
  }
})

const completeSetup = () => {
    localStorage.setItem('hasSeenOnboarding', 'true')
    isModalOpen.value = false;
}
</script>

<template>
    <UModal v-model="isModalOpen" prevent-close>
      <UCard :ui="{ ring: '', divide: 'divide-y divide-gray-100 dark:divide-gray-800' }">
        <template #header>
          <div class="flex items-center justify-between">
            <h3 class="text-lg font-bold text-gray-900">
              Welcome to Komo POS !
            </h3>
          </div>
        </template>

        <div class="p-2 space-y-6">
          <p class="text-gray-600 text-sm">Let's set up your store before you start selling. You can change these settings later in the Backoffice.</p>
          
          <UFormGroup label="Store Name" required>
            <UInput v-model="storeName" placeholder="e.g. Komo Central Park" size="lg" />
          </UFormGroup>
          
          <UFormGroup label="Primary Currency">
            <USelect v-model="currency" :options="['IDR - Indonesian Rupiah', 'USD - US Dollar', 'SGD - Singapore Dollar']" size="lg" />
          </UFormGroup>
          
          <div class="pt-4 flex justify-end">
            <UButton 
              color="primary" 
              label="Complete Setup & Go to POS" 
              size="lg" 
              class="w-full justify-center font-bold" 
              @click="completeSetup" 
            />
          </div>
        </div>
      </UCard>
    </UModal>
</template>
