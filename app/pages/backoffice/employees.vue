<script setup lang="ts">
definePageMeta({ layout: 'backoffice' })

const employees = [
  { id: 'EMP-001', name: 'Rina Wijaya', role: 'Kasir', outlet: 'Central Park', status: 'Active', joined: '12 Jan 2025' },
  { id: 'EMP-002', name: 'Andi Pratama', role: 'Dapur', outlet: 'Central Park', status: 'Active', joined: '15 Jan 2025' },
  { id: 'EMP-003', name: 'Siska Lestari', role: 'Manager', outlet: 'Mall Kelapa Gading', status: 'Active', joined: '01 Feb 2025' },
  { id: 'EMP-004', name: 'Bimo Aryo', role: 'Kasir', outlet: 'Senayan City', status: 'Inactive', joined: '10 Feb 2025' },
  { id: 'EMP-005', name: 'Tono Subagyo', role: 'Dapur', outlet: 'Senayan City', status: 'Active', joined: '20 Feb 2025' },
]

const columns = [
  { id: 'name', key: 'name', label: 'Employee' },
  { id: 'role', key: 'role', label: 'Role & Outlet' },
  { id: 'status', key: 'status', label: 'Status' },
  { id: 'joined', key: 'joined', label: 'Date Joined' },
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
        <h2 class="text-2xl font-bold text-gray-900">Employee Management</h2>
        <p class="text-gray-500 text-sm mt-1">Manage staff roles, access, and see performance overview.</p>
      </div>
      <UButton color="primary" label="Add Employee" icon="i-lucide-user-plus" />
    </div>

    <!-- Filters & Search -->
    <div class="bg-white p-4 justify-between flex items-center rounded-2xl shadow-sm border border-gray-100">
       <UInput v-model="search" icon="i-lucide-search" placeholder="Search employee..." class="w-72" />
       <div class="flex gap-2 text-sm text-gray-600">
         <USelectMenu placeholder="All Roles" :options="['Kasir', 'Manager', 'Dapur']" class="w-40" />
         <USelectMenu placeholder="All Outlets" :options="['Central Park', 'Mall Kelapa Gading', 'Senayan City']" class="w-40" />
       </div>
    </div>

    <!-- Data Table -->
    <div class="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
      <UTable :rows="employees" :columns="columns" :ui="{ td: { padding: 'py-4 px-6' }, th: { padding: 'py-4 px-6 text-gray-500 font-medium bg-gray-50/50' } }">
        <template #name-data="{ row }">
          <div class="flex items-center gap-3">
            <UAvatar :alt="row.name" size="sm" :ui="{ background: 'bg-indigo-100 dark:bg-indigo-900', text: 'text-indigo-600 dark:text-indigo-400' }" />
            <div>
              <p class="font-medium text-gray-900">{{ row.name }}</p>
              <p class="text-xs text-gray-500">ID: {{ row.id }}</p>
            </div>
          </div>
        </template>
        
        <template #role-data="{ row }">
          <div>
            <p class="text-sm font-medium text-gray-900">{{ row.role }}</p>
            <p class="text-xs text-gray-500 flex items-center gap-1 mt-0.5">
               <UIcon name="i-lucide-map-pin" class="w-3 h-3" /> {{ row.outlet }}
            </p>
          </div>
        </template>
        
        <template #status-data="{ row }">
          <UBadge :color="row.status === 'Active' ? 'green' : 'gray'" variant="soft" class="px-2.5 py-1 rounded-full text-xs font-medium">
            {{ row.status }}
          </UBadge>
        </template>
        
        <template #joined-data="{ row }">
          <span class="text-sm text-gray-600">
            {{ row.joined }}
          </span>
        </template>

        <template #actions-data="{ row }">
          <div class="flex justify-end gap-2 pr-4 text-gray-400">
             <UButton color="gray" variant="ghost" icon="i-lucide-edit" size="xs" />
             <UButton color="red" variant="ghost" icon="i-lucide-trash-2" size="xs" />
          </div>
        </template>
      </UTable>
    </div>
  </div>
</template>
