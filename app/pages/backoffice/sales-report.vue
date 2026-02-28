<script setup lang="ts">
definePageMeta({ layout: 'backoffice' })

const client = useSupabaseClient()
const user = useSupabaseUser()
const loading = ref(true)

const stats = ref([
  { label: 'TOTAL REVENUE', value: 'RM 42,593.50', trend: '↗ +12.5%', trendText: 'vs last period', icon: 'i-lucide-dollar-sign', iconBg: 'bg-green-50', iconColor: 'text-green-600' },
  { label: 'COGS', value: 'RM 14,205.00', trend: '↗ +2.3%', trendText: 'vs last period', icon: 'i-lucide-shopping-cart', iconBg: 'bg-orange-50', iconColor: 'text-orange-600' },
  { label: 'GROSS PROFIT', value: 'RM 28,388.50', trend: '↗ +8.1%', trendText: 'vs last period', icon: 'i-lucide-trending-up', iconBg: 'bg-emerald-50', iconColor: 'text-emerald-600' },
  { label: 'NET PROFIT', value: 'RM 18,450.20', trend: '↗ +15.4%', trendText: 'vs last period', icon: 'i-lucide-wallet', iconBg: 'bg-blue-50', iconColor: 'text-blue-600' },
])

const topItems = ref([
  { name: 'Signature Latte', sold: 482, revenue: 'RM 6,266', trend: '↑ 12%', trendColor: 'text-green-600' },
  { name: 'Avocado Toast', sold: 315, revenue: 'RM 5,670', trend: '↑ 8%', trendColor: 'text-green-600' },
  { name: 'Chicken Croissant', sold: 290, revenue: 'RM 4,060', trend: '↓ 2%', trendColor: 'text-red-500' },
  { name: 'Chocolate Muffin', sold: 210, revenue: 'RM 1,890', trend: '↑ 5%', trendColor: 'text-green-600' },
  { name: 'Iced Americano', sold: 185, revenue: 'RM 2,035', trend: '— 0%', trendColor: 'text-gray-500' },
])

const productTab = ref('Top 10')

const categoryData = [
  { name: 'Coffee & Beverages', pct: '45%', color: 'bg-green-500' },
  { name: 'Main Course Food', pct: '35%', color: 'bg-blue-500' },
  { name: 'Desserts & Pastries', pct: '20%', color: 'bg-green-300' },
]

onMounted(async () => {
  if (!user.value) { loading.value = false; return }
  try {
    const { data: profile } = await client.from('profiles').select('outlet_id').eq('id', user.value.id).single()
    if (!profile?.outlet_id) return

    const { data: orders } = await client
      .from('orders')
      .select('total')
      .eq('outlet_id', profile.outlet_id)
      .eq('payment_status', 'paid')

    if (orders && orders.length > 0) {
      const total = orders.reduce((sum: number, o: any) => sum + (o.total || 0), 0)
      stats.value[0].value = 'RM ' + total.toLocaleString('en-MY', { minimumFractionDigits: 2 })
    }
  } finally {
    loading.value = false
  }
})
</script>

<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex justify-between items-start">
      <h2 class="text-2xl font-bold text-gray-900">Sales Report</h2>
      <div class="flex items-center gap-3">
        <UButton color="primary" label="Update Report" icon="i-lucide-refresh-cw" />
        <UButton color="neutral" variant="outline" label="Export" icon="i-lucide-download" />
      </div>
    </div>

    <!-- Filter Bar -->
    <div class="flex items-center gap-4">
      <div class="flex items-center gap-2 text-sm text-gray-500 bg-white border border-gray-200 px-4 py-2 rounded-lg">
        <UIcon name="i-lucide-calendar" class="w-4 h-4" />
        This Week <UIcon name="i-lucide-chevron-down" class="w-4 h-4" />
      </div>
      <div class="flex items-center gap-2 text-sm text-gray-500 bg-white border border-gray-200 px-4 py-2 rounded-lg">
        <UIcon name="i-lucide-clock" class="w-4 h-4" />
        All Shifts <UIcon name="i-lucide-chevron-down" class="w-4 h-4" />
      </div>
      <div class="flex items-center gap-2 text-sm text-gray-500 bg-white border border-gray-200 px-4 py-2 rounded-lg">
        <UIcon name="i-lucide-building" class="w-4 h-4" />
        All Outlets <UIcon name="i-lucide-chevron-down" class="w-4 h-4" />
      </div>
    </div>

    <!-- 4 Stat Cards -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-5">
      <div v-for="s in stats" :key="s.label" class="bg-white rounded-xl p-5 border border-gray-100 shadow-sm">
        <div class="flex items-start justify-between">
          <div>
            <p class="text-xs font-medium text-gray-500 uppercase tracking-wider">{{ s.label }}</p>
            <p class="text-2xl font-bold text-gray-900 mt-2">{{ s.value }}</p>
            <p class="text-sm mt-2">
              <span class="text-green-600 font-medium">{{ s.trend }}</span>
              <span class="text-gray-400 ml-1">{{ s.trendText }}</span>
            </p>
          </div>
          <div :class="[s.iconBg, s.iconColor, 'w-10 h-10 rounded-xl flex items-center justify-center']">
            <UIcon :name="s.icon" class="w-5 h-5" />
          </div>
        </div>
      </div>
    </div>

    <!-- Charts Row -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <!-- Sales by Category -->
      <div class="bg-white rounded-xl border border-gray-100 shadow-sm p-6">
        <div class="flex justify-between items-center mb-6">
          <h3 class="font-semibold text-gray-900">Sales by Category</h3>
          <UIcon name="i-lucide-more-horizontal" class="w-5 h-5 text-gray-400" />
        </div>
        <div class="flex flex-col items-center">
          <!-- Donut Placeholder -->
          <div class="w-40 h-40 rounded-full border-[24px] border-[#1E293B] border-t-blue-500 border-l-green-400 flex items-center justify-center mb-6">
            <div class="text-center">
              <p class="text-2xl font-bold text-gray-900">1,248</p>
              <p class="text-xs text-gray-500 uppercase">Orders</p>
            </div>
          </div>
          <div class="flex gap-6">
            <div v-for="cat in categoryData" :key="cat.name" class="flex items-center gap-2 text-sm">
              <span :class="[cat.color, 'w-3 h-3 rounded-full']"></span>
              <span class="text-gray-600">{{ cat.name }}</span>
              <span class="font-semibold text-gray-900">{{ cat.pct }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Peak Hours Analysis -->
      <div class="bg-white rounded-xl border border-gray-100 shadow-sm p-6">
        <div class="flex justify-between items-center mb-6">
          <h3 class="font-semibold text-gray-900">Peak Hours Analysis</h3>
          <div class="flex items-center gap-2 text-xs text-gray-500">
            <span class="w-3 h-3 rounded-full bg-[#1E293B] inline-block"></span> Sales Volume
          </div>
        </div>
        <div class="h-[200px] flex items-end justify-between gap-2 px-4">
          <div v-for="(h, i) in [30, 40, 50, 85, 95, 80, 70, 60, 45, 35, 25, 20]" :key="i"
            class="flex-1 bg-[#1E293B] rounded-t-md transition-all hover:bg-[#334155]"
            :style="{ height: h + '%' }"
          ></div>
        </div>
        <div class="flex justify-between px-4 mt-2">
          <span v-for="t in ['10am', '12pm', '2pm', '4pm', '6pm', '8pm', '10pm']" :key="t" class="text-xs text-gray-400">{{ t }}</span>
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
              v-for="tab in ['Top 10', 'Least Selling']"
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
        <table class="w-full text-sm">
          <thead>
            <tr class="border-b border-gray-100">
              <th class="text-left py-3 px-6 text-xs font-medium text-gray-500 uppercase">Item Name</th>
              <th class="text-left py-3 px-6 text-xs font-medium text-gray-500 uppercase">Qty Sold</th>
              <th class="text-left py-3 px-6 text-xs font-medium text-gray-500 uppercase">Revenue</th>
              <th class="text-left py-3 px-6 text-xs font-medium text-gray-500 uppercase">Trend</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-50">
            <tr v-for="item in topItems" :key="item.name" class="hover:bg-gray-50 transition-colors">
              <td class="py-4 px-6 font-medium text-gray-900">{{ item.name }}</td>
              <td class="py-4 px-6 text-gray-600">{{ item.sold.toLocaleString() }}</td>
              <td class="py-4 px-6 font-semibold text-gray-900">{{ item.revenue }}</td>
              <td class="py-4 px-6" :class="item.trendColor">{{ item.trend }}</td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Financial Summary -->
      <div class="bg-white rounded-xl border border-gray-100 shadow-sm p-6">
        <h3 class="font-semibold text-gray-900 mb-6">Financial Summary</h3>
        <div class="grid grid-cols-2 gap-4 mb-6">
          <div class="bg-gray-50 rounded-lg p-4">
            <p class="text-xs text-gray-500 uppercase font-medium">Service Charge (10%)</p>
            <p class="text-xl font-bold text-gray-900 mt-1">RM 4,259.35</p>
          </div>
          <div class="bg-gray-50 rounded-lg p-4">
            <p class="text-xs text-gray-500 uppercase font-medium">SST Tax (6%)</p>
            <p class="text-xl font-bold text-gray-900 mt-1">RM 2,555.61</p>
          </div>
        </div>

        <div class="grid grid-cols-2 gap-4">
          <!-- Payment Distribution -->
          <div class="border border-gray-100 rounded-lg p-4">
            <h4 class="font-semibold text-gray-900 text-sm mb-4">PAYMENT DISTRIBUTION</h4>
            <div class="space-y-3">
              <div v-for="pm in [{name:'Credit Card', pct:'45%', color:'bg-[#1E293B]'},{name:'e-Wallet (QR)', pct:'35%', color:'bg-blue-500'},{name:'Cash', pct:'20%', color:'bg-green-500'}]" :key="pm.name" class="flex items-center justify-between">
                <div class="flex items-center gap-2">
                  <span :class="[pm.color, 'w-6 h-2 rounded-full']"></span>
                  <span class="text-sm text-gray-600">{{ pm.name }}</span>
                </div>
                <span class="font-semibold text-gray-900">{{ pm.pct }}</span>
              </div>
            </div>
          </div>

          <!-- Labor Cost -->
          <div class="border border-gray-100 rounded-lg p-4 flex flex-col items-center justify-center">
            <h4 class="font-semibold text-gray-900 text-sm mb-3">LABOR COST %</h4>
            <div class="w-24 h-24 rounded-full border-8 border-orange-400 border-t-gray-200 flex items-center justify-center">
              <span class="text-xl font-bold text-gray-900">28%</span>
            </div>
            <p class="text-xs text-gray-500 mt-2">Target: &lt; 30%</p>
            <p class="text-xs text-green-600 font-medium">Optimal Range</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
