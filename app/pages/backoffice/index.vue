<script setup lang="ts">
definePageMeta({
  layout: 'backoffice'
})

// Analytics data (Mocked)
const metrics = [
  { label: 'Total Revenue', value: 'Rp 14.500.000', trend: '+12%', icon: 'i-lucide-banknote', color: 'text-green-600', bg: 'bg-green-100' },
  { label: 'Total Orders', value: '342', trend: '+5%', icon: 'i-lucide-receipt', color: 'text-blue-600', bg: 'bg-blue-100' },
  { label: 'Avg. Order Value', value: 'Rp 42.397', trend: '-2%', icon: 'i-lucide-calculator', color: 'text-orange-600', bg: 'bg-orange-100' },
]

const recentTransactions = [
  { id: 'TRX-001', time: '10:42', customer: 'Walk-in', amount: 85000, status: 'Completed', method: 'QRIS' },
  { id: 'TRX-002', time: '10:55', customer: 'Budi (Table 4)', amount: 120000, status: 'Completed', method: 'EDC' },
  { id: 'TRX-003', time: '11:15', customer: 'Walk-in', amount: 45000, status: 'Pending', method: 'Cash' },
  { id: 'TRX-004', time: '11:30', customer: 'Walk-in', amount: 32000, status: 'Completed', method: 'QRIS' },
]

const columns = [
  { key: 'id', label: 'Order ID' },
  { key: 'time', label: 'Time' },
  { key: 'customer', label: 'Customer' },
  { key: 'amount', label: 'Total' },
  { key: 'method', label: 'Payment' },
  { key: 'status', label: 'Status' }
]
</script>

<template>
  <div class="space-y-6">
    <div class="flex justify-between items-end">
      <div>
        <h2 class="text-2xl font-bold text-gray-900">Dashboard Overview</h2>
        <p class="text-gray-500 text-sm mt-1">Here's what's happening at your stores today.</p>
      </div>
      <div class="flex gap-2">
        <UButton color="white" label="Export" icon="i-lucide-download" />
        <UButton color="primary" label="New Report" icon="i-lucide-plus" />
      </div>
    </div>

    <!-- Metrik Cards -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
      <div v-for="metric in metrics" :key="metric.label" class="bg-white rounded-2xl p-6 shadow-sm border border-gray-100 flex items-start gap-4 hover:shadow-md transition-shadow">
        <div :class="[metric.bg, metric.color, 'p-3 rounded-xl']">
          <UIcon :name="metric.icon" class="w-6 h-6" />
        </div>
        <div>
          <p class="text-sm font-medium text-gray-500">{{ metric.label }}</p>
          <div class="flex items-end gap-2 mt-1">
            <p class="text-2xl font-bold text-gray-900">{{ metric.value }}</p>
            <span :class="['text-xs font-medium mb-1', metric.trend.startsWith('+') ? 'text-green-600' : 'text-red-600']">
              {{ metric.trend }}
            </span>
          </div>
        </div>
      </div>
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
      <!-- Chart Area Placeholder -->
      <div class="lg:col-span-2 bg-white rounded-2xl shadow-sm border border-gray-100 p-6 flex flex-col">
        <div class="flex justify-between mb-6">
          <h3 class="font-semibold text-gray-900 text-lg">Revenue Trend</h3>
          <USelectMenu :options="['Today', 'This Week', 'This Month']" placeholder="Today" />
        </div>
        <div class="flex-1 min-h-[300px] flex items-center justify-center border-2 border-dashed border-gray-200 rounded-xl bg-gray-50 text-gray-400">
          <div class="text-center">
            <UIcon name="i-lucide-bar-chart-3" class="w-8 h-8 mx-auto mb-2 opacity-50" />
            <p>Chart Component Ready</p>
          </div>
        </div>
      </div>

      <!-- Live / Recent Transactions -->
      <div class="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 flex flex-col">
        <div class="flex justify-between mb-4">
          <h3 class="font-semibold text-gray-900 text-lg">Recent Orders</h3>
          <UButton color="gray" variant="ghost" icon="i-lucide-arrow-right" class="-mr-2" />
        </div>
        
        <div class="space-y-4 flex-1 overflow-y-auto pr-2">
          <div v-for="tx in recentTransactions" :key="tx.id" class="flex items-center justify-between pb-4 border-b border-gray-50 last:border-0 last:pb-0">
            <div class="flex items-center gap-3">
              <div :class="['w-10 h-10 rounded-full flex items-center justify-center flex-shrink-0', tx.status === 'Completed' ? 'bg-green-100 text-green-600' : 'bg-orange-100 text-orange-600']">
                <UIcon :name="tx.status === 'Completed' ? 'i-lucide-check' : 'i-lucide-clock'" class="w-5 h-5" />
              </div>
              <div>
                <p class="text-sm font-medium text-gray-900">{{ tx.id }}</p>
                <p class="text-xs text-gray-500">{{ tx.customer }} • {{ tx.time }}</p>
              </div>
            </div>
            <div class="text-right">
              <p class="text-sm font-semibold text-gray-900">Rp {{ tx.amount.toLocaleString('id-ID') }}</p>
              <UBadge :color="tx.method === 'QRIS' ? 'blue' : (tx.method === 'EDC' ? 'purple' : 'gray')" variant="soft" size="xs">
                {{ tx.method }}
              </UBadge>
            </div>
          </div>
        </div>
      </div>
    </div>
    
  </div>
</template>
