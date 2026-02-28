<script setup lang="ts">
definePageMeta({
  layout: 'backoffice'
})

const client = useSupabaseClient()
const user = useSupabaseUser()

const metrics = ref([
  { label: 'Total Revenue', value: 'Rp 0', trend: '', icon: 'i-lucide-banknote', color: 'text-green-600', bg: 'bg-green-100 dark:bg-green-900/30' },
  { label: 'Total Orders', value: '0', trend: '', icon: 'i-lucide-receipt', color: 'text-blue-600', bg: 'bg-blue-100 dark:bg-blue-900/30' },
  { label: 'Avg. Order Value', value: 'Rp 0', trend: '', icon: 'i-lucide-calculator', color: 'text-orange-600', bg: 'bg-orange-100 dark:bg-orange-900/30' }
])

const recentTransactions = ref<any[]>([])
const loadingMetrics = ref(true)

const formatRp = (amount: number) => {
  return 'Rp ' + amount.toLocaleString('id-ID')
}

onMounted(async () => {
  if (!user.value) return

  try {
    // Fetch profile to get outlet_id
    const { data: profile } = await client
      .from('profiles')
      .select('outlet_id')
      .eq('id', user.value.id)
      .single()

    if (!profile?.outlet_id) {
      loadingMetrics.value = false
      return
    }

    // Fetch orders for this outlet
    const { data: orders } = await client
      .from('orders')
      .select('id, total, payment_method, payment_status, order_status, created_at, receipt_number')
      .eq('outlet_id', profile.outlet_id)
      .eq('payment_status', 'paid')
      .order('created_at', { ascending: false })

    if (orders && orders.length > 0) {
      const totalRevenue = orders.reduce((sum: number, o: any) => sum + (o.total || 0), 0)
      const totalOrders = orders.length
      const avgValue = totalOrders > 0 ? Math.round(totalRevenue / totalOrders) : 0

      metrics.value[0].value = formatRp(totalRevenue)
      metrics.value[1].value = totalOrders.toString()
      metrics.value[2].value = formatRp(avgValue)
    }

    // Fetch recent transactions (all statuses)
    const { data: recent } = await client
      .from('orders')
      .select('id, receipt_number, total, payment_method, payment_status, order_status, created_at')
      .eq('outlet_id', profile.outlet_id)
      .order('created_at', { ascending: false })
      .limit(5)

    recentTransactions.value = (recent || []).map((tx: any) => ({
      id: tx.receipt_number || tx.id.substring(0, 8),
      time: new Date(tx.created_at).toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' }),
      customer: 'Walk-in',
      amount: tx.total || 0,
      status: tx.payment_status === 'paid' ? 'Completed' : 'Pending',
      method: (tx.payment_method || 'Cash').toUpperCase()
    }))
  } finally {
    loadingMetrics.value = false
  }
})
</script>

<template>
  <div class="space-y-6">
    <div class="flex justify-between items-end">
      <div>
        <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Dashboard Overview</h2>
        <p class="text-gray-500 dark:text-gray-400 text-sm mt-1">Here's what's happening at your stores today.</p>
      </div>
    </div>

    <!-- Metrik Cards -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
      <div v-for="metric in metrics" :key="metric.label" class="bg-white dark:bg-gray-900 rounded-2xl p-6 shadow-sm border border-gray-100 dark:border-gray-800 flex items-start gap-4 hover:shadow-md transition-shadow">
        <div :class="[metric.bg, metric.color, 'p-3 rounded-xl']">
          <UIcon :name="metric.icon" class="w-6 h-6" />
        </div>
        <div>
          <p class="text-sm font-medium text-gray-500 dark:text-gray-400">{{ metric.label }}</p>
          <div class="flex items-end gap-2 mt-1">
            <p v-if="loadingMetrics" class="text-2xl font-bold text-gray-300 dark:text-gray-600 animate-pulse">---</p>
            <p v-else class="text-2xl font-bold text-gray-900 dark:text-white">{{ metric.value }}</p>
          </div>
        </div>
      </div>
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
      <!-- Chart Area Placeholder -->
      <div class="lg:col-span-2 bg-white dark:bg-gray-900 rounded-2xl shadow-sm border border-gray-100 dark:border-gray-800 p-6 flex flex-col">
        <div class="flex justify-between mb-6">
          <h3 class="font-semibold text-gray-900 dark:text-white text-lg">Revenue Trend</h3>
          <USelect :options="['Today', 'This Week', 'This Month']" placeholder="Today" />
        </div>
        <div class="flex-1 min-h-[300px] flex items-center justify-center border-2 border-dashed border-gray-200 dark:border-gray-700 rounded-xl bg-gray-50 dark:bg-gray-800/50 text-gray-400 dark:text-gray-500">
          <div class="text-center">
            <UIcon name="i-lucide-bar-chart-3" class="w-8 h-8 mx-auto mb-2 opacity-50" />
            <p>Chart will appear when you have order data</p>
          </div>
        </div>
      </div>

      <!-- Recent Transactions -->
      <div class="bg-white dark:bg-gray-900 rounded-2xl shadow-sm border border-gray-100 dark:border-gray-800 p-6 flex flex-col">
        <div class="flex justify-between mb-4">
          <h3 class="font-semibold text-gray-900 dark:text-white text-lg">Recent Orders</h3>
          <UButton to="/backoffice/transactions" color="neutral" variant="ghost" icon="i-lucide-arrow-right" class="-mr-2" />
        </div>

        <div v-if="recentTransactions.length === 0 && !loadingMetrics" class="flex-1 flex items-center justify-center text-center text-gray-400 dark:text-gray-500 py-12">
          <div>
            <UIcon name="i-lucide-inbox" class="w-10 h-10 mx-auto mb-3 opacity-40" />
            <p class="text-sm">No orders yet.<br>Start selling from the POS!</p>
          </div>
        </div>

        <div class="space-y-4 flex-1 overflow-y-auto pr-2">
          <div v-for="tx in recentTransactions" :key="tx.id" class="flex items-center justify-between pb-4 border-b border-gray-50 dark:border-gray-800 last:border-0 last:pb-0">
            <div class="flex items-center gap-3">
              <div :class="['w-10 h-10 rounded-full flex items-center justify-center flex-shrink-0', tx.status === 'Completed' ? 'bg-green-100 dark:bg-green-900/30 text-green-600' : 'bg-orange-100 dark:bg-orange-900/30 text-orange-600']">
                <UIcon :name="tx.status === 'Completed' ? 'i-lucide-check' : 'i-lucide-clock'" class="w-5 h-5" />
              </div>
              <div>
                <p class="text-sm font-medium text-gray-900 dark:text-white">{{ tx.id }}</p>
                <p class="text-xs text-gray-500 dark:text-gray-400">{{ tx.customer }} • {{ tx.time }}</p>
              </div>
            </div>
            <div class="text-right">
              <p class="text-sm font-semibold text-gray-900 dark:text-white">Rp {{ tx.amount.toLocaleString('id-ID') }}</p>
              <UBadge :color="tx.method === 'QRIS' ? 'blue' : (tx.method === 'EDC' ? 'purple' : 'neutral')" variant="soft" size="xs">
                {{ tx.method }}
              </UBadge>
            </div>
          </div>
        </div>
      </div>
    </div>

  </div>
</template>
