<script setup lang="ts">
definePageMeta({ layout: 'backoffice' })

const client = useSupabaseClient()
const user = useSupabaseUser()
const transactions = ref<any[]>([])
const loading = ref(true)
const search = ref('')

const columns = [
  { id: 'id', key: 'id', label: 'Transaction ID' },
  { id: 'details', key: 'details', label: 'Date & Location' },
  { id: 'status', key: 'status', label: 'Status' },
  { id: 'payment', key: 'payment', label: 'Payment' },
  { id: 'total', key: 'total', label: 'Total Amount' }
]

onMounted(async () => {
  if (!user.value) return
  try {
    const { data: profile } = await client
      .from('profiles')
      .select('outlet_id')
      .eq('id', user.value.id)
      .single()

    if (!profile?.outlet_id) return

    const { data } = await client
      .from('orders')
      .select('*, outlets(name), profiles!orders_cashier_id_fkey(full_name)')
      .eq('outlet_id', profile.outlet_id)
      .order('created_at', { ascending: false })
      .limit(50)

    transactions.value = (data || []).map((tx: any) => ({
      id: tx.receipt_number || tx.id.substring(0, 8),
      date: new Date(tx.created_at).toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' }),
      outlet: tx.outlets?.name || '-',
      cashier: tx.profiles?.full_name || '-',
      status: tx.payment_status === 'paid' ? 'Completed' : tx.order_status === 'cancelled' ? 'Voided' : 'Pending',
      method: tx.payment_method || 'Cash',
      total: tx.total || 0
    }))
  } finally {
    loading.value = false
  }
})

const filteredTx = computed(() => {
  if (!search.value) return transactions.value
  return transactions.value.filter(tx => tx.id.toLowerCase().includes(search.value.toLowerCase()))
})
</script>

<template>
  <div class="space-y-6">
    <div class="flex justify-between items-end">
      <div>
        <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Transactions History</h2>
        <p class="text-gray-500 dark:text-gray-400 text-sm mt-1">Review past orders and payment details.</p>
      </div>
    </div>

    <!-- Filters & Search -->
    <div class="bg-white dark:bg-gray-900 p-4 justify-between flex flex-col md:flex-row gap-4 items-center rounded-2xl shadow-sm border border-gray-100 dark:border-gray-800">
       <UInput v-model="search" icon="i-lucide-search" placeholder="Search by TRX ID..." class="w-full md:w-80" />
    </div>

    <!-- Empty State -->
    <div v-if="!loading && filteredTx.length === 0" class="bg-white dark:bg-gray-900 rounded-2xl shadow-sm border border-gray-100 dark:border-gray-800 p-16 text-center">
      <UIcon name="i-lucide-receipt" class="w-12 h-12 mx-auto mb-4 text-gray-300 dark:text-gray-600" />
      <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-2">No transactions yet</h3>
      <p class="text-gray-500 dark:text-gray-400 text-sm">Completed orders from the POS will appear here.</p>
    </div>

    <!-- Data Table -->
    <div v-else class="bg-white dark:bg-gray-900 rounded-2xl shadow-sm border border-gray-100 dark:border-gray-800 overflow-hidden">
      <UTable :rows="filteredTx" :columns="columns" :loading="loading">
        <template #id-data="{ row }">
          <p class="font-semibold text-primary cursor-pointer hover:underline">{{ row.id }}</p>
        </template>

        <template #details-data="{ row }">
          <div>
            <p class="text-sm font-medium text-gray-900 dark:text-white">{{ row.date }}</p>
            <p class="text-xs text-gray-500 dark:text-gray-400">{{ row.outlet }} • {{ row.cashier }}</p>
          </div>
        </template>

        <template #status-data="{ row }">
          <UBadge :color="row.status === 'Completed' ? 'success' : (row.status === 'Voided' ? 'error' : 'warning')" variant="soft" class="px-2.5 py-1 rounded-full text-xs font-medium">
            {{ row.status }}
          </UBadge>
        </template>

        <template #payment-data="{ row }">
           <div class="flex items-center gap-2 text-sm text-gray-600 dark:text-gray-400">
             <UIcon :name="row.method === 'cash' ? 'i-lucide-banknote' : (row.method === 'qris' ? 'i-lucide-qr-code' : 'i-lucide-credit-card')" class="w-4 h-4 text-gray-400" />
             {{ row.method }}
           </div>
        </template>

        <template #total-data="{ row }">
          <span class="font-bold text-gray-900 dark:text-white">
            Rp {{ row.total.toLocaleString('id-ID') }}
          </span>
        </template>
      </UTable>
    </div>
  </div>
</template>
