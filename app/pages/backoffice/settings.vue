<script setup lang="ts">
definePageMeta({ layout: 'backoffice' })

const client = useSupabaseClient()
const user = useSupabaseUser()
const loading = ref(true)
const saving = ref(false)
const saveSuccess = ref(false)

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
  name: '',
  address: '',
  city: '',
  phone: '',
  email: '',
  store_type: '',
})
const outletId = ref<string | null>(null)

// Operations
const operations = ref({
  currency: 'IDR',
  timezone: 'Asia/Jakarta',
  sst: 10,
  serviceCharge: 0,
})

// Receipts
const receipts = ref({
  header: 'Welcome!',
  footer: 'Thank you for your visit!',
  showLogo: true,
  showSocial: true,
})

// Roles
const roles = ref([
  { name: 'Admin', pos: true, refunds: true, reports: true, settings: true },
  { name: 'Manager', pos: true, refunds: true, reports: true, settings: false },
  { name: 'Cashier', pos: true, refunds: false, reports: false, settings: false },
  { name: 'Kitchen', pos: false, refunds: false, reports: false, settings: false },
])

// Integrations
const integrations = ref([
  { name: 'Kitchen Printer', desc: 'Connect via USB or network IP', status: 'Not configured', statusColor: 'text-gray-500', icon: 'i-lucide-printer', action: 'Configure' },
  { name: 'Payment Terminal', desc: 'EDC / card reader integration', status: 'Not configured', statusColor: 'text-gray-500', icon: 'i-lucide-credit-card', action: 'Configure' },
  { name: 'Food Delivery', desc: 'GrabFood, ShopeeFood integration', status: 'Coming Soon', statusColor: 'text-amber-500', icon: 'i-lucide-truck', action: 'Learn More' },
])

const currencyOptions = ['IDR', 'MYR', 'SGD', 'USD', 'PHP', 'THB']
const timezoneOptions = ['Asia/Jakarta', 'Asia/Kuala_Lumpur', 'Asia/Singapore', 'Asia/Bangkok', 'Asia/Manila']

onMounted(async () => {
  if (!user.value) return
  try {
    const { data: profile } = await client.from('profiles').select('outlet_id, email').eq('id', user.value.id).single()
    outletId.value = profile?.outlet_id || null
    storeInfo.value.email = profile?.email || ''
    if (!outletId.value) return

    const { data: outlet } = await client.from('outlets').select('*').eq('id', outletId.value).single()
    if (outlet) {
      storeInfo.value.name = outlet.name || ''
      storeInfo.value.phone = outlet.phone || ''
      storeInfo.value.address = outlet.address || ''
      storeInfo.value.city = outlet.city || ''
      storeInfo.value.store_type = outlet.store_type || ''
      operations.value.currency = outlet.currency || 'IDR'
      operations.value.timezone = outlet.timezone || 'Asia/Jakarta'
    }
  } finally {
    loading.value = false
  }
})

const saveSettings = async () => {
  if (!outletId.value) return
  saving.value = true
  saveSuccess.value = false
  try {
    await client.from('outlets').update({
      name: storeInfo.value.name,
      phone: storeInfo.value.phone,
      address: storeInfo.value.address,
      city: storeInfo.value.city,
      store_type: storeInfo.value.store_type,
      currency: operations.value.currency,
      timezone: operations.value.timezone,
    }).eq('id', outletId.value)
    saveSuccess.value = true
    setTimeout(() => { saveSuccess.value = false }, 3000)
  } catch (err: any) {
    alert(err.message || 'Failed to save')
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <div class="space-y-6">
    <div class="flex justify-between items-start">
      <div>
        <h2 class="text-2xl font-bold text-gray-900">Settings</h2>
        <p class="text-sm text-gray-500 mt-1">Manage your store configuration and preferences.</p>
      </div>
      <div class="flex items-center gap-3">
        <span v-if="saveSuccess" class="text-sm text-green-600 font-medium flex items-center gap-1">
          <UIcon name="i-lucide-check-circle" class="w-4 h-4" /> Saved!
        </span>
        <UButton color="primary" label="Save Changes" @click="saveSettings" :loading="saving" icon="i-lucide-save" />
      </div>
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

          <!-- Pro Tip -->
          <div class="bg-blue-50 border border-blue-200 rounded-xl px-4 py-3 flex items-start gap-3">
            <UIcon name="i-lucide-lightbulb" class="w-4 h-4 text-blue-500 mt-0.5 flex-shrink-0" />
            <p class="text-sm text-blue-700">Store name and address will appear on printed receipts and the sidebar navigation.</p>
          </div>

          <div class="grid grid-cols-2 gap-6">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1.5">Store Name</label>
              <UInput v-model="storeInfo.name" placeholder="Your store name" />
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1.5">Store Type</label>
              <UInput v-model="storeInfo.store_type" placeholder="e.g. Cafe, Restaurant" />
            </div>
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1.5">Address</label>
            <UTextarea v-model="storeInfo.address" autoresize placeholder="Full store address" />
          </div>
          <div class="grid grid-cols-2 gap-6">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1.5">City</label>
              <UInput v-model="storeInfo.city" placeholder="City" />
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1.5">Contact Number</label>
              <UInput v-model="storeInfo.phone" placeholder="+62 xxx xxxx xxxx" />
            </div>
          </div>
        </div>

        <!-- Operations -->
        <div v-show="activeTab === 'operations'" class="space-y-8 max-w-3xl">
          <div>
            <h3 class="text-lg font-semibold text-gray-900">Operational Settings</h3>
            <p class="text-sm text-gray-500 mt-1">Configure currency, taxes, and service charges.</p>
          </div>

          <div class="bg-blue-50 border border-blue-200 rounded-xl px-4 py-3 flex items-start gap-3">
            <UIcon name="i-lucide-lightbulb" class="w-4 h-4 text-blue-500 mt-0.5 flex-shrink-0" />
            <p class="text-sm text-blue-700">Tax rates are automatically applied to all new orders created from the POS.</p>
          </div>

          <div class="grid grid-cols-2 gap-6">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1.5">Default Currency</label>
              <select v-model="operations.currency" class="w-full h-10 px-3 rounded-lg border border-gray-300 text-sm focus:ring-2 focus:ring-primary outline-none">
                <option v-for="c in currencyOptions" :key="c" :value="c">{{ c }}</option>
              </select>
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1.5">Time Zone</label>
              <select v-model="operations.timezone" class="w-full h-10 px-3 rounded-lg border border-gray-300 text-sm focus:ring-2 focus:ring-primary outline-none">
                <option v-for="tz in timezoneOptions" :key="tz" :value="tz">{{ tz }}</option>
              </select>
            </div>
          </div>

          <div>
            <h4 class="font-semibold text-gray-900 mb-4">Taxes & Fees</h4>
            <div class="space-y-4">
              <div class="flex items-center justify-between p-4 bg-gray-50 rounded-xl">
                <div class="flex items-center gap-3">
                  <span class="w-6 h-6 bg-green-500 rounded-full flex items-center justify-center"><UIcon name="i-lucide-check" class="w-4 h-4 text-white" /></span>
                  <div>
                    <p class="font-medium text-gray-900">Tax</p>
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

          <div class="bg-blue-50 border border-blue-200 rounded-xl px-4 py-3 flex items-start gap-3">
            <UIcon name="i-lucide-lightbulb" class="w-4 h-4 text-blue-500 mt-0.5 flex-shrink-0" />
            <p class="text-sm text-blue-700">The live preview on the right shows exactly how your printed receipt will look.</p>
          </div>

          <div class="grid grid-cols-2 gap-8">
            <div class="space-y-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1.5">Header Text</label>
                <UInput v-model="receipts.header" />
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1.5">Footer Text</label>
                <UInput v-model="receipts.footer" />
              </div>
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
                <p class="font-bold text-sm uppercase">{{ storeInfo.name || 'Your Store' }}</p>
                <p class="text-gray-500 text-[10px]">{{ storeInfo.address || 'Store address' }}</p>
                <p class="text-gray-400 italic text-[10px]">{{ receipts.header }}</p>
                <div class="border-t border-dashed border-gray-300 my-2"></div>
                <div class="flex justify-between"><span>Item 1</span><span>12.00</span></div>
                <div class="flex justify-between"><span>Item 2</span><span>8.50</span></div>
                <div class="border-t border-dashed border-gray-300 my-2"></div>
                <div class="flex justify-between font-bold"><span>TOTAL</span><span>20.50</span></div>
                <div class="border-t border-dashed border-gray-300 my-2"></div>
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

          <div class="bg-blue-50 border border-blue-200 rounded-xl px-4 py-3 flex items-start gap-3">
            <UIcon name="i-lucide-lightbulb" class="w-4 h-4 text-blue-500 mt-0.5 flex-shrink-0" />
            <p class="text-sm text-blue-700">Roles control what each employee can access. Assign roles when adding employees from the Employees page.</p>
          </div>

          <table class="w-full text-sm">
            <thead>
              <tr class="border-b border-gray-200">
                <th class="text-left py-3 text-xs font-medium text-gray-500 uppercase tracking-wider">Role</th>
                <th class="text-center py-3 text-xs font-medium text-gray-500 uppercase tracking-wider">POS Access</th>
                <th class="text-center py-3 text-xs font-medium text-gray-500 uppercase tracking-wider">Refunds</th>
                <th class="text-center py-3 text-xs font-medium text-gray-500 uppercase tracking-wider">Reports</th>
                <th class="text-center py-3 text-xs font-medium text-gray-500 uppercase tracking-wider">Settings</th>
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

          <div class="bg-blue-50 border border-blue-200 rounded-xl px-4 py-3 flex items-start gap-3">
            <UIcon name="i-lucide-lightbulb" class="w-4 h-4 text-blue-500 mt-0.5 flex-shrink-0" />
            <p class="text-sm text-blue-700">Hardware integrations allow your POS to print kitchen tickets and process card payments directly.</p>
          </div>

          <div class="grid grid-cols-3 gap-4">
            <div v-for="hw in integrations" :key="hw.name" class="border border-gray-200 rounded-xl p-5">
              <div class="flex justify-between items-start mb-3">
                <UIcon :name="hw.icon" class="w-8 h-8 text-gray-400" />
                <span class="text-xs font-semibold" :class="hw.statusColor">{{ hw.status }}</span>
              </div>
              <p class="font-semibold text-gray-900 mt-2">{{ hw.name }}</p>
              <p class="text-xs text-gray-500 mt-1">{{ hw.desc }}</p>
              <button class="mt-4 w-full py-2 text-sm font-medium rounded-lg border border-gray-200 text-gray-600 hover:bg-gray-50 transition-colors">
                {{ hw.action }}
              </button>
            </div>
          </div>
        </div>

      </div>
    </div>
  </div>
</template>
