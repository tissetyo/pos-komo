<script setup lang="ts">
definePageMeta({ layout: 'backoffice' })

const client = useSupabaseClient()
const user = useSupabaseUser()
const loading = ref(true)
const saving = ref(false)

const settingsTabs = [
  { label: 'General Info', id: 'general' },
  { label: 'Feature Toggles', id: 'toggles' }
]
const activeTab = ref('general')

// General Info
const storeInfo = ref({
  name: '',
  phone: '',
  address: '',
  timezone: 'Asia/Jakarta',
  storeType: 'Kafe/Coffee Shop'
})
const outletId = ref<string | null>(null)

// Feature Toggles
const toggles = ref([
  { id: 'realtime', name: 'Real-time Kitchen Status', desc: 'Enable WebSocket connection between cashier and kitchen display.', enabled: true, module: 'Cashier' },
  { id: 'autoprint', name: 'Auto-Print Receipts', desc: 'Automatically print receipt upon payment completion.', enabled: true, module: 'Cashier' },
  { id: 'cashdrawer', name: 'Cash Drawer Integration', desc: 'Kick open drawer automatically on cash transaction.', enabled: false, module: 'Cashier' },
  { id: 'analytics', name: 'Analytics Dashboard', desc: 'Show detailed performance and revenue metrics.', enabled: true, module: 'Backoffice' },
  { id: 'multioutlet', name: 'Multi-Outlet Management', desc: 'Enable switching and managing multiple stores.', enabled: true, module: 'Backoffice' }
])

onMounted(async () => {
  if (!user.value) return
  try {
    const { data: profile } = await client.from('profiles').select('outlet_id').eq('id', user.value.id).single()
    outletId.value = profile?.outlet_id || null
    if (!outletId.value) return

    const { data: outlet } = await client.from('outlets').select('*').eq('id', outletId.value).single()
    if (outlet) {
      storeInfo.value = {
        name: outlet.name || '',
        phone: outlet.phone || '',
        address: outlet.address || '',
        timezone: outlet.timezone || 'Asia/Jakarta',
        storeType: outlet.store_type || 'Kafe/Coffee Shop'
      }
    }
  } finally {
    loading.value = false
  }
})

const saveGeneral = async () => {
  if (!outletId.value) return
  saving.value = true
  try {
    await client.from('outlets').update({
      name: storeInfo.value.name,
      phone: storeInfo.value.phone,
      address: storeInfo.value.address,
      timezone: storeInfo.value.timezone,
      store_type: storeInfo.value.storeType
    }).eq('id', outletId.value)
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <div class="max-w-4xl mx-auto space-y-6">
    <div>
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Store Settings</h2>
      <p class="text-gray-500 dark:text-gray-400 text-sm mt-1">Configure your POS preferences and feature toggles.</p>
    </div>

    <div class="bg-white dark:bg-gray-900 rounded-2xl shadow-sm border border-gray-100 dark:border-gray-800 flex flex-col md:flex-row overflow-hidden min-h-[600px]">

      <!-- Settings Navigation -->
      <div class="w-full md:w-64 border-b md:border-b-0 md:border-r border-gray-100 dark:border-gray-800 p-4 bg-gray-50/50 dark:bg-gray-800/30 flex flex-col gap-1">
        <button
          v-for="tab in settingsTabs"
          :key="tab.id"
          @click="activeTab = tab.id"
          :class="[
            'text-left px-4 py-3 rounded-lg text-sm font-medium transition-colors',
            activeTab === tab.id ? 'bg-primary/10 dark:bg-primary/20 text-primary' : 'text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800'
          ]"
        >
          {{ tab.label }}
        </button>
      </div>

      <!-- Settings Content -->
      <div class="flex-1 p-6 md:p-8">

        <!-- General Info -->
        <div v-show="activeTab === 'general'" class="space-y-6">
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white border-b border-gray-100 dark:border-gray-800 pb-2 mb-4">General Information</h3>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <UFormGroup label="Store Name" required>
              <UInput v-model="storeInfo.name" />
            </UFormGroup>
            <UFormGroup label="Phone Number">
              <UInput v-model="storeInfo.phone" />
            </UFormGroup>
             <UFormGroup label="Store Address" class="md:col-span-2">
              <UTextarea v-model="storeInfo.address" autoresize />
            </UFormGroup>
            <UFormGroup label="Timezone">
              <USelect v-model="storeInfo.timezone" :options="['Asia/Jakarta', 'Asia/Makassar', 'Asia/Jayapura']" />
            </UFormGroup>
             <UFormGroup label="Store Type">
              <USelect v-model="storeInfo.storeType" :options="['Kafe/Coffee Shop', 'Restaurant', 'Food Court', 'Cloud Kitchen']" />
            </UFormGroup>
          </div>
          <div class="pt-6">
             <UButton color="primary" label="Save Changes" class="w-full md:w-auto px-8" :loading="saving" @click="saveGeneral" />
          </div>
        </div>

        <!-- Feature Toggles -->
        <div v-show="activeTab === 'toggles'" class="space-y-6">
          <div class="flex justify-between">
            <h3 class="text-lg font-semibold text-gray-900 dark:text-white border-b border-gray-100 dark:border-gray-800 pb-2 mb-2">Feature Toggles</h3>
          </div>
          <p class="text-sm text-gray-500 dark:text-gray-400 mb-6">Enable or disable specific modules across the POS system.</p>

          <div class="space-y-4">
            <div v-for="toggle in toggles" :key="toggle.id" class="flex items-start justify-between p-4 bg-gray-50 dark:bg-gray-800/50 rounded-xl border border-gray-100 dark:border-gray-700">
              <div class="pr-4">
                <div class="flex items-center gap-2">
                  <h4 class="font-semibold text-gray-900 dark:text-white">{{ toggle.name }}</h4>
                  <UBadge color="neutral" variant="soft" size="xs">{{ toggle.module }}</UBadge>
                </div>
                <p class="text-sm text-gray-500 dark:text-gray-400 mt-1">{{ toggle.desc }}</p>
              </div>
              <UToggle v-model="toggle.enabled" color="primary" class="mt-1 flex-shrink-0" />
            </div>
          </div>
        </div>

      </div>
    </div>
  </div>
</template>
