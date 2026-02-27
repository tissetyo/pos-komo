<script setup lang="ts">
definePageMeta({ layout: 'backoffice' })

const salesData = [
  { item: 'Komo Signature Iced Coffee', category: 'Signature', sold: 1245, revenue: 34860000 },
  { item: 'Butter Croissant', category: 'Pastry', sold: 890, revenue: 17800000 },
  { item: 'Hot Cafe Latte', category: 'Coffee', sold: 756, revenue: 18900000 },
  { item: 'Iced Matcha Latte', category: 'Non-Coffee', sold: 612, revenue: 18360000 },
  { item: 'Brownie Bites', category: 'Snacks', sold: 450, revenue: 8100000 },
]
</script>

<template>
  <div class="space-y-6">
    <div class="flex justify-between items-end">
      <div>
        <h2 class="text-2xl font-bold text-gray-900">Sales Report</h2>
        <p class="text-gray-500 text-sm mt-1">Detailed performance of your products.</p>
      </div>
      <div class="flex gap-3">
        <USelectMenu placeholder="This Month" :options="['Today', 'This Week', 'This Month', 'Last Month', 'Custom Range']" class="w-40" />
        <UButton color="white" label="Export CSV" icon="i-lucide-download" />
      </div>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-4 gap-6">
      <div class="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 flex flex-col justify-between">
        <div class="text-gray-500 text-sm font-medium mb-2">Net Sales</div>
        <div class="text-3xl font-bold text-gray-900">Rp 98.020.000</div>
        <div class="text-sm text-green-600 mt-2 flex items-center gap-1 font-medium"><UIcon name="i-lucide-trending-up" class="w-4 h-4" /> +14.5%</div>
      </div>
      <div class="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 flex flex-col justify-between">
        <div class="text-gray-500 text-sm font-medium mb-2">Gross Profit</div>
        <div class="text-3xl font-bold text-gray-900">Rp 64.150.000</div>
        <div class="text-sm text-green-600 mt-2 flex items-center gap-1 font-medium"><UIcon name="i-lucide-trending-up" class="w-4 h-4" /> +12.1%</div>
      </div>
       <div class="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 flex flex-col justify-between">
        <div class="text-gray-500 text-sm font-medium mb-2">Total Transactions</div>
        <div class="text-3xl font-bold text-gray-900">4,251</div>
        <div class="text-sm text-green-600 mt-2 flex items-center gap-1 font-medium"><UIcon name="i-lucide-trending-up" class="w-4 h-4" /> +8.4%</div>
      </div>
       <div class="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 flex flex-col justify-between">
        <div class="text-gray-500 text-sm font-medium mb-2">Avg. Ticket Size</div>
        <div class="text-3xl font-bold text-gray-900">Rp 23.058</div>
        <div class="text-sm text-red-600 mt-2 flex items-center gap-1 font-medium"><UIcon name="i-lucide-trending-down" class="w-4 h-4" /> -1.2%</div>
      </div>
    </div>

    <div class="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
      <div class="px-6 py-5 border-b border-gray-100 flex justify-between items-center">
        <h3 class="font-semibold text-gray-900 text-lg">Top Selling Items</h3>
      </div>
      <div class="overflow-x-auto">
        <table class="w-full text-left text-sm text-gray-600">
          <thead class="bg-gray-50/50 text-gray-500 font-medium">
            <tr>
              <th class="py-4 px-6 font-medium">Item Name</th>
              <th class="py-4 px-6 font-medium">Category</th>
              <th class="py-4 px-6 font-medium text-right">Items Sold</th>
              <th class="py-4 px-6 font-medium text-right">Revenue</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-100">
            <tr v-for="item in salesData" :key="item.item" class="hover:bg-gray-50/50 transition-colors">
              <td class="py-4 px-6 font-medium text-gray-900">{{ item.item }}</td>
              <td class="py-4 px-6">
                 <UBadge color="gray" variant="soft">{{ item.category }}</UBadge>
              </td>
              <td class="py-4 px-6 text-right font-medium">{{ item.sold.toLocaleString() }}</td>
              <td class="py-4 px-6 text-right font-semibold text-gray-900 whitespace-nowrap">Rp {{ item.revenue.toLocaleString('id-ID') }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

  </div>
</template>
