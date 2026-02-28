<script setup lang="ts">
definePageMeta({ layout: 'backoffice' })

const client = useSupabaseClient()
const user = useSupabaseUser()
const transactions = ref<any[]>([])
const loading = ref(true)
const search = ref('')
const activeTab = ref('All Transactions')

const tabs = ['All Transactions', 'Online Orders', 'Offline Orders', 'Void/Refunds']

const columns = [
  { id: 'dateTime', key: 'dateTime', label: 'Date & Time' },
  { id: 'orderId', key: 'orderId', label: 'Order ID' },
  { id: 'channel', key: 'channel', label: 'Channel' },
  { id: 'tableCustomer', key: 'tableCustomer', label: 'Table/Customer' },
  { id: 'total', key: 'total', label: 'Total' },
  { id: 'payment', key: 'payment', label: 'Payment' },
  { id: 'status', key: 'status', label: 'Status' },
  { id: 'actions', key: 'actions', label: 'Action' }
]

const currentPage = ref(1)
const perPage = 10

onMounted(async () => {
  if (!user.value) return
  try {
    const { data: profile } = await client.from('profiles').select('outlet_id').eq('id', user.value.id).single()
    if (!profile?.outlet_id) return

    const { data } = await client
      .from('orders')
      .select('*, outlets(name), profiles!orders_cashier_id_fkey(full_name)')
      .eq('outlet_id', profile.outlet_id)
      .order('created_at', { ascending: false })
      .limit(50)

    transactions.value = (data || []).map((tx: any) => ({
      orderId: '#' + (tx.receipt_number || 'ORD-' + tx.id.substring(0, 8)),
      date: new Date(tx.created_at).toLocaleDateString('en-MY', { day: 'numeric', month: 'short', year: 'numeric' }),
      time: new Date(tx.created_at).toLocaleTimeString('en-MY', { hour: '2-digit', minute: '2-digit' }),
      channel: tx.order_type === 'dine-in' ? 'Counter' : 'Mobile QR',
      channelIcon: tx.order_type === 'dine-in' ? 'i-lucide-monitor' : 'i-lucide-smartphone',
      table: tx.order_type === 'dine-in' ? 'Table ' + (Math.floor(Math.random() * 12) + 1) : 'Takeaway',
      customer: tx.profiles?.full_name || 'Walk-in',
      status: tx.payment_status === 'paid' ? 'Paid' : tx.order_status === 'cancelled' ? 'Voided' : 'Pending',
      method: tx.payment_method || 'Cash',
      methodIcon: (tx.payment_method || 'cash') === 'cash' ? 'i-lucide-banknote' : 'i-lucide-credit-card',
      total: tx.total || 0
    }))
  } finally {
    loading.value = false
  }
})

const filteredTx = computed(() => {
  let filtered = transactions.value
  if (search.value) {
    filtered = filtered.filter(tx => tx.orderId.toLowerCase().includes(search.value.toLowerCase()))
  }
  if (activeTab.value === 'Void/Refunds') {
    filtered = filtered.filter(tx => tx.status === 'Voided')
  }
  return filtered
})

const paginatedTx = computed(() => {
  const start = (currentPage.value - 1) * perPage
  return filteredTx.value.slice(start, start + perPage)
})

const totalPages = computed(() => Math.ceil(filteredTx.value.length / perPage))
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
        <UButton color="primary" label="Export CSV" icon="i-lucide-download" />
      </div>
    </div>

    <!-- Tabs -->
    <div class="border-b border-gray-200">
      <div class="flex gap-6">
        <button
          v-for="tab in tabs"
          :key="tab"
          @click="activeTab = tab"
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
          <span v-if="tab === 'Online Orders'" class="bg-blue-100 text-blue-700 text-xs font-semibold px-2 py-0.5 rounded-full">12</span>
        </button>
      </div>
    </div>

    <!-- Filters -->
    <div class="flex items-center gap-4">
      <UInput v-model="search" icon="i-lucide-search" placeholder="Search Order ID, Table #, Customer..." class="w-96" />
      <div class="flex items-center gap-2 text-sm text-gray-500 bg-white border border-gray-200 px-4 py-2 rounded-lg">
        <UIcon name="i-lucide-calendar" class="w-4 h-4" />
        Today: Feb 17, 2026
      </div>
      <div class="flex items-center gap-2 text-sm text-gray-500 bg-white border border-gray-200 px-4 py-2 rounded-lg">
        Filter by Status <UIcon name="i-lucide-chevron-down" class="w-4 h-4" />
      </div>
      <button class="text-sm text-gray-500 hover:text-gray-700">Clear Filters</button>
    </div>

    <!-- Table -->
    <div v-if="!loading && filteredTx.length === 0" class="bg-white rounded-xl border border-gray-100 p-16 text-center">
      <UIcon name="i-lucide-receipt" class="w-12 h-12 mx-auto mb-4 text-gray-300" />
      <h3 class="text-lg font-semibold text-gray-900 mb-2">No transactions yet</h3>
      <p class="text-gray-500 text-sm">Completed orders from the POS will appear here.</p>
    </div>

    <div v-else class="bg-white rounded-xl border border-gray-100 overflow-hidden shadow-sm">
      <table class="w-full text-sm">
        <thead>
          <tr class="border-b border-gray-100">
            <th v-for="col in columns" :key="col.id" class="text-left py-4 px-5 text-xs font-medium text-gray-500 uppercase tracking-wider">{{ col.label }}</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-gray-50">
          <tr v-for="tx in paginatedTx" :key="tx.orderId" class="hover:bg-gray-50 transition-colors">
            <td class="py-4 px-5">
              <p class="font-medium text-gray-900">{{ tx.date }}</p>
              <p class="text-xs text-gray-500">{{ tx.time }}</p>
            </td>
            <td class="py-4 px-5 font-semibold text-primary">{{ tx.orderId }}</td>
            <td class="py-4 px-5">
              <div class="flex items-center gap-2 text-gray-600">
                <UIcon :name="tx.channelIcon" class="w-4 h-4 text-gray-400" />
                {{ tx.channel }}
              </div>
            </td>
            <td class="py-4 px-5">
              <p class="font-medium text-gray-900">{{ tx.table }}</p>
              <p class="text-xs text-gray-500">{{ tx.customer }}</p>
            </td>
            <td class="py-4 px-5 font-bold text-gray-900">RM {{ tx.total.toFixed(2) }}</td>
            <td class="py-4 px-5">
              <div class="flex items-center gap-2 text-gray-600">
                <UIcon :name="tx.methodIcon" class="w-4 h-4 text-gray-400" />
                {{ tx.method }}
              </div>
            </td>
            <td class="py-4 px-5">
              <span
                :class="[
                  'px-3 py-1 rounded-full text-xs font-semibold',
                  tx.status === 'Paid' ? 'bg-green-50 text-green-700' :
                  tx.status === 'Voided' ? 'bg-red-50 text-red-600' :
                  'bg-yellow-50 text-yellow-700'
                ]"
              >
                {{ tx.status }}
              </span>
            </td>
            <td class="py-4 px-5">
              <div class="flex items-center gap-2">
                <UButton icon="i-lucide-eye" color="neutral" variant="ghost" size="xs" />
                <UButton icon="i-lucide-printer" color="neutral" variant="ghost" size="xs" />
              </div>
            </td>
          </tr>
        </tbody>
      </table>

      <!-- Pagination -->
      <div class="flex items-center justify-between px-6 py-4 border-t border-gray-100">
        <p class="text-sm text-gray-500">
          Showing {{ ((currentPage - 1) * perPage) + 1 }} to {{ Math.min(currentPage * perPage, filteredTx.length) }} of {{ filteredTx.length }} results
        </p>
        <div class="flex items-center gap-1">
          <button
            @click="currentPage = Math.max(1, currentPage - 1)"
            :disabled="currentPage === 1"
            class="px-3 py-1.5 text-sm rounded-lg border border-gray-200 text-gray-600 hover:bg-gray-50 disabled:opacity-40"
          >
            <UIcon name="i-lucide-chevron-left" class="w-4 h-4" />
          </button>
          <button
            v-for="page in Math.min(totalPages, 5)"
            :key="page"
            @click="currentPage = page"
            :class="[
              'w-9 h-9 text-sm rounded-lg transition-colors',
              currentPage === page ? 'bg-[#1E293B] text-white' : 'text-gray-600 hover:bg-gray-100'
            ]"
          >
            {{ page }}
          </button>
          <button
            @click="currentPage = Math.min(totalPages, currentPage + 1)"
            :disabled="currentPage >= totalPages"
            class="px-3 py-1.5 text-sm rounded-lg border border-gray-200 text-gray-600 hover:bg-gray-50 disabled:opacity-40"
          >
            <UIcon name="i-lucide-chevron-right" class="w-4 h-4" />
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
