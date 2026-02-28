<script setup lang="ts">
definePageMeta({ layout: 'backoffice' })

const client = useSupabaseClient()
const user = useSupabaseUser()
const loading = ref(true)
const saving = ref(false)

const settingsTabs = [
  { label: 'Store Profile', id: 'profile', icon: 'i-lucide-building' },
  { label: 'Operations', id: 'operations', icon: 'i-lucide-settings-2' },
  { label: 'Receipts', id: 'receipts', icon: 'i-lucide-receipt' },
  { label: 'Security & Roles', id: 'security', icon: 'i-lucide-shield' },
  { label: 'Integrations', id: 'integrations', icon: 'i-lucide-puzzle' },
]
const activeTab = ref('profile')

// Store Profile
const storeInfo = ref({
  name: 'Main Street Cafe',
  taxId: 'W10-1808-32000001',
  address: 'Lot 1.23, Main Street Mall, Jalan Sultan Ismail, 50250 Kuala Lumpur, Malaysia',
  phone: '+60 3-2141 1234',
  email: 'hello@mainstreetcafe.com',
})
const outletId = ref<string | null>(null)

// Operations
const operations = ref({
  currency: 'MYR - Malaysian Ringgit',
  timezone: '(GMT+08:00) Kuala Lumpur, Singapore',
  sst: 6,
  serviceCharge: 10,
})

// Receipts
const receipts = ref({
  header: 'Welcome to Main Street Cafe!',
  footer: 'Thank you for dining with us!',
  showLogo: true,
  showSocial: true,
})

// Roles
const roles = ref([
  { name: 'Admin', pos: true, refunds: true, reports: true, settings: true },
  { name: 'Store Manager', pos: true, refunds: true, reports: true, settings: false },
  { name: 'Cashier', pos: true, refunds: false, reports: false, settings: false },
])

// Integrations
const integrations = ref([
  { name: 'Kitchen Printer', desc: 'EPSON TM-T82III (192.168.1.102)', status: 'Connected', statusColor: 'text-green-600', icon: 'i-lucide-printer', action: 'Configure' },
  { name: 'EDC Terminal', desc: 'Maybank Move 2500', status: 'Connected', statusColor: 'text-green-600', icon: 'i-lucide-credit-card', action: 'Configure' },
  { name: 'Food Delivery', desc: 'GrabFood / FoodPanda Integration', status: 'Disconnected', statusColor: 'text-red-500', icon: 'i-lucide-truck', action: 'Connect' },
])

onMounted(async () => {
  if (!user.value) return
  try {
    const { data: profile } = await client.from('profiles').select('outlet_id').eq('id', user.value.id).single()
    outletId.value = profile?.outlet_id || null
    if (!outletId.value) return

    const { data: outlet } = await client.from('outlets').select('*').eq('id', outletId.value).single()
    if (outlet) {
      storeInfo.value.name = outlet.name || storeInfo.value.name
      storeInfo.value.phone = outlet.phone || storeInfo.value.phone
      storeInfo.value.address = outlet.address || storeInfo.value.address
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
    }).eq('id', outletId.value)
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <div class="space-y-6">
    <div class="flex justify-between items-start">
      <h2 class="text-2xl font-bold text-gray-900">Settings</h2>
      <UButton v-if="activeTab === 'profile'" color="primary" label="Save changes" @click="saveGeneral" :loading="saving" />
    </div>

    <div class="bg-white rounded-xl border border-gray-100 shadow-sm flex overflow-hidden min-h-[700px]">
      <!-- Settings Navigation (Left side) -->
      <div class="w-60 border-r border-gray-100 p-4 bg-gray-50/50 flex flex-col gap-1 flex-shrink-0">
        <button
          v-for="tab in settingsTabs"
          :key="tab.id"
          @click="activeTab = tab.id"
          :class="[
            'flex items-center gap-3 text-left px-4 py-3 rounded-lg text-sm font-medium transition-colors',
            activeTab === tab.id ? 'bg-primary text-white' : 'text-gray-600 hover:bg-gray-100'
          ]"
        >
          <UIcon :name="tab.icon" class="w-5 h-5" />
          {{ tab.label }}
        </button>
      </div>

      <!-- Settings Content -->
      <div class="flex-1 p-8 overflow-y-auto">

        <!-- Store Profile -->
        <div v-show="activeTab === 'profile'" class="space-y-8 max-w-3xl">
          <div>
            <h3 class="text-lg font-semibold text-gray-900">Store Profile</h3>
            <p class="text-sm text-gray-500 mt-1">Manage your basic store information and branding.</p>
          </div>

          <!-- Logo Upload -->
          <div class="flex items-center gap-6">
            <div class="w-20 h-20 bg-gray-100 rounded-xl flex items-center justify-center border-2 border-dashed border-gray-300">
              <UIcon name="i-lucide-image-plus" class="w-8 h-8 text-gray-400" />
            </div>
            <div>
              <p class="font-medium text-gray-900">Store Logo</p>
              <p class="text-xs text-gray-500 mt-0.5">Recommended size: 512×512px. JPG, PNG supported.</p>
              <button class="text-sm text-primary mt-1 hover:underline">Upload New Logo</button>
            </div>
          </div>

          <div class="grid grid-cols-2 gap-6">
            <UFormGroup label="Store Name">
              <UInput v-model="storeInfo.name" />
            </UFormGroup>
            <UFormGroup label="Tax ID / SST Registration No.">
              <UInput v-model="storeInfo.taxId" />
            </UFormGroup>
          </div>
          <UFormGroup label="Address">
            <UTextarea v-model="storeInfo.address" autoresize />
          </UFormGroup>
          <div class="grid grid-cols-2 gap-6">
            <UFormGroup label="Contact Number">
              <UInput v-model="storeInfo.phone" />
            </UFormGroup>
            <UFormGroup label="Email Address">
              <UInput v-model="storeInfo.email" type="email" />
            </UFormGroup>
          </div>
        </div>

        <!-- Operations -->
        <div v-show="activeTab === 'operations'" class="space-y-8 max-w-3xl">
          <div>
            <h3 class="text-lg font-semibold text-gray-900">Operational Settings</h3>
            <p class="text-sm text-gray-500 mt-1">Configure currency, taxes, and service charges.</p>
          </div>

          <div class="grid grid-cols-2 gap-6">
            <UFormGroup label="Default Currency">
              <USelect v-model="operations.currency" :options="['MYR - Malaysian Ringgit', 'SGD - Singapore Dollar', 'USD - US Dollar']" />
            </UFormGroup>
            <UFormGroup label="Time Zone">
              <USelect v-model="operations.timezone" :options="['(GMT+08:00) Kuala Lumpur, Singapore', '(GMT+07:00) Jakarta', '(GMT+09:00) Tokyo']" />
            </UFormGroup>
          </div>

          <div>
            <h4 class="font-semibold text-gray-900 mb-4">Taxes & Fees</h4>
            <div class="space-y-4">
              <div class="flex items-center justify-between p-4 bg-gray-50 rounded-xl">
                <div class="flex items-center gap-3">
                  <span class="w-6 h-6 bg-green-500 rounded-full flex items-center justify-center"><UIcon name="i-lucide-check" class="w-4 h-4 text-white" /></span>
                  <div>
                    <p class="font-medium text-gray-900">SST (Sales and Service Tax)</p>
                    <p class="text-xs text-gray-500">Applied to all taxable items</p>
                  </div>
                </div>
                <div class="flex items-center gap-2">
                  <UInput v-model.number="operations.sst" class="w-16 text-center" />
                  <span class="text-gray-500">%</span>
                </div>
              </div>
              <div class="flex items-center justify-between p-4 bg-gray-50 rounded-xl">
                <div class="flex items-center gap-3">
                  <span class="w-6 h-6 bg-green-500 rounded-full flex items-center justify-center"><UIcon name="i-lucide-check" class="w-4 h-4 text-white" /></span>
                  <div>
                    <p class="font-medium text-gray-900">Service Charge</p>
                    <p class="text-xs text-gray-500">Applied to dine-in orders only</p>
                  </div>
                </div>
                <div class="flex items-center gap-2">
                  <UInput v-model.number="operations.serviceCharge" class="w-16 text-center" />
                  <span class="text-gray-500">%</span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Receipts -->
        <div v-show="activeTab === 'receipts'" class="space-y-8 max-w-3xl">
          <div>
            <h3 class="text-lg font-semibold text-gray-900">Receipt Customization</h3>
            <p class="text-sm text-gray-500 mt-1">Customize how your printed receipts look.</p>
          </div>

          <div class="grid grid-cols-2 gap-8">
            <div class="space-y-4">
              <UFormGroup label="Header Text">
                <UInput v-model="receipts.header" />
              </UFormGroup>
              <UFormGroup label="Footer Text">
                <UInput v-model="receipts.footer" />
              </UFormGroup>
              <div class="flex items-center justify-between py-3">
                <span class="text-sm text-gray-700">Show Logo on Receipt</span>
                <UToggle v-model="receipts.showLogo" color="primary" />
              </div>
              <div class="flex items-center justify-between py-3">
                <span class="text-sm text-gray-700">Show Social Media Links</span>
                <UToggle v-model="receipts.showSocial" color="primary" />
              </div>
            </div>
            <!-- Receipt Preview -->
            <div class="border border-gray-200 rounded-xl p-6 bg-gray-50">
              <div class="bg-white rounded-lg p-4 shadow-sm text-center font-mono text-xs space-y-2">
                <div class="w-10 h-10 bg-gray-200 rounded-full mx-auto"></div>
                <p class="font-bold text-sm">MAIN STREET CAFE</p>
                <p class="text-gray-500">Lot 1.23, Main Street Mall</p>
                <div class="border-t border-dashed border-gray-300 my-2"></div>
                <div class="flex justify-between"><span>Latte</span><span>12.00</span></div>
                <div class="flex justify-between"><span>Croissant</span><span>8.50</span></div>
                <div class="border-t border-dashed border-gray-300 my-2"></div>
                <div class="flex justify-between font-bold"><span>TOTAL</span><span>20.50</span></div>
                <p class="text-gray-500 mt-2">{{ receipts.footer }}</p>
              </div>
              <p class="text-center text-xs text-gray-400 mt-3">Live Preview</p>
            </div>
          </div>
        </div>

        <!-- Security & Roles -->
        <div v-show="activeTab === 'security'" class="space-y-8 max-w-3xl">
          <div>
            <h3 class="text-lg font-semibold text-gray-900">Security & Roles</h3>
            <p class="text-sm text-gray-500 mt-1">Manage access permissions for different employee roles.</p>
          </div>

          <table class="w-full text-sm">
            <thead>
              <tr class="border-b border-gray-200">
                <th class="text-left py-3 text-xs font-medium text-gray-500 uppercase tracking-wider">Role</th>
                <th class="text-center py-3 text-xs font-medium text-gray-500 uppercase tracking-wider">POS Access</th>
                <th class="text-center py-3 text-xs font-medium text-gray-500 uppercase tracking-wider">Refunds</th>
                <th class="text-center py-3 text-xs font-medium text-gray-500 uppercase tracking-wider">Reports</th>
                <th class="text-center py-3 text-xs font-medium text-gray-500 uppercase tracking-wider">Settings</th>
                <th class="text-right py-3"></th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100">
              <tr v-for="role in roles" :key="role.name">
                <td class="py-4 font-medium text-gray-900">{{ role.name }}</td>
                <td class="py-4 text-center">
                  <UIcon :name="role.pos ? 'i-lucide-check-circle' : 'i-lucide-x-circle'" :class="role.pos ? 'text-green-500' : 'text-gray-300'" class="w-5 h-5" />
                </td>
                <td class="py-4 text-center">
                  <UIcon :name="role.refunds ? 'i-lucide-check-circle' : 'i-lucide-x-circle'" :class="role.refunds ? 'text-green-500' : 'text-gray-300'" class="w-5 h-5" />
                </td>
                <td class="py-4 text-center">
                  <UIcon :name="role.reports ? 'i-lucide-check-circle' : 'i-lucide-x-circle'" :class="role.reports ? 'text-green-500' : 'text-gray-300'" class="w-5 h-5" />
                </td>
                <td class="py-4 text-center">
                  <UIcon :name="role.settings ? 'i-lucide-check-circle' : 'i-lucide-x-circle'" :class="role.settings ? 'text-green-500' : 'text-gray-300'" class="w-5 h-5" />
                </td>
                <td class="py-4 text-right">
                  <button class="text-sm text-primary hover:underline">Edit</button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <!-- Integrations -->
        <div v-show="activeTab === 'integrations'" class="space-y-8 max-w-3xl">
          <div>
            <h3 class="text-lg font-semibold text-gray-900">Hardware & Integrations</h3>
            <p class="text-sm text-gray-500 mt-1">Connect your printers, payment terminals, and delivery platforms.</p>
          </div>

          <div class="grid grid-cols-3 gap-4">
            <div v-for="hw in integrations" :key="hw.name" class="border border-gray-200 rounded-xl p-5 text-center">
              <div class="flex justify-between items-start mb-3">
                <UIcon :name="hw.icon" class="w-8 h-8 text-gray-400" />
                <span class="text-xs font-semibold" :class="hw.statusColor">{{ hw.status }}</span>
              </div>
              <p class="font-semibold text-gray-900 mt-2">{{ hw.name }}</p>
              <p class="text-xs text-gray-500 mt-1">{{ hw.desc }}</p>
              <button
                :class="[
                  'mt-4 w-full py-2 text-sm font-medium rounded-lg border transition-colors',
                  hw.status === 'Connected'
                    ? 'border-gray-200 text-gray-600 hover:bg-gray-50'
                    : 'border-red-200 text-red-600 bg-red-50 hover:bg-red-100'
                ]"
              >
                {{ hw.action }}
              </button>
            </div>
          </div>
        </div>

      </div>
    </div>
  </div>
</template>
