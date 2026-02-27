<script setup lang="ts">
definePageMeta({ layout: 'backoffice' })

const customers = [
  { id: 'CUST-001', name: 'Budi Santoso', phone: '081234567890', email: 'budi@example.com', totalOrders: 14, totalSpent: 1850000, lastVisit: '10 mins ago' },
  { id: 'CUST-002', name: 'Siti Aminah', phone: '085711223344', email: 'siti@example.com', totalOrders: 5, totalSpent: 420000, lastVisit: '2 days ago' },
  { id: 'CUST-003', name: 'Agus Pratama', phone: '081399887766', email: 'agus@example.com', totalOrders: 28, totalSpent: 3500000, lastVisit: '1 hour ago' },
  { id: 'CUST-004', name: 'Dewi Lestari', phone: '089655443322', email: 'dewi@example.com', totalOrders: 2, totalSpent: 150000, lastVisit: 'Last week' },
  { id: 'CUST-005', name: 'Joko Widodo', phone: '081122334455', email: 'joko@example.com', totalOrders: 42, totalSpent: 5200000, lastVisit: 'Yesterday' }
]

const columns = [
  { id: 'name', key: 'name', label: 'Name' },
  { id: 'contact', key: 'contact', label: 'Contact Info' },
  { id: 'stats', key: 'stats', label: 'Order History' },
  { id: 'lastVisit', key: 'lastVisit', label: 'Last Visit' },
  { id: 'actions', key: 'actions', label: '' }
]

const search = ref('')
const page = ref(1)
const itemsPerPage = 10
</script>

<template>
  <div class="space-y-6">
    <div class="flex justify-between items-end">
      <div>
        <h2 class="text-2xl font-bold text-gray-900">Customers Directory</h2>
        <p class="text-gray-500 text-sm mt-1">Manage and view your customer history.</p>
      </div>
      <UButton color="primary" label="Add Customer" icon="i-lucide-user-plus" />
    </div>

    <!-- Filters & Search -->
    <div class="bg-white p-4 justify-between flex items-center rounded-2xl shadow-sm border border-gray-100">
       <UInput v-model="search" icon="i-lucide-search" placeholder="Search by name or phone..." class="w-72" />
       <div class="flex gap-2 text-sm text-gray-600">
         <UButton color="gray" variant="ghost" icon="i-lucide-filter" label="Filter" />
         <UButton color="gray" variant="ghost" icon="i-lucide-arrow-down-up" label="Sort" />
       </div>
    </div>

    <!-- Data Table -->
    <div class="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
      <UTable :rows="customers" :columns="columns" :ui="{ td: { padding: 'py-4 px-6' }, th: { padding: 'py-4 px-6 text-gray-500 font-medium bg-gray-50/50' } }">
        <template #name-data="{ row }">
          <div class="flex items-center gap-3">
            <UAvatar :alt="row.name" size="sm" :ui="{ background: 'bg-primary-100 dark:bg-primary-900', text: 'text-primary-600 dark:text-primary-400' }" />
            <div>
              <p class="font-medium text-gray-900">{{ row.name }}</p>
              <p class="text-xs text-gray-500">ID: {{ row.id }}</p>
            </div>
          </div>
        </template>
        
        <template #contact-data="{ row }">
          <div>
            <p class="text-sm text-gray-900">{{ row.phone }}</p>
            <p class="text-xs text-gray-500">{{ row.email }}</p>
          </div>
        </template>
        
        <template #stats-data="{ row }">
          <div>
            <p class="text-sm font-medium text-gray-900">{{ row.totalOrders }} orders</p>
            <p class="text-xs text-gray-500">Rp {{ row.totalSpent.toLocaleString('id-ID') }} total</p>
          </div>
        </template>
        
        <template #lastVisit-data="{ row }">
          <span class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-800">
            {{ row.lastVisit }}
          </span>
        </template>

        <template #actions-data="{ row }">
          <div class="flex justify-end pr-4">
             <UButton color="gray" variant="ghost" icon="i-lucide-more-horizontal" />
          </div>
        </template>
      </UTable>

      <div class="flex justify-between items-center px-6 py-4 border-t border-gray-100 bg-gray-50/50">
        <span class="text-sm text-gray-500">Showing 1 to 5 of 5 customers</span>
        <UPagination v-model="page" :page-count="itemsPerPage" :total="customers.length" />
      </div>
    </div>
  </div>
</template>
