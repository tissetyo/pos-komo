<script setup lang="ts">
definePageMeta({
  layout: 'backoffice'
})

const client = useSupabaseClient()
const user = useSupabaseUser()
const dateRange = ref('Today')

const metrics = ref([
  { label: 'Total Sales', value: 'RM 8,175.88', trend: '-3.15%', trendDir: 'down', change: '(-RM 265.99)', sub: 'Sales Report', icon: 'i-lucide-dollar-sign', iconBg: 'bg-blue-50', iconColor: 'text-blue-600' },
  { label: 'Total New Customers', value: '19', trend: '+5.56%', trendDir: 'up', change: '(+1)', sub: 'Loyalty Report', icon: 'i-lucide-user-plus', iconBg: 'bg-emerald-50', iconColor: 'text-emerald-600' },
  { label: 'Total Transactions', value: '429', trend: '-13.51%', trendDir: 'down', change: '(-67)', sub: '', icon: 'i-lucide-receipt', iconBg: 'bg-purple-50', iconColor: 'text-purple-600' },
  { label: 'Avg. Order Value', value: 'RM 19.06', trend: '+11.97%', trendDir: 'up', change: '(+RM 2.04)', sub: '', icon: 'i-lucide-calculator', iconBg: 'bg-orange-50', iconColor: 'text-orange-600' }
])

const loadingMetrics = ref(true)
const recentTransactions = ref<any[]>([])

const storeChannels = ref([
  { name: 'Main Street Cafe', offline: 'RM 4,230.50', qr: 'RM 850.00', total: 'RM 5,080.50' },
  { name: 'Downtown Kiosk', offline: 'RM 1,230.50', qr: 'RM 250.00', total: 'RM 5,080.50' },
  { name: 'Mall Branch', offline: 'RM 1,230.50', qr: 'RM 250.00', total: 'RM 5,080.50' },
])

const bestSellers = ref([
  { name: 'Signature Latte', category: 'Beverages', sold: 142, trend: '+12% vs last week', color: 'bg-red-100 text-red-600' },
  { name: 'Croissant Butter', category: 'Pastry', sold: 98, trend: '+5% vs last week', color: 'bg-amber-100 text-amber-600' },
  { name: 'Chicken Sandwich', category: 'Food', sold: 76, trend: '-2% vs last week', color: 'bg-green-100 text-green-600' },
])

onMounted(async () => {
  // Load real data if available
  if (!user.value) { loadingMetrics.value = false; return }
  try {
    const { data: profile } = await client.from('profiles').select('outlet_id').eq('id', user.value.id).single()
    if (!profile?.outlet_id) return

    const { data: orders } = await client
      .from('orders')
      .select('id, total, payment_method, payment_status, order_status, created_at, receipt_number')
      .eq('outlet_id', profile.outlet_id)
      .eq('payment_status', 'paid')
      .order('created_at', { ascending: false })

    if (orders && orders.length > 0) {
      const totalRevenue = orders.reduce((sum: number, o: any) => sum + (o.total || 0), 0)
      metrics.value[0].value = 'RM ' + totalRevenue.toLocaleString('en-MY', { minimumFractionDigits: 2 })
      metrics.value[2].value = orders.length.toString()
      const avg = Math.round((totalRevenue / orders.length) * 100) / 100
      metrics.value[3].value = 'RM ' + avg.toLocaleString('en-MY', { minimumFractionDigits: 2 })
    }
  } finally {
    loadingMetrics.value = false
  }
})
</script>

<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex justify-between items-start">
      <h2 class="text-2xl font-bold text-gray-900">Welcome Back !</h2>
      <div class="flex items-center gap-1">
        <button
          v-for="range in ['Today', 'This Week', 'This Month']"
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

    <!-- 4 Stat Cards -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-5">
      <div v-for="m in metrics" :key="m.label" class="bg-white rounded-xl p-5 border border-gray-100 shadow-sm hover:shadow-md transition-shadow">
        <div class="flex items-start justify-between mb-3">
          <p class="text-sm text-gray-500 font-medium">{{ m.label }}</p>
          <UIcon name="i-lucide-info" class="w-4 h-4 text-gray-300" />
        </div>
        <p v-if="loadingMetrics" class="text-2xl font-bold text-gray-300 animate-pulse">---</p>
        <p v-else class="text-2xl font-bold text-gray-900">{{ m.value }}</p>
        <div class="flex items-center gap-2 mt-2">
          <span
            :class="[
              'text-xs font-semibold px-2 py-0.5 rounded-full',
              m.trendDir === 'up' ? 'bg-green-50 text-green-600' : 'bg-red-50 text-red-600'
            ]"
          >
            {{ m.trendDir === 'up' ? '↗' : '↘' }} {{ m.trend }}
          </span>
          <span class="text-xs text-gray-400">{{ m.change }}</span>
        </div>
        <p v-if="m.sub" class="text-xs text-primary mt-2 cursor-pointer hover:underline">{{ m.sub }}</p>
      </div>
    </div>

    <!-- Charts Row -->
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
      <!-- Accumulative Sales Chart -->
      <div class="lg:col-span-2 bg-white rounded-xl border border-gray-100 shadow-sm p-6">
        <h3 class="font-semibold text-gray-900 text-lg mb-1">Total Accumulative Sales <span class="text-gray-400 text-sm font-normal">(RM)</span></h3>
        <div class="h-[300px] flex items-center justify-center border-2 border-dashed border-gray-200 rounded-lg bg-gray-50 text-gray-400 mt-4">
          <div class="text-center">
            <UIcon name="i-lucide-line-chart" class="w-8 h-8 mx-auto mb-2 opacity-50" />
            <p class="text-sm">Sales chart will render with real data</p>
            <div class="flex gap-4 justify-center mt-3">
              <span class="flex items-center gap-1.5 text-xs"><span class="w-3 h-3 rounded-full bg-blue-600 inline-block"></span> Yesterday</span>
              <span class="flex items-center gap-1.5 text-xs"><span class="w-3 h-3 rounded-full bg-orange-500 inline-block"></span> Today</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Sales by Channels -->
      <div class="bg-white rounded-xl border border-gray-100 shadow-sm p-6">
        <h3 class="font-semibold text-gray-900 text-lg mb-4">Total Sales by Channels</h3>
        <div class="flex flex-col items-center justify-center h-[200px]">
          <!-- Donut placeholder -->
          <div class="w-36 h-36 rounded-full border-[20px] border-[#1E293B] border-t-blue-300 flex items-center justify-center">
          </div>
        </div>
        <div class="flex justify-center gap-8 mt-4">
          <div class="text-center">
            <div class="flex items-center gap-1.5 mb-1"><span class="w-3 h-1 bg-[#1E293B] rounded-full inline-block"></span></div>
            <p class="text-xl font-bold text-gray-900">82.74%</p>
            <p class="text-xs text-gray-500">Offline ⓘ</p>
            <p class="text-xs text-gray-400">RM 6,764.88</p>
          </div>
          <div class="text-center">
            <div class="flex items-center gap-1.5 mb-1"><span class="w-3 h-1 bg-blue-300 rounded-full inline-block"></span></div>
            <p class="text-xl font-bold text-gray-900">17.26%</p>
            <p class="text-xs text-gray-500">QR Order and Pay ⓘ</p>
            <p class="text-xs text-gray-400">RM 1,411.00</p>
          </div>
        </div>
      </div>
    </div>

    <!-- Bottom Row -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <!-- Sales per Store with Channel -->
      <div class="bg-white rounded-xl border border-gray-100 shadow-sm">
        <div class="flex justify-between items-center px-6 py-4 border-b border-gray-100">
          <h3 class="font-semibold text-gray-900">Sales per Store with Channel</h3>
          <button class="text-sm text-primary hover:underline">View All</button>
        </div>
        <table class="w-full text-sm">
          <thead>
            <tr class="text-gray-500 text-xs uppercase tracking-wider">
              <th class="text-left py-3 px-6 font-medium">Store Name</th>
              <th class="text-left py-3 px-6 font-medium">Offline</th>
              <th class="text-left py-3 px-6 font-medium">QR Order</th>
              <th class="text-left py-3 px-6 font-medium">Total</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-50">
            <tr v-for="store in storeChannels" :key="store.name" class="hover:bg-gray-50 transition-colors">
              <td class="py-4 px-6 font-medium text-gray-900">{{ store.name }}</td>
              <td class="py-4 px-6 text-gray-600">{{ store.offline }}</td>
              <td class="py-4 px-6 text-gray-600">{{ store.qr }}</td>
              <td class="py-4 px-6 font-bold text-gray-900">{{ store.total }}</td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Best Selling Products -->
      <div class="bg-white rounded-xl border border-gray-100 shadow-sm">
        <div class="flex justify-between items-center px-6 py-4 border-b border-gray-100">
          <h3 class="font-semibold text-gray-900">Best Selling Products</h3>
          <div class="flex items-center gap-1 text-sm text-gray-500 border border-gray-200 px-3 py-1.5 rounded-lg">
            By Qty <UIcon name="i-lucide-chevron-down" class="w-4 h-4" />
          </div>
        </div>
        <div class="divide-y divide-gray-50">
          <div v-for="(item, i) in bestSellers" :key="item.name" class="flex items-center gap-4 px-6 py-4 hover:bg-gray-50 transition-colors">
            <div :class="[item.color, 'w-10 h-10 rounded-lg flex items-center justify-center flex-shrink-0']">
              <UIcon name="i-lucide-coffee" class="w-5 h-5" />
            </div>
            <div class="flex-1 min-w-0">
              <p class="font-medium text-gray-900">{{ item.name }}</p>
              <p class="text-xs text-gray-500">{{ item.category }}</p>
            </div>
            <div class="text-right">
              <p class="font-bold text-gray-900">{{ item.sold }} sold</p>
              <p class="text-xs" :class="item.trend.startsWith('+') ? 'text-green-600' : 'text-red-500'">{{ item.trend }}</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
