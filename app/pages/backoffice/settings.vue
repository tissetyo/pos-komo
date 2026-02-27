<script setup lang="ts">
definePageMeta({ layout: 'backoffice' })

const settingsTabs = [
  { label: 'General Info', id: 'general' },
  { label: 'Feature Toggles', id: 'toggles' },
  { label: 'Printer & Hardware', id: 'hardware' },
  { label: 'Taxes & Receipts', id: 'receipts' },
]
const activeTab = ref('general')

// Feature Toggles State (From US-019 / KOMO-018)
const toggles = ref([
  { id: 'realtime', name: 'Real-time Kitchen Status', desc: 'Enable WebSocket connection between cashier and kitchen display.', enabled: true, module: 'Cashier' },
  { id: 'autoprint', name: 'Auto-Print Receipts', desc: 'Automatically print receipt upon payment completion.', enabled: true, module: 'Cashier' },
  { id: 'cashdrawer', name: 'Cash Drawer Integration', desc: 'Kick open drawer automatically on cash transaction.', enabled: false, module: 'Cashier' },
  { id: 'analytics', name: 'Analytics Dashboard', desc: 'Show detailed performance and revenue metrics.', enabled: true, module: 'Backoffice' },
  { id: 'multioutlet', name: 'Multi-Outlet Management', desc: 'Enable switching and managing multiple stores.', enabled: true, module: 'Backoffice' },
])

</script>

<template>
  <div class="max-w-4xl mx-auto space-y-6">
    <div>
      <h2 class="text-2xl font-bold text-gray-900">Store Settings</h2>
      <p class="text-gray-500 text-sm mt-1">Configure your POS preferences, hardware, and feature toggles.</p>
    </div>

    <div class="bg-white rounded-2xl shadow-sm border border-gray-100 flex flex-col md:flex-row overflow-hidden min-h-[600px]">
      
      <!-- Settings Navigation -->
      <div class="w-full md:w-64 border-b md:border-b-0 md:border-r border-gray-100 p-4 bg-gray-50/50 flex flex-col gap-1">
        <button 
          v-for="tab in settingsTabs" 
          :key="tab.id"
          @click="activeTab = tab.id"
          :class="[
            'text-left px-4 py-3 rounded-lg text-sm font-medium transition-colors',
            activeTab === tab.id ? 'bg-primary-50 text-primary-700' : 'text-gray-600 hover:bg-gray-100'
          ]"
        >
          {{ tab.label }}
        </button>
      </div>

      <!-- Settings Content -->
      <div class="flex-1 p-6 md:p-8">
        
        <!-- General Info -->
        <div v-show="activeTab === 'general'" class="space-y-6">
          <h3 class="text-lg font-semibold text-gray-900 border-b border-gray-100 pb-2 mb-4">General Information</h3>
          
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <UFormGroup label="Store Name" required>
              <UInput value="Komo Cafe - Central Park" />
            </UFormGroup>
            <UFormGroup label="Phone Number">
              <UInput value="021-555-0100" />
            </UFormGroup>
             <UFormGroup label="Store Address" class="md:col-span-2">
              <UTextarea value="Jl. Letjen S. Parman No.28, Tj. Duren Sel., Grogol petamburan, Kota Jakarta Barat, Daerah Khusus Ibukota Jakarta 11470" autoresize />
            </UFormGroup>
            <UFormGroup label="Timezone">
              <USelectMenu :options="['Asia/Jakarta (WIB)', 'Asia/Makassar (WITA)', 'Asia/Jayapura (WIT)']" value="Asia/Jakarta (WIB)" />
            </UFormGroup>
             <UFormGroup label="Store Type">
              <USelectMenu :options="['Kafe/Coffee Shop', 'Restaurant', 'Food Court', 'Cloud Kitchen']" value="Kafe/Coffee Shop" />
            </UFormGroup>
          </div>
          <div class="pt-6">
             <UButton color="primary" label="Save Changes" class="w-full md:w-auto px-8" />
          </div>
        </div>

        <!-- Feature Toggles -->
        <div v-show="activeTab === 'toggles'" class="space-y-6">
          <div class="flexjustify-between">
            <h3 class="text-lg font-semibold text-gray-900 border-b border-gray-100 pb-2 mb-2">Feature Toggles</h3>
            <p class="text-sm text-gray-500 mb-6">Enable or disable specific modules across the POS system to simplify the UI based on your needs.</p>
          </div>

          <div class="space-y-6">
            <div v-for="toggle in toggles" :key="toggle.id" class="flex items-start justify-between p-4 bg-gray-50 rounded-xl border border-gray-100">
              <div class="pr-4">
                <div class="flex items-center gap-2">
                  <h4 class="font-semibold text-gray-900">{{ toggle.name }}</h4>
                  <UBadge color="gray" variant="soft" size="xs">{{ toggle.module }}</UBadge>
                </div>
                <p class="text-sm text-gray-500 mt-1">{{ toggle.desc }}</p>
              </div>
              <UToggle v-model="toggle.enabled" color="primary" class="mt-1 flex-shrink-0" />
            </div>
          </div>
        </div>

      </div>
    </div>
  </div>
</template>
