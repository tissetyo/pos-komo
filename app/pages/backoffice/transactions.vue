<script setup lang="ts">
definePageMeta({ layout: 'backoffice' })

const { client, outletId, profileReady } = useUserProfile()
const transactions = ref<any[]>([])
const loading = ref(true)
const search = ref('')
const activeTab = ref('All Transactions')

const tabs = ['All Transactions', 'Online Orders', 'Offline Orders', 'Void/Refunds']

const currentPage = ref(1)
const perPage = 10

// View order modal
const viewingOrder = ref<any>(null)
const orderItems = ref<any[]>([])
const loadingItems = ref(false)

const today = computed(() => {
  return new Date().toLocaleDateString('en-MY', { weekday: 'short', day: 'numeric', month: 'short', year: 'numeric' })
})

const fetchTransactions = async () => {
  loading.value = true
  try {
    if (!outletId.value) return

    const { data } = await client
      .from('orders')
      .select('*, customers(name), profiles!orders_cashier_id_fkey(full_name)')
      .eq('outlet_id', outletId.value)
      .order('created_at', { ascending: false })
      .limit(200)

    transactions.value = (data || []).map((tx: any) => ({
      id: tx.id,
      receiptNumber: tx.receipt_number || 'ORD-' + tx.id.substring(0, 8),
      date: new Date(tx.created_at).toLocaleDateString('en-MY', { day: 'numeric', month: 'short', year: 'numeric' }),
      time: new Date(tx.created_at).toLocaleTimeString('en-MY', { hour: '2-digit', minute: '2-digit' }),
      orderType: tx.order_type || 'dine-in',
      channel: tx.order_type === 'delivery' ? 'Online' : 'Offline',
      channelLabel: tx.order_type === 'dine-in' ? 'Dine-in' : tx.order_type === 'takeaway' ? 'Takeaway' : tx.order_type === 'delivery' ? 'Delivery' : tx.order_type || 'Dine-in',
      channelIcon: tx.order_type === 'delivery' ? 'i-lucide-smartphone' : 'i-lucide-monitor',
      customer: tx.customers?.name || 'Walk-in',
      cashier: tx.profiles?.full_name || 'Staff',
      status: tx.payment_status === 'paid' ? 'Paid' : tx.payment_status === 'refunded' ? 'Refunded' : tx.order_status === 'cancelled' ? 'Voided' : 'Pending',
      method: tx.payment_method || 'cash',
      methodLabel: (tx.payment_method || 'cash').charAt(0).toUpperCase() + (tx.payment_method || 'cash').slice(1),
      methodIcon: (tx.payment_method || 'cash') === 'cash' ? 'i-lucide-banknote' : (tx.payment_method || '') === 'qris' ? 'i-lucide-qr-code' : 'i-lucide-credit-card',
      total: tx.total || 0,
      subtotal: tx.subtotal || 0,
      tax: tx.tax || 0,
      discount: tx.discount || 0
    }))
  } finally {
    loading.value = false
  }
}

watch(profileReady, (ready) => { if (ready) fetchTransactions() })

const filteredTx = computed(() => {
  let filtered = transactions.value
  if (search.value) {
    const q = search.value.toLowerCase()
    filtered = filtered.filter(tx => tx.receiptNumber.toLowerCase().includes(q) || tx.customer.toLowerCase().includes(q))
  }
  if (activeTab.value === 'Online Orders') {
    filtered = filtered.filter(tx => tx.channel === 'Online')
  } else if (activeTab.value === 'Offline Orders') {
    filtered = filtered.filter(tx => tx.channel === 'Offline')
  } else if (activeTab.value === 'Void/Refunds') {
    filtered = filtered.filter(tx => tx.status === 'Voided' || tx.status === 'Refunded')
  }
  return filtered
})

const tabCounts = computed(() => ({
  'All Transactions': transactions.value.length,
  'Online Orders': transactions.value.filter(tx => tx.channel === 'Online').length,
  'Offline Orders': transactions.value.filter(tx => tx.channel === 'Offline').length,
  'Void/Refunds': transactions.value.filter(tx => tx.status === 'Voided' || tx.status === 'Refunded').length
}))

const paginatedTx = computed(() => {
  const start = (currentPage.value - 1) * perPage
  return filteredTx.value.slice(start, start + perPage)
})

const totalPages = computed(() => Math.ceil(filteredTx.value.length / perPage))

const viewOrder = async (tx: any) => {
  viewingOrder.value = tx
  loadingItems.value = true
  try {
    const { data } = await client
      .from('order_items')
      .select('*, products(name)')
      .eq('order_id', tx.id)
    orderItems.value = (data || []).map((i: any) => ({
      name: i.products?.name || 'Item',
      quantity: i.quantity,
      unitPrice: i.unit_price,
      totalPrice: i.total_price,
      variation: i.variation_snapshot
    }))
  } finally {
    loadingItems.value = false
  }
}

const formatRM = (amount: number) => 'RM ' + amount.toLocaleString('en-MY', { minimumFractionDigits: 2, maximumFractionDigits: 2 })

const exportCSV = () => {
  const headers = ['Date', 'Time', 'Receipt #', 'Channel', 'Customer', 'Method', 'Status', 'Total']
  const rows = filteredTx.value.map(tx => [tx.date, tx.time, tx.receiptNumber, tx.channelLabel, tx.customer, tx.methodLabel, tx.status, tx.total])
  const csv = [headers, ...rows].map(row => row.join(',')).join('\n')
  const blob = new Blob([csv], { type: 'text/csv' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `transactions_${new Date().toISOString().split('T')[0]}.csv`
  a.click()
}
</script>

<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex justify-between items-start">
      <div>
        <h2 class="text-2xl font-bold text-gray-900">Transactions</h2>
        <p class="text-gray-500 text-sm mt-1">Manage and view all your order history</p>
      </div>
      <div class="flex items-center gap-3">
        <span class="bg-emerald-50 text-emerald-700 text-sm font-semibold px-4 py-2 rounded-full border border-emerald-200">
          Total: {{ filteredTx.length.toLocaleString() }} Orders
        </span>
        <UButton color="primary" label="Export CSV" icon="i-lucide-download" @click="exportCSV" />
      </div>
    </div>

    <!-- Pro Tip -->
    <div class="bg-blue-50 border border-blue-200 rounded-xl px-5 py-3 flex items-start gap-3">
      <UIcon name="i-lucide-lightbulb" class="w-5 h-5 text-blue-500 mt-0.5 flex-shrink-0" />
      <p class="text-sm text-blue-700">
        <span class="font-medium text-blue-900">Pro Tip:</span> Click Export CSV to download filtered transactions for your records. Use Search to find specific orders by receipt number.
      </p>
    </div>

    <!-- Tabs -->
    <div class="border-b border-gray-200">
      <div class="flex gap-6">
        <button
          v-for="tab in tabs"
          :key="tab"
          @click="activeTab = tab; currentPage = 1"
          :class="[
            'pb-3 text-sm font-medium transition-colors border-b-2 flex items-center gap-2',
            activeTab === tab
              ? 'border-[#1E293B] text-gray-900'
              : 'border-transparent text-gray-500 hover:text-gray-700'
          ]"
        >
          <UIcon v-if="tab === 'All Transactions'" name="i-lucide-list" class="w-4 h-4" />
          <UIcon v-if="tab === 'Online Orders'" name="i-lucide-smartphone" class="w-4 h-4" />
          <UIcon v-if="tab === 'Offline Orders'" name="i-lucide-monitor" class="w-4 h-4" />
          <UIcon v-if="tab === 'Void/Refunds'" name="i-lucide-rotate-ccw" class="w-4 h-4" />
          {{ tab }}
          <span v-if="(tabCounts as any)[tab] > 0" class="bg-gray-100 text-gray-700 text-xs font-semibold px-2 py-0.5 rounded-full">{{ (tabCounts as any)[tab] }}</span>
        </button>
      </div>
    </div>

    <!-- Filters -->
    <div class="flex items-center gap-4">
      <UInput v-model="search" icon="i-lucide-search" placeholder="Search receipt #, customer..." class="w-96" @input="currentPage = 1" />
      <div class="flex items-center gap-2 text-sm text-gray-500 bg-white border border-gray-200 px-4 py-2 rounded-lg">
        <UIcon name="i-lucide-calendar" class="w-4 h-4" />
        {{ today }}
      </div>
    </div>

    <!-- Empty State -->
    <div v-if="!loading && filteredTx.length === 0" class="bg-white rounded-xl border border-gray-100 p-16 text-center">
      <UIcon name="i-lucide-receipt" class="w-12 h-12 mx-auto mb-4 text-gray-300" />
      <h3 class="text-lg font-semibold text-gray-900 mb-2">No transactions found</h3>
      <p class="text-gray-500 text-sm">Completed orders from the POS will appear here.</p>
    </div>

    <!-- Table -->
    <div v-else-if="!loading" class="bg-white rounded-xl border border-gray-100 overflow-hidden shadow-sm">
      <table class="w-full text-sm">
        <thead>
          <tr class="border-b border-gray-100">
            <th class="text-left py-4 px-5 text-xs font-medium text-gray-500 uppercase tracking-wider">Date & Time</th>
            <th class="text-left py-4 px-5 text-xs font-medium text-gray-500 uppercase tracking-wider">Receipt #</th>
            <th class="text-left py-4 px-5 text-xs font-medium text-gray-500 uppercase tracking-wider">Channel</th>
            <th class="text-left py-4 px-5 text-xs font-medium text-gray-500 uppercase tracking-wider">Customer</th>
            <th class="text-left py-4 px-5 text-xs font-medium text-gray-500 uppercase tracking-wider">Total</th>
            <th class="text-left py-4 px-5 text-xs font-medium text-gray-500 uppercase tracking-wider">Payment</th>
            <th class="text-left py-4 px-5 text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
            <th class="text-left py-4 px-5 text-xs font-medium text-gray-500 uppercase tracking-wider">Action</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-gray-50">
          <tr v-for="tx in paginatedTx" :key="tx.id" class="hover:bg-gray-50 transition-colors">
            <td class="py-4 px-5">
              <p class="font-medium text-gray-900">{{ tx.date }}</p>
              <p class="text-xs text-gray-500">{{ tx.time }}</p>
            </td>
            <td class="py-4 px-5 font-semibold text-primary">{{ tx.receiptNumber }}</td>
            <td class="py-4 px-5">
              <div class="flex items-center gap-2 text-gray-600">
                <UIcon :name="tx.channelIcon" class="w-4 h-4 text-gray-400" />
                {{ tx.channelLabel }}
              </div>
            </td>
            <td class="py-4 px-5">
              <p class="font-medium text-gray-900">{{ tx.customer }}</p>
              <p class="text-xs text-gray-500">by {{ tx.cashier }}</p>
            </td>
            <td class="py-4 px-5 font-bold text-gray-900">{{ formatRM(tx.total) }}</td>
            <td class="py-4 px-5">
              <div class="flex items-center gap-2 text-gray-600">
                <UIcon :name="tx.methodIcon" class="w-4 h-4 text-gray-400" />
                {{ tx.methodLabel }}
              </div>
            </td>
            <td class="py-4 px-5">
              <span
                :class="[
                  'px-3 py-1 rounded-full text-xs font-semibold',
                  tx.status === 'Paid' ? 'bg-green-50 text-green-700' :
                  tx.status === 'Voided' || tx.status === 'Refunded' ? 'bg-red-50 text-red-600' :
                  'bg-yellow-50 text-yellow-700'
                ]"
              >
                {{ tx.status }}
              </span>
            </td>
            <td class="py-4 px-5">
              <UButton icon="i-lucide-eye" color="neutral" variant="ghost" size="xs" @click="viewOrder(tx)" />
            </td>
          </tr>
        </tbody>
      </table>

      <!-- Pagination -->
      <div v-if="totalPages > 1" class="flex items-center justify-between px-6 py-4 border-t border-gray-100">
        <p class="text-sm text-gray-500">
          Showing {{ ((currentPage - 1) * perPage) + 1 }} to {{ Math.min(currentPage * perPage, filteredTx.length) }} of {{ filteredTx.length }} results
        </p>
        <div class="flex items-center gap-1">
          <button @click="currentPage = Math.max(1, currentPage - 1)" :disabled="currentPage === 1"
            class="px-3 py-1.5 text-sm rounded-lg border border-gray-200 text-gray-600 hover:bg-gray-50 disabled:opacity-40">
            <UIcon name="i-lucide-chevron-left" class="w-4 h-4" />
          </button>
          <button v-for="page in Math.min(totalPages, 5)" :key="page" @click="currentPage = page"
            :class="['w-9 h-9 text-sm rounded-lg transition-colors', currentPage === page ? 'bg-[#1E293B] text-white' : 'text-gray-600 hover:bg-gray-100']">
            {{ page }}
          </button>
          <button @click="currentPage = Math.min(totalPages, currentPage + 1)" :disabled="currentPage >= totalPages"
            class="px-3 py-1.5 text-sm rounded-lg border border-gray-200 text-gray-600 hover:bg-gray-50 disabled:opacity-40">
            <UIcon name="i-lucide-chevron-right" class="w-4 h-4" />
          </button>
        </div>
      </div>
    </div>

    <!-- View Order Modal -->
    <UModal v-model:open="viewingOrder" v-if="viewingOrder">
      <template #content>
        <div class="p-6 bg-white max-w-lg mx-auto">
          <div class="flex justify-between items-start mb-6">
            <div>
              <h3 class="text-lg font-bold text-gray-900">Order {{ viewingOrder.receiptNumber }}</h3>
              <p class="text-sm text-gray-500">{{ viewingOrder.date }} at {{ viewingOrder.time }}</p>
            </div>
            <span :class="[
              'px-3 py-1 rounded-full text-xs font-semibold',
              viewingOrder.status === 'Paid' ? 'bg-green-50 text-green-700' : 'bg-red-50 text-red-600'
            ]">
              {{ viewingOrder.status }}
            </span>
          </div>

          <div class="space-y-3 mb-6">
            <div class="flex justify-between text-sm">
              <span class="text-gray-500">Customer</span>
              <span class="font-medium text-gray-900">{{ viewingOrder.customer }}</span>
            </div>
            <div class="flex justify-between text-sm">
              <span class="text-gray-500">Channel</span>
              <span class="font-medium text-gray-900">{{ viewingOrder.channelLabel }}</span>
            </div>
            <div class="flex justify-between text-sm">
              <span class="text-gray-500">Payment</span>
              <span class="font-medium text-gray-900">{{ viewingOrder.methodLabel }}</span>
            </div>
          </div>

          <div class="border-t border-gray-100 pt-4">
            <h4 class="font-semibold text-gray-900 mb-3">Items</h4>
            <div v-if="loadingItems" class="text-center py-4 text-gray-400">
              <UIcon name="i-lucide-loader-2" class="w-5 h-5 animate-spin" />
            </div>
            <div v-else class="space-y-2">
              <div v-for="item in orderItems" :key="item.name" class="flex justify-between text-sm">
                <span class="text-gray-600">{{ item.name }} × {{ item.quantity }}</span>
                <span class="font-medium text-gray-900">{{ formatRM(item.totalPrice) }}</span>
              </div>
            </div>
          </div>

          <div class="border-t border-dashed border-gray-200 mt-4 pt-4 space-y-2">
            <div class="flex justify-between text-sm">
              <span class="text-gray-500">Subtotal</span>
              <span class="text-gray-900">{{ formatRM(viewingOrder.subtotal) }}</span>
            </div>
            <div class="flex justify-between text-sm">
              <span class="text-gray-500">Tax</span>
              <span class="text-gray-900">{{ formatRM(viewingOrder.tax) }}</span>
            </div>
            <div v-if="viewingOrder.discount > 0" class="flex justify-between text-sm">
              <span class="text-gray-500">Discount</span>
              <span class="text-red-500">-{{ formatRM(viewingOrder.discount) }}</span>
            </div>
            <div class="flex justify-between text-lg font-bold pt-2 border-t border-gray-200">
              <span>Total</span>
              <span>{{ formatRM(viewingOrder.total) }}</span>
            </div>
          </div>

          <div class="flex justify-end mt-6">
            <UButton color="neutral" variant="ghost" label="Close" @click="viewingOrder = null" />
          </div>
        </div>
      </template>
    </UModal>
  </div>
</template>
