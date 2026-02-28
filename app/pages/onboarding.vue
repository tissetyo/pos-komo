<script setup lang="ts">
definePageMeta({ layout: 'default' })

const client = useSupabaseClient()
const user = useSupabaseUser()
const loading = ref(false)
const currentStep = ref(1)
const totalSteps = 4

// Step 1: Store Info
const storeInfo = ref({
  name: '',
  city: '',
  timezone: 'Asia/Kuala_Lumpur',
  storeType: 'Kafe/Coffee Shop',
  currency: 'MYR'
})

const timezoneOptions = [
  { label: 'Asia/Kuala Lumpur (MYT)', value: 'Asia/Kuala_Lumpur' },
  { label: 'Asia/Jakarta (WIB)', value: 'Asia/Jakarta' },
  { label: 'Asia/Makassar (WITA)', value: 'Asia/Makassar' },
  { label: 'Asia/Singapore (SGT)', value: 'Asia/Singapore' }
]

const storeTypeOptions = [
  { label: 'Kafe / Coffee Shop', value: 'Kafe/Coffee Shop' },
  { label: 'Restaurant', value: 'Restaurant' },
  { label: 'Food Court', value: 'Food Court' },
  { label: 'Cloud Kitchen', value: 'Cloud Kitchen' }
]

const currencyOptions = [
  { label: 'MYR — Malaysian Ringgit', value: 'MYR' },
  { label: 'IDR — Indonesian Rupiah', value: 'IDR' },
  { label: 'SGD — Singapore Dollar', value: 'SGD' },
  { label: 'USD — US Dollar', value: 'USD' }
]

// Step 2: Features
const features = ref([
  { id: 'realtime', name: 'Real-time Kitchen Status', desc: 'Live order status between cashier and kitchen display.', icon: 'i-lucide-chef-hat', enabled: true },
  { id: 'autoprint', name: 'Auto-Print Receipts', desc: 'Print receipt automatically after payment.', icon: 'i-lucide-printer', enabled: true },
  { id: 'analytics', name: 'Analytics Dashboard', desc: 'Revenue and performance metrics.', icon: 'i-lucide-bar-chart-3', enabled: true },
  { id: 'multioutlet', name: 'Multi-Outlet Management', desc: 'Manage multiple stores from one account.', icon: 'i-lucide-building-2', enabled: false }
])

const toggleFeature = (feature: any) => {
  feature.enabled = !feature.enabled
}

// Step 3: First Product
const product = ref({
  name: '',
  price: '',
  category: ''
})

// Step 4: Cashier PIN
const cashierPin = ref(['', '', '', ''])
const pinInputs = ref<HTMLInputElement[]>([])

const handlePinInput = (index: number, event: Event) => {
  const target = event.target as HTMLInputElement
  const value = target.value
  if (value && index < 3) {
    pinInputs.value[index + 1]?.focus()
  }
}

const handlePinKeydown = (index: number, event: KeyboardEvent) => {
  if (event.key === 'Backspace' && !cashierPin.value[index] && index > 0) {
    pinInputs.value[index - 1]?.focus()
  }
}

const pinString = computed(() => cashierPin.value.join(''))

// Load existing progress on mount
onMounted(async () => {
  if (!user.value) return
  const { data: profile } = await client
    .from('profiles')
    .select('onboarding_step, outlet_id')
    .eq('id', user.value.id)
    .single()

  if (profile?.onboarding_step && profile.onboarding_step > 1) {
    currentStep.value = profile.onboarding_step
  }

  if (profile?.outlet_id) {
    const { data: outlet } = await client.from('outlets').select('*').eq('id', profile.outlet_id).single()
    if (outlet) {
      storeInfo.value.name = outlet.name || ''
      storeInfo.value.city = outlet.city || ''
      storeInfo.value.timezone = outlet.timezone || 'Asia/Kuala_Lumpur'
      storeInfo.value.storeType = outlet.store_type || 'Kafe/Coffee Shop'
      storeInfo.value.currency = outlet.currency || 'MYR'
    }
  }
})

const saveProgress = async (step: number) => {
  if (!user.value) return
  await client.from('profiles').update({ onboarding_step: step }).eq('id', user.value.id)
}

const nextStep = async () => {
  loading.value = true
  try {
    if (currentStep.value === 1) await saveStoreInfo()
    if (currentStep.value === 3) await saveFirstProduct()
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
  if (currentStep.value > 1) currentStep.value--
}

const saveStoreInfo = async () => {
  if (!user.value) return
  const { data: profile } = await client.from('profiles').select('outlet_id').eq('id', user.value.id).single()
  if (profile?.outlet_id) {
    await client.from('outlets').update({
      name: storeInfo.value.name,
      city: storeInfo.value.city,
      timezone: storeInfo.value.timezone,
      store_type: storeInfo.value.storeType,
      currency: storeInfo.value.currency
    }).eq('id', profile.outlet_id)
  }
}

const saveFirstProduct = async () => {
  if (!user.value || !product.value.name || !product.value.price) return
  const { data: profile } = await client.from('profiles').select('outlet_id').eq('id', user.value.id).single()
  if (!profile?.outlet_id) return
  let categoryId = null
  if (product.value.category) {
    const { data: cat } = await client.from('categories').insert({ name: product.value.category, outlet_id: profile.outlet_id }).select().single()
    if (cat) categoryId = cat.id
  }
  await client.from('products').insert({
    name: product.value.name,
    price: parseInt(product.value.price),
    category_id: categoryId,
    outlet_id: profile.outlet_id,
    is_active: true
  })
}

const completeSetup = async () => {
  if (!user.value) return
  const updateData: any = { onboarding_completed: true, onboarding_step: totalSteps }
  if (pinString.value.length === 4) updateData.pin = pinString.value
  await client.from('profiles').update(updateData).eq('id', user.value.id)
  navigateTo('/backoffice')
}
</script>

<template>
  <div class="w-full max-w-[560px] mx-4">
    <div class="bg-white dark:bg-gray-900 rounded-3xl shadow-xl border border-gray-100 dark:border-gray-800 overflow-hidden">

      <!-- Header -->
      <div class="px-10 pt-10 pb-6">
        <h1 class="text-2xl font-bold text-gray-900 dark:text-white text-center">Welcome to Komo POS!</h1>
        <p class="text-sm text-gray-500 dark:text-gray-400 text-center mt-1">Let's get your store ready in just a few steps.</p>

        <!-- Stepper -->
        <div class="flex items-center justify-center gap-2 mt-6">
          <template v-for="step in totalSteps" :key="step">
            <div :class="['w-10 h-10 rounded-xl flex items-center justify-center text-sm font-bold transition-all',
              step === currentStep ? 'bg-primary text-white shadow-md shadow-primary/30 scale-110'
              : step < currentStep ? 'bg-primary/10 text-primary dark:bg-primary/20'
              : 'bg-gray-100 dark:bg-gray-800 text-gray-400']">
              <UIcon v-if="step < currentStep" name="i-lucide-check" class="w-5 h-5" />
              <span v-else>{{ step }}</span>
            </div>
            <div v-if="step < totalSteps" :class="['w-8 h-0.5 rounded-full', step < currentStep ? 'bg-primary' : 'bg-gray-200 dark:bg-gray-700']" />
          </template>
        </div>
        <p class="text-center text-xs text-gray-400 dark:text-gray-500 mt-2">Step {{ currentStep }} of {{ totalSteps }}</p>
      </div>

      <!-- Content Area -->
      <div class="px-10 pb-4 min-h-[340px]">

        <!-- STEP 1: Store Info -->
        <div v-if="currentStep === 1" class="space-y-5">
          <div class="flex items-center gap-3 mb-2">
            <div class="w-10 h-10 bg-primary/10 dark:bg-primary/20 rounded-xl flex items-center justify-center text-primary"><UIcon name="i-lucide-store" class="w-5 h-5" /></div>
            <div>
              <h3 class="font-semibold text-gray-900 dark:text-white">Configure Your Store</h3>
              <p class="text-xs text-gray-500 dark:text-gray-400">Basic info about your business.</p>
            </div>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1.5">Store Name</label>
            <UInput v-model="storeInfo.name" placeholder="e.g. Komo Central Park" size="xl" class="w-full" />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1.5">City</label>
            <UInput v-model="storeInfo.city" placeholder="e.g. Kuala Lumpur" size="xl" class="w-full" />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1.5">Timezone</label>
            <select v-model="storeInfo.timezone" class="w-full h-12 px-4 rounded-xl border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 text-gray-900 dark:text-white text-sm focus:ring-2 focus:ring-primary focus:border-primary outline-none">
              <option v-for="opt in timezoneOptions" :key="opt.value" :value="opt.value">{{ opt.label }}</option>
            </select>
          </div>
          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1.5">Store Type</label>
              <select v-model="storeInfo.storeType" class="w-full h-12 px-4 rounded-xl border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 text-gray-900 dark:text-white text-sm focus:ring-2 focus:ring-primary focus:border-primary outline-none">
                <option v-for="opt in storeTypeOptions" :key="opt.value" :value="opt.value">{{ opt.label }}</option>
              </select>
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1.5">Currency</label>
              <select v-model="storeInfo.currency" class="w-full h-12 px-4 rounded-xl border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 text-gray-900 dark:text-white text-sm focus:ring-2 focus:ring-primary focus:border-primary outline-none">
                <option v-for="opt in currencyOptions" :key="opt.value" :value="opt.value">{{ opt.label }}</option>
              </select>
            </div>
          </div>
        </div>

        <!-- STEP 2: Feature Selection -->
        <div v-if="currentStep === 2" class="space-y-4">
          <div class="flex items-center gap-3 mb-2">
            <div class="w-10 h-10 bg-blue-500/10 dark:bg-blue-500/20 rounded-xl flex items-center justify-center text-blue-500"><UIcon name="i-lucide-layout-grid" class="w-5 h-5" /></div>
            <div>
              <h3 class="font-semibold text-gray-900 dark:text-white">Choose Your Features</h3>
              <p class="text-xs text-gray-500 dark:text-gray-400">You can change these later in Settings.</p>
            </div>
          </div>

          <div
            v-for="feature in features"
            :key="feature.id"
            :class="['flex items-center gap-4 p-4 rounded-xl border-2 cursor-pointer transition-all',
              feature.enabled
                ? 'border-primary bg-primary/5 dark:bg-primary/10'
                : 'border-gray-200 dark:border-gray-700 hover:border-gray-300 dark:hover:border-gray-600'
            ]"
            @click="toggleFeature(feature)"
          >
            <div :class="['w-10 h-10 rounded-lg flex items-center justify-center flex-shrink-0',
              feature.enabled ? 'bg-primary/10 text-primary' : 'bg-gray-100 dark:bg-gray-800 text-gray-400']">
              <UIcon :name="feature.icon" class="w-5 h-5" />
            </div>
            <div class="flex-1 min-w-0">
              <h4 class="font-medium text-gray-900 dark:text-white text-sm">{{ feature.name }}</h4>
              <p class="text-xs text-gray-500 dark:text-gray-400 mt-0.5">{{ feature.desc }}</p>
            </div>
            <div :class="['w-6 h-6 rounded-md border-2 flex items-center justify-center flex-shrink-0 transition-colors',
              feature.enabled ? 'bg-primary border-primary' : 'border-gray-300 dark:border-gray-600']">
              <UIcon v-if="feature.enabled" name="i-lucide-check" class="w-4 h-4 text-white" />
            </div>
          </div>
        </div>

        <!-- STEP 3: First Product -->
        <div v-if="currentStep === 3" class="space-y-5">
          <div class="flex items-center gap-3 mb-2">
            <div class="w-10 h-10 bg-amber-500/10 dark:bg-amber-500/20 rounded-xl flex items-center justify-center text-amber-500"><UIcon name="i-lucide-coffee" class="w-5 h-5" /></div>
            <div>
              <h3 class="font-semibold text-gray-900 dark:text-white">Add Your First Product</h3>
              <p class="text-xs text-gray-500 dark:text-gray-400">Optional — you can always add products later.</p>
            </div>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1.5">Product Name</label>
            <UInput v-model="product.name" placeholder="e.g. Signature Iced Latte" size="xl" class="w-full" />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1.5">Category</label>
            <UInput v-model="product.category" placeholder="e.g. Coffee, Pastry, Snacks" size="xl" class="w-full" />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1.5">Price ({{ storeInfo.currency }})</label>
            <UInput v-model="product.price" type="number" placeholder="e.g. 15" size="xl" class="w-full" />
          </div>
        </div>

        <!-- STEP 4: Cashier PIN -->
        <div v-if="currentStep === 4" class="space-y-6">
          <div class="flex items-center gap-3 mb-2">
            <div class="w-10 h-10 bg-green-500/10 dark:bg-green-500/20 rounded-xl flex items-center justify-center text-green-500"><UIcon name="i-lucide-shield-check" class="w-5 h-5" /></div>
            <div>
              <h3 class="font-semibold text-gray-900 dark:text-white">Secure Your Cashier</h3>
              <p class="text-xs text-gray-500 dark:text-gray-400">Set a 4-digit PIN for your POS screen. Optional.</p>
            </div>
          </div>

          <div class="text-center py-6">
            <p class="text-sm text-gray-600 dark:text-gray-400 mb-6">Enter a 4-digit PIN</p>
            <div class="flex justify-center gap-4">
              <input
                v-for="(_, i) in cashierPin"
                :key="i"
                :ref="el => { if (el) pinInputs[i] = el as HTMLInputElement }"
                v-model="cashierPin[i]"
                type="password"
                maxlength="1"
                inputmode="numeric"
                class="w-16 h-16 text-center text-2xl font-bold rounded-xl border-2 border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:border-primary focus:ring-2 focus:ring-primary/30 outline-none transition-all"
                @input="handlePinInput(i, $event)"
                @keydown="handlePinKeydown(i, $event)"
              />
            </div>
            <p class="text-xs text-gray-400 dark:text-gray-500 mt-4">This PIN locks the POS screen and approves voids.</p>
          </div>
        </div>
      </div>

      <!-- Footer -->
      <div class="px-10 py-6 border-t border-gray-100 dark:border-gray-800 flex justify-between items-center">
        <div>
          <UButton v-if="currentStep > 1" color="neutral" variant="ghost" label="Back" icon="i-lucide-arrow-left" @click="prevStep" />
        </div>
        <div class="flex items-center gap-3">
          <UButton v-if="currentStep >= 2" color="neutral" variant="ghost" label="Skip" @click="skipStep" />
          <UButton color="primary" :label="currentStep === totalSteps ? 'Finish Setup' : 'Continue'" :trailing-icon="currentStep === totalSteps ? 'i-lucide-check' : 'i-lucide-arrow-right'" size="lg" class="font-bold px-8 rounded-xl" :loading="loading" @click="nextStep" />
        </div>
      </div>
    </div>
  </div>
</template>
