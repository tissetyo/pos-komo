<script setup lang="ts">
definePageMeta({ layout: 'backoffice' })

const { client, outletId, profileReady } = useUserProfile()
const loading = ref(true)
const saving = ref(false)
const showSaved = ref(false)

// Tax & Fees
const taxConfig = ref({
  sst: '',
  serviceCharge: '',
  rounding: 'none' as 'none' | 'nearest-5' | 'nearest-10'
})

// Payment Methods
const paymentMethods = ref({
  cash: true,
  qris: false,
  debit: false,
  credit: false
})

// Third-party Integrations
const integrations = ref([
  {
    id: 'stripe',
    name: 'Stripe',
    description: 'Accept credit & debit card payments online',
    icon: 'i-lucide-credit-card',
    color: '#635BFF',
    connected: false,
    apiKey: ''
  },
  {
    id: 'gobiz',
    name: 'GoBiz / GoPay',
    description: 'Accept GoPay and QRIS payments',
    icon: 'i-lucide-smartphone',
    color: '#00AED6',
    connected: false,
    apiKey: ''
  },
  {
    id: 'grabpay',
    name: 'GrabPay',
    description: 'Accept GrabPay wallet and GrabFood orders',
    icon: 'i-lucide-wallet',
    color: '#00B14F',
    connected: false,
    apiKey: ''
  },
  {
    id: 'ipay88',
    name: 'iPay88',
    description: 'Malaysian payment gateway — FPX, VISA, Mastercard',
    icon: 'i-lucide-landmark',
    color: '#E31937',
    connected: false,
    apiKey: ''
  },
  {
    id: 'billplz',
    name: 'Billplz',
    description: 'Malaysian FPX and direct debit payments',
    icon: 'i-lucide-receipt',
    color: '#FF6600',
    connected: false,
    apiKey: ''
  },
  {
    id: 'senangpay',
    name: 'SenangPay',
    description: 'Online banking, e-wallets, and card payments (MY)',
    icon: 'i-lucide-banknote',
    color: '#2563EB',
    connected: false,
    apiKey: ''
  }
])

const expandedIntegration = ref<string | null>(null)

const toggleExpand = (id: string) => {
  expandedIntegration.value = expandedIntegration.value === id ? null : id
}

const loadSettings = async () => {
  if (!outletId.value) return
  loading.value = true
  const { data } = await client
    .from('outlets')
    .select('sst, service_charge, rounding, payment_methods, integrations')
    .eq('id', outletId.value)
    .single()

  if (data) {
    taxConfig.value.sst = String(data.sst || '')
    taxConfig.value.serviceCharge = String(data.service_charge || '')
    taxConfig.value.rounding = data.rounding || 'none'

    if (data.payment_methods) {
      paymentMethods.value = { ...paymentMethods.value, ...data.payment_methods }
    }
    if (data.integrations) {
      // Merge saved integration state
      const saved = data.integrations as Record<string, any>
      integrations.value.forEach(i => {
        if (saved[i.id]) {
          i.connected = saved[i.id].connected || false
          i.apiKey = saved[i.id].apiKey || ''
        }
      })
    }
  }
  loading.value = false
}

watch(profileReady, (ready) => { if (ready) loadSettings() }, { immediate: true })

const saveSettings = async () => {
  if (!outletId.value) return
  saving.value = true

  const integrationsMap: Record<string, any> = {}
  integrations.value.forEach(i => {
    integrationsMap[i.id] = { connected: i.connected, apiKey: i.apiKey }
  })

  await client.from('outlets').update({
    sst: parseFloat(taxConfig.value.sst) || 0,
    service_charge: parseFloat(taxConfig.value.serviceCharge) || 0,
    rounding: taxConfig.value.rounding,
    payment_methods: paymentMethods.value,
    integrations: integrationsMap
  }).eq('id', outletId.value)

  saving.value = false
  showSaved.value = true
  setTimeout(() => { showSaved.value = false }, 3000)
}

const connectIntegration = (integration: any) => {
  integration.connected = !integration.connected
}

const testingConnection = ref<string | null>(null)
const toast = useToast()

const testConnection = async (integration: any) => {
  if (!integration.apiKey) {
    toast.add({ title: 'Missing API Key', description: 'Please enter an API key first.', color: 'error' })
    return
  }

  testingConnection.value = integration.id
  try {
    const res = await $fetch('/api/payment/test', {
      method: 'POST',
      body: { provider: integration.id, apiKey: integration.apiKey }
    })
    
    toast.add({
      title: 'Success!',
      description: (res as any).message,
      color: 'success',
      icon: 'i-lucide-check-circle'
    })
  } catch (err: any) {
    toast.add({
      title: 'Connection Failed',
      description: err.data?.message || err.message,
      color: 'error',
      icon: 'i-lucide-alert-circle'
    })
  } finally {
    testingConnection.value = null
  }
}
</script>

<template>
  <div>
    <div v-if="loading" class="flex items-center justify-center py-20">
      <UIcon name="i-lucide-loader-2" class="w-8 h-8 text-gray-400 animate-spin" />
    </div>

    <div v-else class="max-w-5xl mx-auto space-y-8">
      <!-- Header -->
      <div class="flex items-center justify-between">
        <div>
          <h1 class="text-2xl font-bold text-gray-900">Payments & Tax</h1>
          <p class="text-sm text-gray-500 mt-1">Configure tax rates, payment methods, and third-party integrations.</p>
        </div>
        <UButton color="primary" label="Save Changes" icon="i-lucide-check" :loading="saving" @click="saveSettings" />
      </div>

      <!-- Saved Toast -->
      <Transition name="fade">
        <div v-if="showSaved" class="bg-green-50 border border-green-200 rounded-xl p-4 flex items-center gap-3 text-green-700 text-sm font-medium">
          <UIcon name="i-lucide-check-circle" class="w-5 h-5" />
          Settings saved successfully!
        </div>
      </Transition>

      <!-- Tax & Fees -->
      <div class="bg-white rounded-2xl border border-gray-200 p-6">
        <h2 class="text-lg font-bold text-gray-900 mb-1">Tax & Fees</h2>
        <p class="text-sm text-gray-500 mb-6">Set tax rates and service charges that auto-apply to all orders.</p>

        <div class="space-y-4">
          <div class="flex items-center justify-between p-4 rounded-xl bg-gray-50 border border-gray-200">
            <div class="flex items-center gap-3">
              <div class="w-10 h-10 bg-blue-100 rounded-xl flex items-center justify-center">
                <UIcon name="i-lucide-percent" class="w-5 h-5 text-blue-600" />
              </div>
              <div>
                <p class="font-medium text-gray-900">SST / Sales Tax</p>
                <p class="text-xs text-gray-500">Applied to all orders. Set 0 to disable.</p>
              </div>
            </div>
            <div class="flex items-center gap-2">
              <input v-model="taxConfig.sst" type="number" step="0.1" class="w-20 h-10 text-center rounded-lg border border-gray-300 text-sm font-medium focus:ring-2 focus:ring-primary outline-none" />
              <span class="text-sm text-gray-500 font-medium">%</span>
            </div>
          </div>

          <div class="flex items-center justify-between p-4 rounded-xl bg-gray-50 border border-gray-200">
            <div class="flex items-center gap-3">
              <div class="w-10 h-10 bg-emerald-100 rounded-xl flex items-center justify-center">
                <UIcon name="i-lucide-hand-coins" class="w-5 h-5 text-emerald-600" />
              </div>
              <div>
                <p class="font-medium text-gray-900">Service Charge</p>
                <p class="text-xs text-gray-500">Optional service fee added to orders.</p>
              </div>
            </div>
            <div class="flex items-center gap-2">
              <input v-model="taxConfig.serviceCharge" type="number" step="0.1" class="w-20 h-10 text-center rounded-lg border border-gray-300 text-sm font-medium focus:ring-2 focus:ring-primary outline-none" />
              <span class="text-sm text-gray-500 font-medium">%</span>
            </div>
          </div>

          <div class="flex items-center justify-between p-4 rounded-xl bg-gray-50 border border-gray-200">
            <div class="flex items-center gap-3">
              <div class="w-10 h-10 bg-amber-100 rounded-xl flex items-center justify-center">
                <UIcon name="i-lucide-coins" class="w-5 h-5 text-amber-600" />
              </div>
              <div>
                <p class="font-medium text-gray-900">Rounding</p>
                <p class="text-xs text-gray-500">How to round totals for cash payments.</p>
              </div>
            </div>
            <select v-model="taxConfig.rounding" class="h-10 px-4 rounded-lg border border-gray-300 bg-white text-sm focus:ring-2 focus:ring-primary outline-none">
              <option value="none">No Rounding</option>
              <option value="nearest-5">Nearest 0.05</option>
              <option value="nearest-10">Nearest 0.10</option>
            </select>
          </div>
        </div>
      </div>

      <!-- Payment Methods -->
      <div class="bg-white rounded-2xl border border-gray-200 p-6">
        <h2 class="text-lg font-bold text-gray-900 mb-1">Payment Methods</h2>
        <p class="text-sm text-gray-500 mb-6">Enable or disable payment options on the cashier.</p>

        <div class="grid grid-cols-2 gap-4">
          <div
            v-for="(enabled, method) in paymentMethods"
            :key="method"
            :class="['flex items-center justify-between p-4 rounded-xl border transition-all cursor-pointer',
              enabled ? 'bg-blue-50 border-blue-200' : 'bg-gray-50 border-gray-200']"
            @click="paymentMethods[method] = !paymentMethods[method]"
          >
            <div class="flex items-center gap-3">
              <UIcon
                :name="method === 'cash' ? 'i-lucide-banknote' : method === 'qris' ? 'i-lucide-qr-code' : method === 'debit' ? 'i-lucide-credit-card' : 'i-lucide-credit-card'"
                :class="['w-5 h-5', enabled ? 'text-blue-600' : 'text-gray-400']"
              />
              <span :class="['font-medium capitalize text-sm', enabled ? 'text-gray-900' : 'text-gray-500']">
                {{ method === 'qris' ? 'QRIS' : method }}
              </span>
            </div>
            <div :class="['relative inline-flex h-6 w-11 items-center rounded-full transition-colors',
              enabled ? 'bg-blue-500' : 'bg-gray-300']">
              <span :class="['inline-block h-4 w-4 transform rounded-full bg-white transition-transform shadow',
                enabled ? 'translate-x-6' : 'translate-x-1']" />
            </div>
          </div>
        </div>
      </div>

      <!-- Third-party Integrations -->
      <div class="bg-white rounded-2xl border border-gray-200 p-6">
        <h2 class="text-lg font-bold text-gray-900 mb-1">Third-party Integrations</h2>
        <p class="text-sm text-gray-500 mb-6">Connect external payment gateways and services.</p>

        <div class="space-y-3">
          <div
            v-for="integration in integrations"
            :key="integration.id"
            class="border border-gray-200 rounded-xl overflow-hidden"
          >
            <div class="flex items-center justify-between p-4 cursor-pointer hover:bg-gray-50 transition-colors" @click="toggleExpand(integration.id)">
              <div class="flex items-center gap-3">
                <div class="w-10 h-10 rounded-xl flex items-center justify-center" :style="{ background: integration.color + '15' }">
                  <UIcon :name="integration.icon" class="w-5 h-5" :style="{ color: integration.color }" />
                </div>
                <div>
                  <p class="font-medium text-gray-900">{{ integration.name }}</p>
                  <p class="text-xs text-gray-500">{{ integration.description }}</p>
                </div>
              </div>
              <div class="flex items-center gap-3">
                <span v-if="integration.connected" class="bg-green-100 text-green-700 text-xs font-medium px-3 py-1 rounded-full">Connected</span>
                <span v-else class="bg-gray-100 text-gray-500 text-xs font-medium px-3 py-1 rounded-full">Not Connected</span>
                <UIcon :name="expandedIntegration === integration.id ? 'i-lucide-chevron-up' : 'i-lucide-chevron-down'" class="w-4 h-4 text-gray-400" />
              </div>
            </div>

            <!-- Expanded Settings -->
            <Transition name="expand">
              <div v-if="expandedIntegration === integration.id" class="border-t border-gray-100 px-4 py-4 bg-gray-50 space-y-4">
                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-1.5">API Key / Secret Key</label>
                  <input
                    v-model="integration.apiKey"
                    type="password"
                    placeholder="Enter your API key"
                    class="w-full h-10 px-4 rounded-lg border border-gray-300 text-sm focus:ring-2 focus:ring-primary focus:border-primary outline-none"
                  />
                  <p class="text-xs text-gray-400 mt-1">You can find this in your {{ integration.name }} dashboard.</p>
                </div>
                <div class="flex gap-3">
                  <button
                    :class="['px-4 py-2 rounded-lg text-sm font-semibold transition-colors',
                      integration.connected
                        ? 'bg-red-100 text-red-600 hover:bg-red-200'
                        : 'text-white hover:opacity-90']"
                    :style="!integration.connected ? { background: integration.color } : {}"
                    @click="connectIntegration(integration)"
                  >
                    {{ integration.connected ? 'Disconnect' : 'Connect' }}
                  </button>
                  <button v-if="integration.connected" 
                    @click="testConnection(integration)"
                    :disabled="testingConnection === integration.id"
                    class="px-4 py-2 rounded-lg text-sm font-semibold bg-gray-200 text-gray-600 hover:bg-gray-300 disabled:opacity-50 flex items-center gap-2">
                    <UIcon v-if="testingConnection === integration.id" name="i-lucide-loader-2" class="w-4 h-4 animate-spin" />
                    {{ testingConnection === integration.id ? 'Testing...' : 'Test Connection' }}
                  </button>
                </div>
              </div>
            </Transition>
          </div>
        </div>
      </div>

      <!-- Info -->
      <div class="bg-blue-50 border border-blue-200 rounded-xl px-5 py-3 flex items-start gap-3 mb-8">
        <UIcon name="i-lucide-info" class="w-5 h-5 text-blue-500 mt-0.5 flex-shrink-0" />
        <p class="text-sm text-blue-700">
          <span class="font-medium text-blue-900">Note:</span> Third-party integrations store API keys securely. For production use, configure webhooks in each provider's dashboard.
        </p>
      </div>
    </div>
  </div>
</template>

<style scoped>
.fade-enter-active, .fade-leave-active { transition: opacity 0.3s ease; }
.fade-enter-from, .fade-leave-to { opacity: 0; }
.expand-enter-active, .expand-leave-active { transition: all 0.3s ease; overflow: hidden; }
.expand-enter-from, .expand-leave-to { max-height: 0; opacity: 0; padding-top: 0; padding-bottom: 0; }
</style>
