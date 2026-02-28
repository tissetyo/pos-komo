<script setup lang="ts">
definePageMeta({
  layout: 'default'
})

const client = useSupabaseClient()
const user = useSupabaseUser()
const loading = ref(false)
const currentStep = ref(1)
const totalSteps = 4

// Step 1: Store Info
const storeInfo = ref({
  name: '',
  city: '',
  timezone: 'Asia/Jakarta',
  storeType: 'Kafe/Coffee Shop',
  currency: 'IDR'
})

// Step 2: Features
const features = ref([
  { id: 'realtime', name: 'Real-time Kitchen Status', desc: 'Live order status between cashier and kitchen.', enabled: true },
  { id: 'autoprint', name: 'Auto-Print Receipts', desc: 'Print receipt automatically after payment.', enabled: true },
  { id: 'analytics', name: 'Analytics Dashboard', desc: 'Revenue and performance metrics.', enabled: true },
  { id: 'multioutlet', name: 'Multi-Outlet Management', desc: 'Manage multiple stores from one account.', enabled: false }
])

// Step 3: First Product
const product = ref({
  name: '',
  price: '',
  category: ''
})

// Step 4: Cashier PIN
const cashierPin = ref('')

// Load existing progress
onMounted(async () => {
  if (!user.value) return

  const { data: profile } = await client
    .from('profiles')
    .select('onboarding_step, outlet_id')
    .eq('id', user.value.id)
    .single()

  if (profile?.onboarding_step) {
    currentStep.value = profile.onboarding_step
  }

  // Pre-fill store info from outlet if exists
  if (profile?.outlet_id) {
    const { data: outlet } = await client
      .from('outlets')
      .select('*')
      .eq('id', profile.outlet_id)
      .single()

    if (outlet) {
      storeInfo.value.name = outlet.name || ''
      storeInfo.value.city = outlet.city || ''
      storeInfo.value.timezone = outlet.timezone || 'Asia/Jakarta'
      storeInfo.value.storeType = outlet.store_type || 'Kafe/Coffee Shop'
      storeInfo.value.currency = outlet.currency || 'IDR'
    }
  }
})

const saveProgress = async (step: number) => {
  if (!user.value) return
  await client
    .from('profiles')
    .update({ onboarding_step: step })
    .eq('id', user.value.id)
}

const nextStep = async () => {
  loading.value = true
  try {
    if (currentStep.value === 1) {
      await saveStoreInfo()
    } else if (currentStep.value === 3) {
      await saveFirstProduct()
    }

    if (currentStep.value < totalSteps) {
      currentStep.value++
      await saveProgress(currentStep.value)
    } else {
      await completeSetup()
    }
  } finally {
    loading.value = false
  }
}

const skipStep = async () => {
  if (currentStep.value < totalSteps) {
    currentStep.value++
    await saveProgress(currentStep.value)
  } else {
    loading.value = true
    await completeSetup()
    loading.value = false
  }
}

const prevStep = () => {
  if (currentStep.value > 1) {
    currentStep.value--
  }
}

const saveStoreInfo = async () => {
  if (!user.value) return

  const { data: profile } = await client
    .from('profiles')
    .select('outlet_id')
    .eq('id', user.value.id)
    .single()

  if (profile?.outlet_id) {
    await client
      .from('outlets')
      .update({
        name: storeInfo.value.name,
        city: storeInfo.value.city,
        timezone: storeInfo.value.timezone,
        store_type: storeInfo.value.storeType,
        currency: storeInfo.value.currency
      })
      .eq('id', profile.outlet_id)
  }
}

const saveFirstProduct = async () => {
  if (!user.value || !product.value.name || !product.value.price) return

  const { data: profile } = await client
    .from('profiles')
    .select('outlet_id')
    .eq('id', user.value.id)
    .single()

  if (!profile?.outlet_id) return

  // Create category if provided
  let categoryId = null
  if (product.value.category) {
    const { data: cat } = await client
      .from('categories')
      .insert({ name: product.value.category, outlet_id: profile.outlet_id })
      .select()
      .single()
    if (cat) categoryId = cat.id
  }

  await client
    .from('products')
    .insert({
      name: product.value.name,
      price: parseInt(product.value.price),
      category_id: categoryId,
      outlet_id: profile.outlet_id,
      is_active: true
    })
}

const completeSetup = async () => {
  if (!user.value) return

  const updateData: any = {
    onboarding_completed: true,
    onboarding_step: totalSteps
  }

  if (cashierPin.value) {
    updateData.pin = cashierPin.value
  }

  await client
    .from('profiles')
    .update(updateData)
    .eq('id', user.value.id)

  navigateTo('/backoffice')
}

const stepIcons = ['i-lucide-store', 'i-lucide-layout-grid', 'i-lucide-coffee', 'i-lucide-lock']
const stepLabels = ['Store Info', 'Features', 'First Product', 'Security']
const stepColors = ['primary', 'blue', 'amber', 'green']
</script>

<template>
  <div class="w-full max-w-2xl mx-auto p-4">
    <div class="bg-white dark:bg-gray-900 rounded-[2rem] shadow-xl border border-gray-100 dark:border-gray-800 overflow-hidden transition-all duration-300">

      <!-- Header with stepper -->
      <div class="px-8 pt-8 pb-6">
        <div class="text-center mb-6">
          <h1 class="text-2xl font-bold text-gray-900 dark:text-white">Welcome to Komo POS!</h1>
          <p class="text-sm text-gray-500 dark:text-gray-400 mt-1">Let's get your store ready in just a few steps.</p>
        </div>

        <!-- Step indicator -->
        <div class="flex items-center justify-center gap-2 mb-2">
          <template v-for="step in totalSteps" :key="step">
            <div
              :class="[
                'w-10 h-10 rounded-xl flex items-center justify-center transition-all duration-300 text-sm font-semibold',
                step === currentStep
                  ? 'bg-primary text-white shadow-md shadow-primary/30 scale-110'
                  : step < currentStep
                    ? 'bg-primary/10 text-primary dark:bg-primary/20'
                    : 'bg-gray-100 dark:bg-gray-800 text-gray-400 dark:text-gray-500'
              ]"
            >
              <UIcon v-if="step < currentStep" name="i-lucide-check" class="w-5 h-5" />
              <span v-else>{{ step }}</span>
            </div>
            <div
              v-if="step < totalSteps"
              :class="[
                'w-8 h-0.5 rounded-full transition-colors',
                step < currentStep ? 'bg-primary' : 'bg-gray-200 dark:bg-gray-700'
              ]"
            />
          </template>
        </div>
        <p class="text-center text-xs text-gray-400 dark:text-gray-500">Step {{ currentStep }} of {{ totalSteps }} — {{ stepLabels[currentStep - 1] }}</p>
      </div>

      <!-- Content -->
      <div class="px-8 pb-4 min-h-[320px]">

        <!-- Step 1: Store Info -->
        <div v-if="currentStep === 1" class="space-y-5 animate-fade-in">
          <div class="flex items-center gap-3 mb-4">
            <div class="w-12 h-12 bg-primary/10 dark:bg-primary/20 rounded-xl flex items-center justify-center text-primary text-xl">
              <UIcon name="i-lucide-store" />
            </div>
            <div>
              <h3 class="font-semibold text-gray-900 dark:text-white">Configure Your Store</h3>
              <p class="text-sm text-gray-500 dark:text-gray-400">Basic info about your business.</p>
            </div>
          </div>

          <UFormGroup label="Store Name" required>
            <UInput v-model="storeInfo.name" placeholder="e.g. Komo Central Park" size="lg" />
          </UFormGroup>
          <div class="grid grid-cols-2 gap-4">
            <UFormGroup label="City">
              <UInput v-model="storeInfo.city" placeholder="e.g. Jakarta" size="lg" />
            </UFormGroup>
            <UFormGroup label="Timezone">
              <USelect v-model="storeInfo.timezone" :options="['Asia/Jakarta', 'Asia/Makassar', 'Asia/Jayapura']" size="lg" />
            </UFormGroup>
          </div>
          <div class="grid grid-cols-2 gap-4">
            <UFormGroup label="Store Type">
              <USelect v-model="storeInfo.storeType" :options="['Kafe/Coffee Shop', 'Restaurant', 'Food Court', 'Cloud Kitchen']" size="lg" />
            </UFormGroup>
            <UFormGroup label="Currency">
              <USelect v-model="storeInfo.currency" :options="['IDR', 'MYR', 'USD', 'SGD']" size="lg" />
            </UFormGroup>
          </div>
        </div>

        <!-- Step 2: Feature Selection -->
        <div v-if="currentStep === 2" class="space-y-4 animate-fade-in">
          <div class="flex items-center gap-3 mb-4">
            <div class="w-12 h-12 bg-blue-500/10 dark:bg-blue-500/20 rounded-xl flex items-center justify-center text-blue-500 text-xl">
              <UIcon name="i-lucide-layout-grid" />
            </div>
            <div>
              <h3 class="font-semibold text-gray-900 dark:text-white">Choose Your Features</h3>
              <p class="text-sm text-gray-500 dark:text-gray-400">You can change these later in Settings.</p>
            </div>
          </div>

          <div v-for="feature in features" :key="feature.id" class="flex items-center justify-between p-4 bg-gray-50 dark:bg-gray-800/50 rounded-xl border border-gray-100 dark:border-gray-700">
            <div class="pr-4">
              <h4 class="font-medium text-gray-900 dark:text-white text-sm">{{ feature.name }}</h4>
              <p class="text-xs text-gray-500 dark:text-gray-400 mt-0.5">{{ feature.desc }}</p>
            </div>
            <UToggle v-model="feature.enabled" color="primary" />
          </div>
        </div>

        <!-- Step 3: First Product -->
        <div v-if="currentStep === 3" class="space-y-5 animate-fade-in">
          <div class="flex items-center gap-3 mb-4">
            <div class="w-12 h-12 bg-amber-500/10 dark:bg-amber-500/20 rounded-xl flex items-center justify-center text-amber-500 text-xl">
              <UIcon name="i-lucide-coffee" />
            </div>
            <div>
              <h3 class="font-semibold text-gray-900 dark:text-white">Add Your First Product</h3>
              <p class="text-sm text-gray-500 dark:text-gray-400">Optional — you can always add products later.</p>
            </div>
          </div>

          <UFormGroup label="Product Name">
            <UInput v-model="product.name" placeholder="e.g. Signature Iced Latte" size="lg" />
          </UFormGroup>
          <div class="grid grid-cols-2 gap-4">
            <UFormGroup label="Category">
              <UInput v-model="product.category" placeholder="e.g. Coffee" size="lg" />
            </UFormGroup>
            <UFormGroup label="Price">
              <UInput v-model="product.price" type="number" placeholder="28000" size="lg">
                <template #leading>
                  <span class="text-gray-400 dark:text-gray-500 text-xs">{{ storeInfo.currency }}</span>
                </template>
              </UInput>
            </UFormGroup>
          </div>
        </div>

        <!-- Step 4: Cashier PIN -->
        <div v-if="currentStep === 4" class="space-y-5 animate-fade-in">
          <div class="flex items-center gap-3 mb-4">
            <div class="w-12 h-12 bg-green-500/10 dark:bg-green-500/20 rounded-xl flex items-center justify-center text-green-500 text-xl">
              <UIcon name="i-lucide-lock" />
            </div>
            <div>
              <h3 class="font-semibold text-gray-900 dark:text-white">Secure Your Cashier</h3>
              <p class="text-sm text-gray-500 dark:text-gray-400">Set a 4-digit PIN for your POS screen. Optional.</p>
            </div>
          </div>

          <UFormGroup label="Cashier PIN">
            <UInput
              v-model="cashierPin"
              type="password"
              placeholder="••••"
              size="lg"
              maxlength="4"
              class="text-center text-2xl tracking-[0.5em] font-mono"
            />
          </UFormGroup>
          <p class="text-xs text-gray-400 dark:text-gray-500">This PIN will be used to lock the POS screen and approve voids.</p>
        </div>
      </div>

      <!-- Footer -->
      <div class="px-8 py-6 border-t border-gray-100 dark:border-gray-800 flex justify-between items-center">
        <div>
          <UButton
            v-if="currentStep > 1"
            color="neutral"
            variant="ghost"
            label="Back"
            icon="i-lucide-arrow-left"
            @click="prevStep"
          />
        </div>

        <div class="flex items-center gap-3">
          <UButton
            v-if="currentStep >= 2"
            color="neutral"
            variant="ghost"
            label="Skip"
            @click="skipStep"
          />
          <UButton
            color="primary"
            :label="currentStep === totalSteps ? 'Finish Setup' : 'Continue'"
            :trailing-icon="currentStep === totalSteps ? 'i-lucide-check' : 'i-lucide-arrow-right'"
            size="lg"
            class="font-bold px-8"
            :loading="loading"
            @click="nextStep"
          />
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.animate-fade-in {
  animation: fadeIn 0.3s ease-in-out;
}
@keyframes fadeIn {
  from { opacity: 0; transform: translateY(8px); }
  to { opacity: 1; transform: translateY(0); }
}
</style>
