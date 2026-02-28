<script setup lang="ts">
definePageMeta({ layout: 'backoffice' })

const client = useSupabaseClient()
const user = useSupabaseUser()
const loading = ref(true)
const outletId = ref<string | null>(null)

// Real data
const totalRevenue = ref(0)
const totalCOGS = ref(0)
const grossProfit = ref(0)
const netProfit = ref(0)
const totalTax = ref(0)
const totalOrders = ref(0)

const productPerformance = ref<any[]>([])
const productTab = ref('Top Selling')
const categoryBreakdown = ref<{ name: string; count: number; pct: number; color: string }[]>([])
const paymentDistribution = ref<{ name: string; count: number; pct: number; color: string }[]>([])
const hourlyData = ref<number[]>([])

const categoryColors = ['bg-green-500', 'bg-blue-500', 'bg-amber-500', 'bg-purple-500', 'bg-red-500']
const paymentColors = ['bg-[#1E293B]', 'bg-blue-500', 'bg-green-500', 'bg-purple-500']

const formatRM = (amount: number) => 'RM ' + amount.toLocaleString('en-MY', { minimumFractionDigits: 2, maximumFractionDigits: 2 })

onMounted(async () => {
  if (!user.value) { loading.value = false; return }
  try {
    const { data: profile } = await client.from('profiles').select('outlet_id').eq('id', user.value.id).single()
    outletId.value = profile?.outlet_id || null
    if (!outletId.value) return

    // 1. Get all paid orders
    const { data: orders } = await client
      .from('orders')
      .select('id, total, tax, discount, payment_method, created_at')
      .eq('outlet_id', outletId.value)
      .eq('payment_status', 'paid')

    const paidOrders = orders || []
    totalOrders.value = paidOrders.length
    totalRevenue.value = paidOrders.reduce((s: number, o: any) => s + (o.total || 0), 0)
    totalTax.value = paidOrders.reduce((s: number, o: any) => s + (o.tax || 0), 0)

    // 2. Get order items with product cost
    const orderIds = paidOrders.map((o: any) => o.id)
    if (orderIds.length > 0) {
      const { data: items } = await client
        .from('order_items')
        .select('product_id, quantity, total_price, unit_price, products(name, cost, categories(name))')
        .in('order_id', orderIds)

      const allItems = items || []

      // COGS
      totalCOGS.value = allItems.reduce((s: number, i: any) => s + ((i.products?.cost || 0) * i.quantity), 0)
      grossProfit.value = totalRevenue.value - totalCOGS.value
      netProfit.value = grossProfit.value - totalTax.value

      // Product performance
      const productMap: Record<string, { name: string; category: string; sold: number; revenue: number }> = {}
      allItems.forEach((item: any) => {
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
      productPerformance.value = Object.values(productMap).sort((a, b) => b.sold - a.sold)

      // Category breakdown
      const catMap: Record<string, number> = {}
      allItems.forEach((item: any) => {
        const cat = item.products?.categories?.name || 'Other'
        catMap[cat] = (catMap[cat] || 0) + item.quantity
      })
      const totalQty = Object.values(catMap).reduce((s, v) => s + v, 0)
      categoryBreakdown.value = Object.entries(catMap)
        .sort((a, b) => b[1] - a[1])
        .map(([name, count], i) => ({
          name,
          count,
          pct: totalQty > 0 ? Math.round((count / totalQty) * 100) : 0,
          color: categoryColors[i % categoryColors.length]
        }))
    }

    // 3. Payment distribution
    const payMap: Record<string, number> = {}
    paidOrders.forEach((o: any) => {
      const method = (o.payment_method || 'cash').charAt(0).toUpperCase() + (o.payment_method || 'cash').slice(1)
      payMap[method] = (payMap[method] || 0) + 1
    })
    paymentDistribution.value = Object.entries(payMap)
      .sort((a, b) => b[1] - a[1])
      .map(([name, count], i) => ({
        name,
        count,
        pct: totalOrders.value > 0 ? Math.round((count / totalOrders.value) * 100) : 0,
        color: paymentColors[i % paymentColors.length]
      }))

    // 4. Hourly distribution
    const hourMap: number[] = new Array(24).fill(0)
    paidOrders.forEach((o: any) => {
      const hour = new Date(o.created_at).getHours()
      hourMap[hour]++
    })
    // Only show 8am-10pm range
    hourlyData.value = hourMap.slice(8, 22)

  } finally {
    loading.value = false
  }
})

const sortedProducts = computed(() => {
  if (productTab.value === 'Top Selling') {
    return productPerformance.value.slice(0, 10)
  }
  return [...productPerformance.value].sort((a, b) => a.sold - b.sold).slice(0, 10)
})

const maxHourly = computed(() => Math.max(...hourlyData.value, 1))
</script>

<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex justify-between items-start">
      <div>
        <h2 class="text-2xl font-bold text-gray-900">Sales Report</h2>
        <p class="text-gray-500 text-sm mt-1">Comprehensive overview of your sales performance.</p>
      </div>
      <UButton color="neutral" variant="outline" label="Export" icon="i-lucide-download" />
    </div>

    <!-- Pro Tip -->
    <div class="bg-blue-50 border border-blue-200 rounded-xl px-5 py-3 flex items-start gap-3">
      <UIcon name="i-lucide-lightbulb" class="w-5 h-5 text-blue-500 mt-0.5 flex-shrink-0" />
      <p class="text-sm text-blue-700">
        <span class="font-medium text-blue-900">Pro Tip:</span> Export this report to share with your accountant. All numbers are calculated from your actual order data in real-time.
      </p>
    </div>

    <!-- 4 Stat Cards -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-5">
      <div class="bg-white rounded-xl p-5 border border-gray-100 shadow-sm">
        <div class="flex items-start justify-between">
          <div>
            <p class="text-xs font-medium text-gray-500 uppercase tracking-wider">TOTAL REVENUE</p>
            <p v-if="loading" class="text-2xl font-bold text-gray-300 animate-pulse mt-2">---</p>
            <p v-else class="text-2xl font-bold text-gray-900 mt-2">{{ formatRM(totalRevenue) }}</p>
            <p class="text-sm mt-2 text-gray-500">{{ totalOrders }} orders</p>
          </div>
          <div class="w-10 h-10 bg-green-50 rounded-xl flex items-center justify-center">
            <UIcon name="i-lucide-dollar-sign" class="w-5 h-5 text-green-600" />
          </div>
        </div>
      </div>
      <div class="bg-white rounded-xl p-5 border border-gray-100 shadow-sm">
        <div class="flex items-start justify-between">
          <div>
            <p class="text-xs font-medium text-gray-500 uppercase tracking-wider">COGS</p>
            <p v-if="loading" class="text-2xl font-bold text-gray-300 animate-pulse mt-2">---</p>
            <p v-else class="text-2xl font-bold text-gray-900 mt-2">{{ formatRM(totalCOGS) }}</p>
            <p class="text-sm mt-2 text-gray-500">Cost of goods sold</p>
          </div>
          <div class="w-10 h-10 bg-orange-50 rounded-xl flex items-center justify-center">
            <UIcon name="i-lucide-shopping-cart" class="w-5 h-5 text-orange-600" />
          </div>
        </div>
      </div>
      <div class="bg-white rounded-xl p-5 border border-gray-100 shadow-sm">
        <div class="flex items-start justify-between">
          <div>
            <p class="text-xs font-medium text-gray-500 uppercase tracking-wider">GROSS PROFIT</p>
            <p v-if="loading" class="text-2xl font-bold text-gray-300 animate-pulse mt-2">---</p>
            <p v-else class="text-2xl font-bold text-gray-900 mt-2">{{ formatRM(grossProfit) }}</p>
            <p class="text-sm mt-2 text-gray-500">Revenue - COGS</p>
          </div>
          <div class="w-10 h-10 bg-emerald-50 rounded-xl flex items-center justify-center">
            <UIcon name="i-lucide-trending-up" class="w-5 h-5 text-emerald-600" />
          </div>
        </div>
      </div>
      <div class="bg-white rounded-xl p-5 border border-gray-100 shadow-sm">
        <div class="flex items-start justify-between">
          <div>
            <p class="text-xs font-medium text-gray-500 uppercase tracking-wider">NET PROFIT</p>
            <p v-if="loading" class="text-2xl font-bold text-gray-300 animate-pulse mt-2">---</p>
            <p v-else class="text-2xl font-bold text-gray-900 mt-2">{{ formatRM(netProfit) }}</p>
            <p class="text-sm mt-2 text-gray-500">After tax</p>
          </div>
          <div class="w-10 h-10 bg-blue-50 rounded-xl flex items-center justify-center">
            <UIcon name="i-lucide-wallet" class="w-5 h-5 text-blue-600" />
          </div>
        </div>
      </div>
    </div>

    <!-- Charts Row -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <!-- Sales by Category -->
      <div class="bg-white rounded-xl border border-gray-100 shadow-sm p-6">
        <h3 class="font-semibold text-gray-900 mb-4">Sales by Category</h3>
        <div v-if="categoryBreakdown.length === 0 && !loading" class="h-[200px] flex items-center justify-center text-gray-400 text-sm">
          No category data yet
        </div>
        <div v-else class="space-y-4">
          <div v-for="cat in categoryBreakdown" :key="cat.name" class="flex items-center gap-3">
            <span :class="[cat.color, 'w-3 h-3 rounded-full flex-shrink-0']"></span>
            <span class="flex-1 text-sm text-gray-700">{{ cat.name }}</span>
            <div class="w-32 h-2 bg-gray-100 rounded-full overflow-hidden">
              <div :class="[cat.color, 'h-full rounded-full transition-all']" :style="{ width: cat.pct + '%' }"></div>
            </div>
            <span class="text-sm font-semibold text-gray-900 w-12 text-right">{{ cat.pct }}%</span>
          </div>
        </div>
      </div>

      <!-- Peak Hours -->
      <div class="bg-white rounded-xl border border-gray-100 shadow-sm p-6">
        <div class="flex justify-between items-center mb-4">
          <h3 class="font-semibold text-gray-900">Peak Hours</h3>
          <span class="text-xs text-gray-500">Orders per hour (8am-10pm)</span>
        </div>
        <div v-if="hourlyData.length === 0 || maxHourly <= 1" class="h-[200px] flex items-center justify-center text-gray-400 text-sm">
          No hourly data yet
        </div>
        <div v-else class="h-[200px] flex items-end justify-between gap-1.5 px-2">
          <div v-for="(h, i) in hourlyData" :key="i"
            class="flex-1 bg-[#1E293B] rounded-t-md transition-all hover:bg-[#334155] relative group"
            :style="{ height: Math.max((h / maxHourly) * 100, 2) + '%' }"
          >
            <div class="absolute -top-6 left-1/2 -translate-x-1/2 bg-gray-800 text-white text-[10px] px-1.5 py-0.5 rounded opacity-0 group-hover:opacity-100 transition-opacity whitespace-nowrap">
              {{ h }} orders
            </div>
          </div>
        </div>
        <div class="flex justify-between px-2 mt-2">
          <span v-for="t in ['8am', '10', '12pm', '2', '4', '6', '8pm', '10']" :key="t" class="text-[10px] text-gray-400">{{ t }}</span>
        </div>
      </div>
    </div>

    <!-- Bottom Row -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <!-- Product Performance -->
      <div class="bg-white rounded-xl border border-gray-100 shadow-sm overflow-hidden">
        <div class="flex items-center justify-between px-6 py-4 border-b border-gray-100">
          <h3 class="font-semibold text-gray-900">Product Performance</h3>
          <div class="flex gap-1">
            <button
              v-for="tab in ['Top Selling', 'Least Selling']"
              :key="tab"
              @click="productTab = tab"
              :class="[
                'px-4 py-1.5 text-sm rounded-lg transition-colors',
                productTab === tab ? 'bg-gray-900 text-white' : 'text-gray-500 hover:bg-gray-100 border border-gray-200'
              ]"
            >
              {{ tab }}
            </button>
          </div>
        </div>
        <div v-if="sortedProducts.length === 0 && !loading" class="p-10 text-center text-gray-400">
          <UIcon name="i-lucide-package" class="w-8 h-8 mx-auto mb-2 opacity-40" />
          <p class="text-sm">No product data. Complete orders to see performance.</p>
        </div>
        <table v-else class="w-full text-sm">
          <thead>
            <tr class="border-b border-gray-100">
              <th class="text-left py-3 px-6 text-xs font-medium text-gray-500 uppercase">Item</th>
              <th class="text-left py-3 px-6 text-xs font-medium text-gray-500 uppercase">Qty Sold</th>
              <th class="text-left py-3 px-6 text-xs font-medium text-gray-500 uppercase">Revenue</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-50">
            <tr v-for="item in sortedProducts" :key="item.name" class="hover:bg-gray-50 transition-colors">
              <td class="py-4 px-6">
                <p class="font-medium text-gray-900">{{ item.name }}</p>
                <p class="text-xs text-gray-500">{{ item.category }}</p>
              </td>
              <td class="py-4 px-6 text-gray-600">{{ item.sold.toLocaleString() }}</td>
              <td class="py-4 px-6 font-semibold text-gray-900">{{ formatRM(item.revenue) }}</td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Financial Summary -->
      <div class="bg-white rounded-xl border border-gray-100 shadow-sm p-6">
        <h3 class="font-semibold text-gray-900 mb-6">Financial Summary</h3>
        <div class="grid grid-cols-2 gap-4 mb-6">
          <div class="bg-gray-50 rounded-lg p-4">
            <p class="text-xs text-gray-500 uppercase font-medium">Total Tax Collected</p>
            <p class="text-xl font-bold text-gray-900 mt-1">{{ formatRM(totalTax) }}</p>
          </div>
          <div class="bg-gray-50 rounded-lg p-4">
            <p class="text-xs text-gray-500 uppercase font-medium">Total Orders</p>
            <p class="text-xl font-bold text-gray-900 mt-1">{{ totalOrders }}</p>
          </div>
        </div>

        <!-- Payment Distribution -->
        <h4 class="font-semibold text-gray-900 text-sm mb-4 uppercase">Payment Distribution</h4>
        <div v-if="paymentDistribution.length === 0 && !loading" class="text-center text-gray-400 text-sm py-4">
          No payment data yet
        </div>
        <div v-else class="space-y-3">
          <div v-for="pm in paymentDistribution" :key="pm.name" class="flex items-center justify-between">
            <div class="flex items-center gap-2">
              <span :class="[pm.color, 'w-6 h-2 rounded-full']"></span>
              <span class="text-sm text-gray-600">{{ pm.name }}</span>
            </div>
            <div class="flex items-center gap-2">
              <span class="text-sm text-gray-500">{{ pm.count }} orders</span>
              <span class="font-semibold text-gray-900">{{ pm.pct }}%</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
