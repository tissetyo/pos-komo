<script setup lang="ts">
import { ref, onMounted } from 'vue'

const isModalOpen = ref(false)
const currentStep = ref(1)
const totalSteps = 3

// Form state
const storeName = ref('')
const currency = ref('MYR - Malaysia Ringgit')
const productName = ref('')
const productPrice = ref('')
const cashierPin = ref('')

onMounted(() => {
  if (!localStorage.getItem('hasSeenOnboarding')) {
    isModalOpen.value = true
  }
})

const nextStep = () => {
    if (currentStep.value < totalSteps) {
        currentStep.value++
    } else {
        completeSetup()
    }
}

const completeSetup = () => {
    localStorage.setItem('hasSeenOnboarding', 'true')
    isModalOpen.value = false;
}

const skipSetup = () => {
    completeSetup()
}
</script>

<template>
    <UModal v-model="isModalOpen" prevent-close :ui="{ content: 'w-full sm:max-w-xl' }">
      <UCard :ui="{ ring: '', divide: 'divide-y divide-gray-100 dark:divide-gray-800' }">
        <template #header>
          <div class="flex items-center justify-between">
            <div>
              <h3 class="text-xl font-bold text-gray-900">
                Welcome to Komo POS!
              </h3>
              <p class="text-sm text-gray-500 mt-1">Step {{ currentStep }} of {{ totalSteps }}</p>
            </div>
            <UButton color="neutral" variant="ghost" label="Skip Quick Setup" class="text-sm" @click="skipSetup" />
          </div>
          <!-- Progress Bar -->
          <div class="w-full bg-gray-100 rounded-full h-1.5 mt-4">
            <div class="bg-primary h-1.5 rounded-full transition-all duration-300" :style="{ width: `${(currentStep / totalSteps) * 100}%` }"></div>
          </div>
        </template>

        <div class="p-2 min-h-[250px] flex flex-col justify-center">
            
          <!-- Step 1: Basic Info -->
          <div v-if="currentStep === 1" class="space-y-6 animate-fade-in">
             <div class="mb-4">
                <div class="w-12 h-12 bg-primary/10 rounded-full flex items-center justify-center text-primary mb-3 text-xl">
                   <UIcon name="i-lucide-store" />
                </div>
                <h4 class="text-lg font-semibold text-gray-900">Configure Your Store</h4>
                <p class="text-gray-600 text-sm">Let's set up the basics before you start selling.</p>
             </div>
             
             <UFormGroup label="Store Name" required>
               <UInput v-model="storeName" placeholder="e.g. Komo Central Park" size="lg" />
             </UFormGroup>
             
             <UFormGroup label="Primary Currency">
               <USelect v-model="currency" :options="['MYR - Malaysia Ringgit', 'IDR - Indonesian Rupiah', 'USD - US Dollar', 'SGD - Singapore Dollar']" size="lg" />
             </UFormGroup>
          </div>

          <!-- Step 2: First Product -->
          <div v-if="currentStep === 2" class="space-y-6 animate-fade-in">
             <div class="mb-4">
                <div class="w-12 h-12 bg-blue-500/10 rounded-full flex items-center justify-center text-blue-500 mb-3 text-xl">
                   <UIcon name="i-lucide-coffee" />
                </div>
                <h4 class="text-lg font-semibold text-gray-900">Add Your First Product</h4>
                <p class="text-gray-600 text-sm">Create something to sell! You can always add more later.</p>
             </div>
             
             <UFormGroup label="Product Name">
               <UInput v-model="productName" placeholder="e.g. Signature Iced Latte" size="lg" />
             </UFormGroup>
             
             <UFormGroup label="Price">
               <UInput v-model="productPrice" type="number" placeholder="25.00" size="lg">
                 <template #leading>
                    <span class="text-gray-500 text-sm">MYR</span>
                 </template>
               </UInput>
             </UFormGroup>
          </div>

          <!-- Step 3: Security PIN -->
          <div v-if="currentStep === 3" class="space-y-6 animate-fade-in">
             <div class="mb-4">
                <div class="w-12 h-12 bg-green-500/10 rounded-full flex items-center justify-center text-green-500 mb-3 text-xl">
                   <UIcon name="i-lucide-lock" />
                </div>
                <h4 class="text-lg font-semibold text-gray-900">Secure Your Cashier</h4>
                <p class="text-gray-600 text-sm">Set a 4-digit PIN to lock the POS screen and approve voids.</p>
             </div>
             
             <UFormGroup label="Cashier PIN">
               <UInput v-model="cashierPin" type="password" placeholder="••••" size="lg" maxlength="4" class="text-center text-2xl tracking-[0.5em] font-mono" />
             </UFormGroup>
          </div>

        </div>

        <template #footer>
          <div class="flex justify-between items-center w-full">
            <UButton 
              v-if="currentStep > 1"
              color="neutral" 
              variant="ghost" 
              label="Back" 
              icon="i-lucide-arrow-left"
              @click="currentStep--" 
            />
            <div v-else></div> <!-- Spacer -->
            
            <UButton 
              color="primary" 
              :label="currentStep === totalSteps ? 'Finish & Go to POS' : 'Next Step'" 
              :trailing-icon="currentStep === totalSteps ? 'i-lucide-check' : 'i-lucide-arrow-right'"
              size="lg" 
              class="font-bold px-8" 
              @click="nextStep" 
            />
          </div>
        </template>
      </UCard>
    </UModal>
</template>

<style scoped>
.animate-fade-in {
  animation: fadeIn 0.3s ease-in-out;
}
@keyframes fadeIn {
  from { opacity: 0; transform: translateY(5px); }
  to { opacity: 1; transform: translateY(0); }
}
</style>
