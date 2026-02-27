<script setup lang="ts">
definePageMeta({ layout: 'backoffice' })

const transactions = [
  { id: 'TRX-10145', date: '27 Feb 2026, 14:30', outlet: 'Central Park', cashier: 'Rina Wijaya', status: 'Completed', method: 'QRIS', total: 125000 },
  { id: 'TRX-10144', date: '27 Feb 2026, 14:15', outlet: 'Central Park', cashier: 'Rina Wijaya', status: 'Completed', method: 'EDC', total: 85000 },
  { id: 'TRX-10143', date: '27 Feb 2026, 13:50', outlet: 'Central Park', cashier: 'Rina Wijaya', status: 'Voided', method: 'Cash', total: 45000 },
  { id: 'TRX-10142', date: '27 Feb 2026, 13:20', outlet: 'Central Park', cashier: 'Rina Wijaya', status: 'Completed', method: 'QRIS', total: 210000 },
  { id: 'TRX-10141', date: '27 Feb 2026, 13:05', outlet: 'Central Park', cashier: 'Rina Wijaya', status: 'Completed', method: 'Cash', total: 35000 },
]

const columns = [
  { id: 'id', key: 'id', label: 'Transaction ID' },
  { id: 'details', key: 'details', label: 'Date & Location' },
  { id: 'status', key: 'status', label: 'Status' },
  { id: 'payment', key: 'payment', label: 'Payment' },
  { id: 'total', key: 'total', label: 'Total Amount' },
  { id: 'actions', key: 'actions', label: '' }
]

const search = ref('')
</script>

<template>
  <div class="space-y-6">
    <div class="flex justify-between items-end">
      <div>
        <h2 class="text-2xl font-bold text-gray-900">Transactions History</h2>
        <p class="text-gray-500 text-sm mt-1">Review past orders, reprints receipts, and handle voids.</p>
      </div>
      <UButton color="white" label="Export Data" icon="i-lucide-download" />
    </div>

    <!-- Filters & Search -->
    <div class="bg-white p-4 justify-between flex flex-col md:flex-row gap-4 items-center rounded-2xl shadow-sm border border-gray-100">
       <UInput v-model="search" icon="i-lucide-search" placeholder="Search by TRX ID..." class="w-full md:w-80" />
       <div class="flex flex-wrap gap-2 text-sm text-gray-600 w-full md:w-auto">
         <USelectMenu placeholder="All Status" :options="['Completed', 'Voided', 'Pending']" class="w-36" />
         <USelectMenu placeholder="All Payment Types" :options="['QRIS', 'EDC', 'Cash']" class="w-44" />
         <UInput type="date" class="w-40" />
       </div>
    </div>

    <!-- Data Table -->
    <div class="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
      <UTable :rows="transactions" :columns="columns" :ui="{ td: { padding: 'py-4 px-6' }, th: { padding: 'py-4 px-6 text-gray-500 font-medium bg-gray-50/50' } }">
        <template #id-data="{ row }">
          <p class="font-semibold text-primary-600 cursor-pointer hover:underline">{{ row.id }}</p>
        </template>
        
        <template #details-data="{ row }">
          <div>
            <p class="text-sm font-medium text-gray-900">{{ row.date }}</p>
            <p class="text-xs text-gray-500">{{ row.outlet }} • {{ row.cashier }}</p>
          </div>
        </template>
        
        <template #status-data="{ row }">
          <UBadge :color="row.status === 'Completed' ? 'green' : (row.status === 'Voided' ? 'red' : 'orange')" variant="soft" class="px-2.5 py-1 rounded-full text-xs font-medium">
            {{ row.status }}
          </UBadge>
        </template>

        <template #payment-data="{ row }">
           <div class="flex items-center gap-2 text-sm text-gray-600">
             <UIcon :name="row.method === 'Cash' ? 'i-lucide-banknote' : (row.method === 'QRIS' ? 'i-lucide-qr-code' : 'i-lucide-credit-card')" class="w-4 h-4 text-gray-400" />
             {{ row.method }}
           </div>
        </template>
        
        <template #total-data="{ row }">
          <span class="font-bold text-gray-900">
            Rp {{ row.total.toLocaleString('id-ID') }}
          </span>
        </template>

        <template #actions-data="{ row }">
          <div class="flex justify-end pr-4 text-gray-400">
             <UButton color="gray" variant="ghost" icon="i-lucide-printer" size="xs" tooltip="Reprint Receipt" />
          </div>
        </template>
      </UTable>
    </div>
  </div>
</template>
