<script setup lang="ts">
definePageMeta({ layout: 'backoffice' })

const client = useSupabaseClient()
const user = useSupabaseUser()
const loading = ref(true)

const netSales = ref(0)
const totalTx = ref(0)
const avgTicket = ref(0)
const topItems = ref<any[]>([])

onMounted(async () => {
  if (!user.value) return
  try {
    const { data: profile } = await client.from('profiles').select('outlet_id').eq('id', user.value.id).single()
    if (!profile?.outlet_id) return

    // Aggregate from orders
    const { data: orders } = await client
      .from('orders')
      .select('total')
      .eq('outlet_id', profile.outlet_id)
      .eq('payment_status', 'paid')

    if (orders && orders.length > 0) {
      netSales.value = orders.reduce((sum: number, o: any) => sum + (o.total || 0), 0)
      totalTx.value = orders.length
      avgTicket.value = Math.round(netSales.value / totalTx.value)
    }

    // Aggregate top items from order_items
    const { data: items } = await client
      .from('order_items')
      .select('product_id, quantity, total_price, products(name, categories(name))')
      .order('total_price', { ascending: false })
      .limit(100)

    if (items && items.length > 0) {
      const grouped: Record<string, { name: string; category: string; sold: number; revenue: number }> = {}
      for (const item of items) {
        const pid = item.product_id
        if (!grouped[pid]) {
          grouped[pid] = {
            name: (item as any).products?.name || 'Unknown',
            category: (item as any).products?.categories?.name || '-',
            sold: 0,
            revenue: 0
          }
        }
        grouped[pid].sold += item.quantity
        grouped[pid].revenue += item.total_price
      }
      topItems.value = Object.values(grouped).sort((a, b) => b.revenue - a.revenue).slice(0, 5)
    }
  } finally {
    loading.value = false
  }
})

const formatRp = (n: number) => 'Rp ' + n.toLocaleString('id-ID')
</script>

<template>
  <div class="space-y-6">
    <div class="flex justify-between items-end">
      <div>
        <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Sales Report</h2>
        <p class="text-gray-500 dark:text-gray-400 text-sm mt-1">Detailed performance of your products.</p>
      </div>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
      <div class="bg-white dark:bg-gray-900 rounded-2xl shadow-sm border border-gray-100 dark:border-gray-800 p-6">
        <div class="text-gray-500 dark:text-gray-400 text-sm font-medium mb-2">Net Sales</div>
        <div class="text-3xl font-bold text-gray-900 dark:text-white">{{ formatRp(netSales) }}</div>
      </div>
      <div class="bg-white dark:bg-gray-900 rounded-2xl shadow-sm border border-gray-100 dark:border-gray-800 p-6">
        <div class="text-gray-500 dark:text-gray-400 text-sm font-medium mb-2">Total Transactions</div>
        <div class="text-3xl font-bold text-gray-900 dark:text-white">{{ totalTx.toLocaleString() }}</div>
      </div>
      <div class="bg-white dark:bg-gray-900 rounded-2xl shadow-sm border border-gray-100 dark:border-gray-800 p-6">
        <div class="text-gray-500 dark:text-gray-400 text-sm font-medium mb-2">Avg. Ticket Size</div>
        <div class="text-3xl font-bold text-gray-900 dark:text-white">{{ formatRp(avgTicket) }}</div>
      </div>
    </div>

    <div class="bg-white dark:bg-gray-900 rounded-2xl shadow-sm border border-gray-100 dark:border-gray-800 overflow-hidden">
      <div class="px-6 py-5 border-b border-gray-100 dark:border-gray-800">
        <h3 class="font-semibold text-gray-900 dark:text-white text-lg">Top Selling Items</h3>
      </div>

      <div v-if="!loading && topItems.length === 0" class="p-12 text-center text-gray-400 dark:text-gray-500">
        <UIcon name="i-lucide-bar-chart-3" class="w-10 h-10 mx-auto mb-3 opacity-40" />
        <p class="text-sm">No sales data yet. Complete some orders first.</p>
      </div>

      <div v-else class="overflow-x-auto">
        <table class="w-full text-left text-sm text-gray-600 dark:text-gray-400">
          <thead class="bg-gray-50/50 dark:bg-gray-800/50 text-gray-500 dark:text-gray-400 font-medium">
            <tr>
              <th class="py-4 px-6 font-medium">Item Name</th>
              <th class="py-4 px-6 font-medium">Category</th>
              <th class="py-4 px-6 font-medium text-right">Items Sold</th>
              <th class="py-4 px-6 font-medium text-right">Revenue</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-100 dark:divide-gray-800">
            <tr v-for="item in topItems" :key="item.name" class="hover:bg-gray-50/50 dark:hover:bg-gray-800/50 transition-colors">
              <td class="py-4 px-6 font-medium text-gray-900 dark:text-white">{{ item.name }}</td>
              <td class="py-4 px-6">
                 <UBadge color="neutral" variant="soft">{{ item.category }}</UBadge>
              </td>
              <td class="py-4 px-6 text-right font-medium">{{ item.sold.toLocaleString() }}</td>
              <td class="py-4 px-6 text-right font-semibold text-gray-900 dark:text-white whitespace-nowrap">{{ formatRp(item.revenue) }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>
