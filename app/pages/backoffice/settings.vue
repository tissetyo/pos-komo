<script setup lang="ts">
definePageMeta({ layout: 'backoffice' })

const { client, outletId, userId, profileReady } = useUserProfile()
const { symbol: currencySymbol } = useCurrency()
const loading = ref(true)
const saving = ref(false)
const saveSuccess = ref(false)

// Store Profile
const storeInfo = ref({
  name: '',
  address: '',
  city: '',
  phone: '',
  email: '',
  store_type: '',
  tax_id: '',
})
const logoUrl = ref('')
const logoFile = ref<File | null>(null)

// Operations
const operations = ref({
  currency: 'MYR',
  timezone: 'Asia/Kuala_Lumpur',
  sst: 6,
  serviceCharge: 10,
})

// Receipts
const receipts = ref({
  header: 'Welcome to our store!',
  footer: 'Thank you for dining with us',
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
  { name: 'Kitchen Printer', subtitle: 'EPSON TM-T82III', icon: 'i-lucide-printer', status: 'connected' },
  { name: 'EDC Terminal', subtitle: 'Ingenico Move 3500', icon: 'i-lucide-credit-card', status: 'connected' },
  { name: 'Food Delivery', subtitle: 'GrabFood, Food Panda', icon: 'i-lucide-truck', status: 'disconnected' },
])

const currencyOptions = [
  { label: 'MYR - Malaysian Ringgit', value: 'MYR' },
  { label: 'IDR - Indonesian Rupiah', value: 'IDR' },
  { label: 'SGD - Singapore Dollar', value: 'SGD' },
  { label: 'USD - US Dollar', value: 'USD' },
  { label: 'PHP - Philippine Peso', value: 'PHP' },
  { label: 'THB - Thai Baht', value: 'THB' },
]
const timezoneOptions = [
  { label: '(GMT+08:00) Kuala Lumpur, Singapore', value: 'Asia/Kuala_Lumpur' },
  { label: '(GMT+07:00) Jakarta, WIB', value: 'Asia/Jakarta' },
  { label: '(GMT+08:00) Makassar, WITA', value: 'Asia/Makassar' },
  { label: '(GMT+07:00) Bangkok', value: 'Asia/Bangkok' },
  { label: '(GMT+08:00) Manila', value: 'Asia/Manila' },
]

const tips = [
  'Upload a store logo to personalize your receipts and branding.',
  'Set your tax rate (SST) and service charge to auto-calculate on orders.',
  'Configure receipt text to add a personal touch for your customers.',
]

const handleLogoUpload = (e: Event) => {
  const target = e.target as HTMLInputElement
  const file = target.files?.[0]
  if (file) {
    logoFile.value = file
    logoUrl.value = URL.createObjectURL(file)
  }
}

const loadSettings = async () => {
  if (!outletId.value) return
  try {
    // Load profile email
    if (userId.value) {
      const { data: prof } = await client.from('profiles').select('email').eq('id', userId.value).single()
      if (prof) storeInfo.value.email = prof.email || ''
    }

    const { data: outlet } = await client.from('outlets').select('*').eq('id', outletId.value).single()
    if (outlet) {
      storeInfo.value.name = outlet.name || ''
      storeInfo.value.phone = outlet.phone || ''
      storeInfo.value.address = outlet.address || ''
      storeInfo.value.city = outlet.city || ''
      storeInfo.value.store_type = outlet.store_type || ''
      storeInfo.value.tax_id = (outlet as any).tax_id || ''
      operations.value.currency = outlet.currency || 'MYR'
      operations.value.timezone = outlet.timezone || 'Asia/Kuala_Lumpur'
      operations.value.sst = (outlet as any).sst ?? 6
      operations.value.serviceCharge = (outlet as any).service_charge ?? 10
      logoUrl.value = (outlet as any).logo_url || ''

      // Load receipt settings if stored
      if ((outlet as any).receipt_header) receipts.value.header = (outlet as any).receipt_header
      if ((outlet as any).receipt_footer) receipts.value.footer = (outlet as any).receipt_footer
    }
  } finally {
    loading.value = false
  }
}

watch(profileReady, (ready) => { if (ready) loadSettings() })

const saveSettings = async () => {
  if (!outletId.value) return
  saving.value = true
  saveSuccess.value = false
  try {
    // Upload logo if changed
    let finalLogoUrl = logoUrl.value
    if (logoFile.value) {
      const ext = logoFile.value.name.split('.').pop()
      const path = `${outletId.value}/logo.${ext}`
      await client.storage.from('product-images').upload(path, logoFile.value, { upsert: true })
      const { data: urlData } = client.storage.from('product-images').getPublicUrl(path)
      finalLogoUrl = urlData.publicUrl
      logoFile.value = null
    }

    await client.from('outlets').update({
      name: storeInfo.value.name,
      address: storeInfo.value.address,
      city: storeInfo.value.city,
      phone: storeInfo.value.phone,
      store_type: storeInfo.value.store_type,
      currency: operations.value.currency,
      timezone: operations.value.timezone,
      sst: operations.value.sst,
      service_charge: operations.value.serviceCharge,
      tax_id: storeInfo.value.tax_id,
      logo_url: finalLogoUrl,
      receipt_header: receipts.value.header,
      receipt_footer: receipts.value.footer
    }).eq('id', outletId.value)

    saveSuccess.value = true
    setTimeout(() => { saveSuccess.value = false }, 3000)
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <div>
    <div v-if="loading" class="flex items-center justify-center py-20">
      <UIcon name="i-lucide-loader-2" class="w-8 h-8 text-gray-400 animate-spin" />
    </div>

    <div v-else class="max-w-5xl mx-auto space-y-8">
      <!-- Page Header -->
      <div class="flex items-center justify-between">
        <div>
          <h1 class="text-2xl font-bold text-gray-900">Settings</h1>
          <p class="text-sm text-gray-500 mt-1">Manage your store configuration</p>
        </div>
        <UButton
          color="primary"
          :label="saveSuccess ? '✓ Saved!' : 'Save Changes'"
          icon="i-lucide-save"
          size="lg"
          class="font-semibold px-6"
          :loading="saving"
          :disabled="saveSuccess"
          @click="saveSettings"
        />
      </div>

      <!-- Success -->
      <Transition name="fade">
        <div v-if="saveSuccess" class="p-4 rounded-xl bg-emerald-50 border border-emerald-200 text-emerald-700 text-sm flex items-center gap-2">
          <UIcon name="i-lucide-check-circle" class="w-5 h-5" />
          Settings saved successfully!
        </div>
      </Transition>

      <!-- Store Profile Section -->
      <div class="bg-white rounded-2xl border border-gray-200 p-6">
        <h2 class="text-lg font-bold text-gray-900 mb-1">Store Profile</h2>
        <p class="text-sm text-gray-500 mb-6">Manage your basic store information and branding.</p>

        <!-- Logo -->
        <div class="flex items-center gap-6 mb-6 pb-6 border-b border-gray-100">
          <div class="w-20 h-20 rounded-2xl bg-gray-100 border-2 border-dashed border-gray-300 flex items-center justify-center overflow-hidden">
            <img v-if="logoUrl" :src="logoUrl" class="w-full h-full object-cover" />
            <UIcon v-else name="i-lucide-image" class="w-8 h-8 text-gray-400" />
          </div>
          <div>
            <p class="text-sm font-medium text-gray-900">Store Logo</p>
            <p class="text-xs text-gray-500 mb-2">Recommended size: 512×512px. JPG, PNG supported.</p>
            <label class="text-sm font-semibold text-[#162456] cursor-pointer hover:underline">
              Upload New Logo
              <input type="file" accept="image/*" class="hidden" @change="handleLogoUpload" />
            </label>
          </div>
        </div>

        <div class="grid grid-cols-2 gap-6">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1.5">Store Name</label>
            <input v-model="storeInfo.name" class="w-full h-11 px-4 rounded-xl border border-gray-300 text-sm focus:border-[#162456] focus:ring-1 focus:ring-[#162456] outline-none" />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1.5">Tax ID / SST Registration No.</label>
            <input v-model="storeInfo.tax_id" placeholder="W10-1860-32000000" class="w-full h-11 px-4 rounded-xl border border-gray-300 text-sm focus:border-[#162456] focus:ring-1 focus:ring-[#162456] outline-none" />
          </div>
          <div class="col-span-2">
            <label class="block text-sm font-medium text-gray-700 mb-1.5">Address</label>
            <input v-model="storeInfo.address" class="w-full h-11 px-4 rounded-xl border border-gray-300 text-sm focus:border-[#162456] focus:ring-1 focus:ring-[#162456] outline-none" />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1.5">Contact Number</label>
            <input v-model="storeInfo.phone" class="w-full h-11 px-4 rounded-xl border border-gray-300 text-sm focus:border-[#162456] focus:ring-1 focus:ring-[#162456] outline-none" />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1.5">Email Address</label>
            <input v-model="storeInfo.email" readonly class="w-full h-11 px-4 rounded-xl border border-gray-200 bg-gray-50 text-sm text-gray-500" />
          </div>
        </div>
      </div>

      <!-- Operational Settings -->
      <div class="bg-white rounded-2xl border border-gray-200 p-6">
        <h2 class="text-lg font-bold text-gray-900 mb-1">Operational Settings</h2>
        <p class="text-sm text-gray-500 mb-6">Configure currency, taxes, and service charges.</p>

        <div class="grid grid-cols-2 gap-6 mb-6">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1.5">Default Currency</label>
            <select v-model="operations.currency" class="w-full h-11 px-4 rounded-xl border border-gray-300 text-sm bg-white focus:border-[#162456] focus:ring-1 focus:ring-[#162456] outline-none">
              <option v-for="opt in currencyOptions" :key="opt.value" :value="opt.value">{{ opt.label }}</option>
            </select>
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1.5">Time Zone</label>
            <select v-model="operations.timezone" class="w-full h-11 px-4 rounded-xl border border-gray-300 text-sm bg-white focus:border-[#162456] focus:ring-1 focus:ring-[#162456] outline-none">
              <option v-for="opt in timezoneOptions" :key="opt.value" :value="opt.value">{{ opt.label }}</option>
            </select>
          </div>
        </div>

        <h3 class="text-sm font-semibold text-gray-900 mb-4">Taxes & Fees</h3>
        <div class="space-y-3">
          <div class="flex items-center justify-between p-4 rounded-xl bg-gray-50 border border-gray-200">
            <div class="flex items-center gap-3">
              <div class="w-3 h-3 rounded-full bg-[#162456]" />
              <div>
                <p class="text-sm font-medium text-gray-900">SST (Sales and Service Tax)</p>
                <p class="text-xs text-gray-500">Applied to all transactions</p>
              </div>
            </div>
            <div class="flex items-center gap-2">
              <input v-model.number="operations.sst" type="number" min="0" max="100" class="w-16 h-9 text-center rounded-lg border border-gray-300 text-sm focus:border-[#162456] outline-none" />
              <span class="text-sm text-gray-500 font-medium">%</span>
            </div>
          </div>
          <div class="flex items-center justify-between p-4 rounded-xl bg-gray-50 border border-gray-200">
            <div class="flex items-center gap-3">
              <div class="w-3 h-3 rounded-full bg-[#162456]" />
              <div>
                <p class="text-sm font-medium text-gray-900">Service Charge</p>
                <p class="text-xs text-gray-500">Applied to dine-in orders only</p>
              </div>
            </div>
            <div class="flex items-center gap-2">
              <input v-model.number="operations.serviceCharge" type="number" min="0" max="100" class="w-16 h-9 text-center rounded-lg border border-gray-300 text-sm focus:border-[#162456] outline-none" />
              <span class="text-sm text-gray-500 font-medium">%</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Receipt Customization -->
      <div class="bg-white rounded-2xl border border-gray-200 p-6">
        <h2 class="text-lg font-bold text-gray-900 mb-1">Receipt Customization</h2>
        <p class="text-sm text-gray-500 mb-6">Customize how your printed receipts look.</p>

        <div class="grid grid-cols-2 gap-8">
          <!-- Left: Form -->
          <div class="space-y-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1.5">Header Text</label>
              <input v-model="receipts.header" class="w-full h-11 px-4 rounded-xl border border-gray-300 text-sm focus:border-[#162456] focus:ring-1 focus:ring-[#162456] outline-none" />
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1.5">Footer Text</label>
              <input v-model="receipts.footer" class="w-full h-11 px-4 rounded-xl border border-gray-300 text-sm focus:border-[#162456] focus:ring-1 focus:ring-[#162456] outline-none" />
            </div>
            <div class="flex items-center justify-between py-2">
              <span class="text-sm text-gray-700">Show Logo on Receipt</span>
              <button
                :class="['relative w-12 h-6 rounded-full transition-colors', receipts.showLogo ? 'bg-[#162456]' : 'bg-gray-300']"
                @click="receipts.showLogo = !receipts.showLogo"
              >
                <span :class="['absolute top-0.5 left-0.5 w-5 h-5 bg-white rounded-full shadow transition-transform', receipts.showLogo ? 'translate-x-6' : '']" />
              </button>
            </div>
            <div class="flex items-center justify-between py-2">
              <span class="text-sm text-gray-700">Show Social Media Links</span>
              <button
                :class="['relative w-12 h-6 rounded-full transition-colors', receipts.showSocial ? 'bg-[#162456]' : 'bg-gray-300']"
                @click="receipts.showSocial = !receipts.showSocial"
              >
                <span :class="['absolute top-0.5 left-0.5 w-5 h-5 bg-white rounded-full shadow transition-transform', receipts.showSocial ? 'translate-x-6' : '']" />
              </button>
            </div>
          </div>

          <!-- Right: Receipt Preview -->
          <div class="flex justify-center">
            <div class="w-56 bg-white border-2 border-gray-200 rounded-xl p-4 shadow-sm text-center">
              <div v-if="receipts.showLogo" class="w-10 h-10 rounded-full bg-gray-100 mx-auto mb-2 overflow-hidden">
                <img v-if="logoUrl" :src="logoUrl" class="w-full h-full object-cover" />
              </div>
              <p class="font-bold text-xs text-gray-900 uppercase">{{ storeInfo.name || 'STORE NAME' }}</p>
              <p class="text-[10px] text-gray-400 mt-0.5">{{ storeInfo.address || 'Store Address' }}</p>
              <div class="border-t border-dashed border-gray-300 my-3" />
              <div class="flex justify-between text-[10px] text-gray-600 mb-1">
                <span>Latte</span><span>3.50</span>
              </div>
              <div class="flex justify-between text-[10px] text-gray-600 mb-1">
                <span>Croissant</span><span>4.50</span>
              </div>
              <div class="border-t border-dashed border-gray-300 my-2" />
              <div class="flex justify-between text-[10px] font-bold text-gray-900">
                <span>TOTAL</span><span>8.00</span>
              </div>
              <div class="border-t border-dashed border-gray-300 my-2" />
              <p class="text-[10px] text-gray-400 italic">{{ receipts.footer }}</p>
              <p v-if="receipts.showSocial" class="text-[9px] text-blue-500 mt-1 underline">View Reviews</p>
            </div>
          </div>
        </div>
      </div>

      <!-- Security & Roles -->
      <div class="bg-white rounded-2xl border border-gray-200 p-6">
        <h2 class="text-lg font-bold text-gray-900 mb-1">Security & Roles</h2>
        <p class="text-sm text-gray-500 mb-6">Manage access permissions for different employee roles.</p>

        <table class="w-full text-sm">
          <thead>
            <tr class="text-xs text-gray-500 uppercase tracking-wider border-b border-gray-200">
              <th class="text-left py-3 font-medium">Role</th>
              <th class="text-center py-3 font-medium">POS Access</th>
              <th class="text-center py-3 font-medium">Refunds</th>
              <th class="text-center py-3 font-medium">Reports</th>
              <th class="text-center py-3 font-medium">Settings</th>
              <th class="text-right py-3 font-medium">Action</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="role in roles" :key="role.name" class="border-b border-gray-100">
              <td class="py-3 font-medium text-gray-900">{{ role.name }}</td>
              <td class="text-center py-3">
                <UIcon :name="role.pos ? 'i-lucide-check-circle' : 'i-lucide-circle'" :class="role.pos ? 'text-[#162456]' : 'text-gray-300'" class="w-5 h-5" />
              </td>
              <td class="text-center py-3">
                <UIcon :name="role.refunds ? 'i-lucide-check-circle' : 'i-lucide-circle'" :class="role.refunds ? 'text-[#162456]' : 'text-gray-300'" class="w-5 h-5" />
              </td>
              <td class="text-center py-3">
                <UIcon :name="role.reports ? 'i-lucide-check-circle' : 'i-lucide-circle'" :class="role.reports ? 'text-[#162456]' : 'text-gray-300'" class="w-5 h-5" />
              </td>
              <td class="text-center py-3">
                <UIcon :name="role.settings ? 'i-lucide-check-circle' : 'i-lucide-circle'" :class="role.settings ? 'text-[#162456]' : 'text-gray-300'" class="w-5 h-5" />
              </td>
              <td class="text-right py-3">
                <button class="text-sm font-medium text-[#162456] hover:underline">Edit</button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Hardware & Integrations -->
      <div class="bg-white rounded-2xl border border-gray-200 p-6 mb-8">
        <h2 class="text-lg font-bold text-gray-900 mb-1">Hardware & Integrations</h2>
        <p class="text-sm text-gray-500 mb-6">Connect your printers, payment terminals, and delivery platforms.</p>

        <div class="grid grid-cols-3 gap-4">
          <div v-for="item in integrations" :key="item.name" class="border border-gray-200 rounded-xl p-5 text-center">
            <div class="flex justify-center mb-3">
              <div class="w-12 h-12 rounded-xl bg-gray-100 flex items-center justify-center">
                <UIcon :name="item.icon" class="w-6 h-6 text-gray-600" />
              </div>
            </div>
            <span
              :class="[
                'inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium mb-2',
                item.status === 'connected' ? 'bg-emerald-100 text-emerald-700' : 'bg-gray-100 text-gray-500'
              ]"
            >
              {{ item.status === 'connected' ? 'Connected' : 'Disconnected' }}
            </span>
            <p class="font-semibold text-sm text-gray-900">{{ item.name }}</p>
            <p class="text-xs text-gray-500 mt-0.5">{{ item.subtitle }}</p>
            <button
              class="mt-3 w-full py-2 rounded-lg text-xs font-medium border transition-colors"
              :class="item.status === 'connected' ? 'border-gray-200 text-gray-600 hover:bg-gray-50' : 'border-[#162456] text-[#162456] hover:bg-[#162456]/5'"
            >
              {{ item.status === 'connected' ? 'Configure' : 'Connect' }}
            </button>
          </div>
        </div>
      </div>
    </div>

    <FloatingTips :tips="tips" />
  </div>
</template>

<style scoped>
.fade-enter-active, .fade-leave-active { transition: opacity 0.3s; }
.fade-enter-from, .fade-leave-to { opacity: 0; }
</style>
