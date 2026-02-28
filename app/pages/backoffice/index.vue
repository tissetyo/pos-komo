<script setup lang="ts">
definePageMeta({ layout: 'backoffice' })

const { client, outletId, profileReady } = useUserProfile()
const dateRange = ref<'Today' | 'This Week' | 'This Month'>('Today')
const loading = ref(true)

// Real data refs
const totalSales = ref(0)
const totalTransactions = ref(0)
const avgOrderValue = ref(0)
const newCustomers = ref(0)
const bestSellers = ref<any[]>([])
const channelBreakdown = ref<{ label: string; count: number; total: number }[]>([])
const recentOrders = ref<any[]>([])

// Date helpers
const getDateRange = (range: string) => {
  const now = new Date()
  const start = new Date()
  if (range === 'Today') {
    start.setHours(0, 0, 0, 0)
  } else if (range === 'This Week') {
    start.setDate(now.getDate() - now.getDay())
    start.setHours(0, 0, 0, 0)
  } else {
    start.setDate(1)
    start.setHours(0, 0, 0, 0)
  }
  return start.toISOString()
}

const fetchDashboardData = async () => {
  if (!outletId.value) { loading.value = false; return }
  loading.value = true

  try {

    const startDate = getDateRange(dateRange.value)

    // 1. Orders in date range
    const { data: orders } = await client
      .from('orders')
      .select('id, total, payment_method, order_type, payment_status, created_at, receipt_number')
      .eq('outlet_id', outletId.value)
      .eq('payment_status', 'paid')
      .gte('created_at', startDate)
      .order('created_at', { ascending: false })

    const paidOrders = orders || []
    totalTransactions.value = paidOrders.length
    totalSales.value = paidOrders.reduce((sum: number, o: any) => sum + (o.total || 0), 0)
    avgOrderValue.value = paidOrders.length > 0 ? Math.round(totalSales.value / paidOrders.length) : 0

    // 2. New customers this period
    const { count } = await client
      .from('customers')
      .select('id', { count: 'exact', head: true })
      .eq('outlet_id', outletId.value)
      .gte('created_at', startDate)
    newCustomers.value = count || 0

    // 3. Channel breakdown
    const channels: Record<string, { count: number; total: number }> = {}
    paidOrders.forEach((o: any) => {
      const ch = o.order_type || 'dine-in'
      if (!channels[ch]) channels[ch] = { count: 0, total: 0 }
      channels[ch].count++
      channels[ch].total += o.total || 0
    })
    channelBreakdown.value = Object.entries(channels).map(([label, data]) => ({
      label: label === 'dine-in' ? 'Dine-in' : label === 'takeaway' ? 'Takeaway' : label === 'delivery' ? 'Delivery' : label,
      count: data.count,
      total: data.total
    }))

    // 4. Best selling products
    const orderIds = paidOrders.map((o: any) => o.id)
    if (orderIds.length > 0) {
      const { data: items } = await client
        .from('order_items')
        .select('product_id, quantity, total_price, products(name, categories(name))')
        .in('order_id', orderIds)

      const productMap: Record<string, { name: string; category: string; sold: number; revenue: number }> = {}
      ;(items || []).forEach((item: any) => {
        const pid = item.product_id
        if (!productMap[pid]) {
          productMap[pid] = {
            name: item.products?.name || 'Unknown',
            category: item.products?.categories?.name || 'Other',
            sold: 0,
            revenue: 0
          }
        }
        productMap[pid].sold += item.quantity
        productMap[pid].revenue += item.total_price
      })
      bestSellers.value = Object.values(productMap).sort((a, b) => b.sold - a.sold).slice(0, 5)
    } else {
      bestSellers.value = []
    }

    // 5. Recent orders
    recentOrders.value = paidOrders.slice(0, 5)

  } finally {
    loading.value = false
  }
}

watch(dateRange, () => fetchDashboardData())
watch(profileReady, (ready) => { if (ready) fetchDashboardData() })

const formatRM = (amount: number) => 'RM ' + (amount / 100 || amount).toLocaleString('en-MY', { minimumFractionDigits: 2, maximumFractionDigits: 2 })

const categoryColors = ['bg-red-100 text-red-600', 'bg-amber-100 text-amber-600', 'bg-green-100 text-green-600', 'bg-blue-100 text-blue-600', 'bg-purple-100 text-purple-600']
</script>

<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex justify-between items-start">
      <div>
        <h2 class="text-2xl font-bold text-gray-900">Welcome Back!</h2>
        <p class="text-sm text-gray-500 mt-1">Here's what's happening with your store.</p>
      </div>
      <div class="flex items-center gap-1">
        <button
          v-for="range in (['Today', 'This Week', 'This Month'] as const)"
          :key="range"
          @click="dateRange = range"
          :class="[
            'px-4 py-2 text-sm font-medium rounded-lg transition-colors',
            dateRange === range ? 'bg-[#1E293B] text-white' : 'bg-white text-gray-600 hover:bg-gray-100 border border-gray-200'
          ]"
        >
          {{ range }}
        </button>
      </div>
    </div>

    <!-- Pro Tip -->
    <div class="bg-blue-50 border border-blue-200 rounded-xl px-5 py-3 flex items-start gap-3">
      <UIcon name="i-lucide-lightbulb" class="w-5 h-5 text-blue-500 mt-0.5 flex-shrink-0" />
      <div>
        <p class="text-sm font-medium text-blue-900">Pro Tip</p>
        <p class="text-sm text-blue-700">Use the date range filters above to compare performance across different periods. Your stats update in real-time!</p>
      </div>
    </div>

    <!-- 4 Stat Cards -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-5">
      <div class="bg-white rounded-xl p-5 border border-gray-100 shadow-sm hover:shadow-md transition-shadow">
        <div class="flex items-start justify-between mb-3">
          <p class="text-sm text-gray-500 font-medium">Total Sales</p>
          <div class="w-10 h-10 bg-blue-50 rounded-xl flex items-center justify-center">
            <UIcon name="i-lucide-dollar-sign" class="w-5 h-5 text-blue-600" />
          </div>
        </div>
        <p v-if="loading" class="text-2xl font-bold text-gray-300 animate-pulse">---</p>
        <p v-else class="text-2xl font-bold text-gray-900">{{ formatRM(totalSales) }}</p>
        <p class="text-xs text-gray-400 mt-2">{{ dateRange }} period</p>
      </div>

      <div class="bg-white rounded-xl p-5 border border-gray-100 shadow-sm hover:shadow-md transition-shadow">
        <div class="flex items-start justify-between mb-3">
          <p class="text-sm text-gray-500 font-medium">New Customers</p>
          <div class="w-10 h-10 bg-emerald-50 rounded-xl flex items-center justify-center">
            <UIcon name="i-lucide-user-plus" class="w-5 h-5 text-emerald-600" />
          </div>
        </div>
        <p v-if="loading" class="text-2xl font-bold text-gray-300 animate-pulse">---</p>
        <p v-else class="text-2xl font-bold text-gray-900">{{ newCustomers }}</p>
        <p class="text-xs text-gray-400 mt-2">{{ dateRange }} period</p>
      </div>

      <div class="bg-white rounded-xl p-5 border border-gray-100 shadow-sm hover:shadow-md transition-shadow">
        <div class="flex items-start justify-between mb-3">
          <p class="text-sm text-gray-500 font-medium">Total Transactions</p>
          <div class="w-10 h-10 bg-purple-50 rounded-xl flex items-center justify-center">
            <UIcon name="i-lucide-receipt" class="w-5 h-5 text-purple-600" />
          </div>
        </div>
        <p v-if="loading" class="text-2xl font-bold text-gray-300 animate-pulse">---</p>
        <p v-else class="text-2xl font-bold text-gray-900">{{ totalTransactions.toLocaleString() }}</p>
        <p class="text-xs text-gray-400 mt-2">{{ dateRange }} period</p>
      </div>

      <div class="bg-white rounded-xl p-5 border border-gray-100 shadow-sm hover:shadow-md transition-shadow">
        <div class="flex items-start justify-between mb-3">
          <p class="text-sm text-gray-500 font-medium">Avg. Order Value</p>
          <div class="w-10 h-10 bg-orange-50 rounded-xl flex items-center justify-center">
            <UIcon name="i-lucide-calculator" class="w-5 h-5 text-orange-600" />
          </div>
        </div>
        <p v-if="loading" class="text-2xl font-bold text-gray-300 animate-pulse">---</p>
        <p v-else class="text-2xl font-bold text-gray-900">{{ formatRM(avgOrderValue) }}</p>
        <p class="text-xs text-gray-400 mt-2">{{ dateRange }} period</p>
      </div>
    </div>

    <!-- Charts Row -->
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
      <!-- Sales by Channel -->
      <div class="lg:col-span-2 bg-white rounded-xl border border-gray-100 shadow-sm p-6">
        <h3 class="font-semibold text-gray-900 text-lg mb-4">Sales by Channel</h3>
        <div v-if="!loading && channelBreakdown.length === 0" class="h-[200px] flex items-center justify-center text-gray-400">
          <div class="text-center">
            <UIcon name="i-lucide-bar-chart-3" class="w-8 h-8 mx-auto mb-2 opacity-50" />
            <p class="text-sm">No sales data for this period</p>
          </div>
        </div>
        <div v-else class="space-y-4">
          <div v-for="ch in channelBreakdown" :key="ch.label" class="flex items-center justify-between p-4 bg-gray-50 rounded-xl">
            <div class="flex items-center gap-3">
              <UIcon :name="ch.label === 'Dine-in' ? 'i-lucide-utensils-crossed' : ch.label === 'Takeaway' ? 'i-lucide-shopping-bag' : 'i-lucide-truck'" class="w-5 h-5 text-gray-600" />
              <div>
                <p class="font-medium text-gray-900">{{ ch.label }}</p>
                <p class="text-xs text-gray-500">{{ ch.count }} orders</p>
              </div>
            </div>
            <p class="font-bold text-gray-900">{{ formatRM(ch.total) }}</p>
          </div>
        </div>
      </div>

      <!-- Quick Summary -->
      <div class="bg-white rounded-xl border border-gray-100 shadow-sm p-6">
        <h3 class="font-semibold text-gray-900 text-lg mb-4">Quick Summary</h3>
        <div class="space-y-4">
          <div class="flex items-center justify-between p-3 bg-blue-50 rounded-lg">
            <span class="text-sm text-blue-700 font-medium">Total Orders</span>
            <span class="font-bold text-blue-900">{{ totalTransactions }}</span>
          </div>
          <div class="flex items-center justify-between p-3 bg-emerald-50 rounded-lg">
            <span class="text-sm text-emerald-700 font-medium">Revenue</span>
            <span class="font-bold text-emerald-900">{{ formatRM(totalSales) }}</span>
          </div>
          <div class="flex items-center justify-between p-3 bg-orange-50 rounded-lg">
            <span class="text-sm text-orange-700 font-medium">Avg Order</span>
            <span class="font-bold text-orange-900">{{ formatRM(avgOrderValue) }}</span>
          </div>
          <div class="flex items-center justify-between p-3 bg-purple-50 rounded-lg">
            <span class="text-sm text-purple-700 font-medium">New Customers</span>
            <span class="font-bold text-purple-900">{{ newCustomers }}</span>
          </div>
        </div>
      </div>
    </div>

    <!-- Bottom Row -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <!-- Best Selling Products -->
      <div class="bg-white rounded-xl border border-gray-100 shadow-sm">
        <div class="flex justify-between items-center px-6 py-4 border-b border-gray-100">
          <h3 class="font-semibold text-gray-900">Best Selling Products</h3>
          <span class="text-xs text-gray-500">{{ dateRange }}</span>
        </div>
        <div v-if="bestSellers.length === 0 && !loading" class="p-10 text-center text-gray-400">
          <UIcon name="i-lucide-trending-up" class="w-8 h-8 mx-auto mb-2 opacity-40" />
          <p class="text-sm">No sales data yet. Complete orders from the POS to see your top products.</p>
        </div>
        <div v-else class="divide-y divide-gray-50">
          <div v-for="(item, i) in bestSellers" :key="item.name" class="flex items-center gap-4 px-6 py-4 hover:bg-gray-50 transition-colors">
            <div :class="[categoryColors[i % categoryColors.length], 'w-10 h-10 rounded-lg flex items-center justify-center flex-shrink-0']">
              <span class="font-bold text-sm">{{ i + 1 }}</span>
            </div>
            <div class="flex-1 min-w-0">
              <p class="font-medium text-gray-900">{{ item.name }}</p>
              <p class="text-xs text-gray-500">{{ item.category }}</p>
            </div>
            <div class="text-right">
              <p class="font-bold text-gray-900">{{ item.sold }} sold</p>
              <p class="text-xs text-gray-500">{{ formatRM(item.revenue) }}</p>
            </div>
          </div>
        </div>
      </div>

      <!-- Recent Orders -->
      <div class="bg-white rounded-xl border border-gray-100 shadow-sm">
        <div class="flex justify-between items-center px-6 py-4 border-b border-gray-100">
          <h3 class="font-semibold text-gray-900">Recent Orders</h3>
          <NuxtLink to="/backoffice/transactions" class="text-sm text-primary hover:underline">View All</NuxtLink>
        </div>
        <div v-if="recentOrders.length === 0 && !loading" class="p-10 text-center text-gray-400">
          <UIcon name="i-lucide-receipt" class="w-8 h-8 mx-auto mb-2 opacity-40" />
          <p class="text-sm">No orders yet. Start selling from the POS!</p>
        </div>
        <div v-else class="divide-y divide-gray-50">
          <div v-for="order in recentOrders" :key="order.id" class="flex items-center justify-between px-6 py-4 hover:bg-gray-50 transition-colors">
            <div>
              <p class="font-medium text-gray-900 text-sm">#{{ order.receipt_number }}</p>
              <p class="text-xs text-gray-500">{{ new Date(order.created_at).toLocaleString('en-MY', { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' }) }}</p>
            </div>
            <div class="text-right">
              <p class="font-bold text-gray-900">{{ formatRM(order.total) }}</p>
              <span class="text-xs px-2 py-0.5 rounded-full bg-green-50 text-green-700 font-medium">{{ order.payment_status }}</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
