<script setup lang="ts">
definePageMeta({ layout: 'backoffice' })

const { client, outletId, profileReady } = useUserProfile()
const customers = ref<any[]>([])
const loading = ref(true)
const search = ref('')

const isAddOpen = ref(false)
const editingCustomer = ref<any>(null)
const newCustomer = ref({ name: '', phone: '', email: '', address: '' })
const saving = ref(false)

const currentPage = ref(1)
const perPage = 10

// Real stats
const totalCustomers = ref(0)
const newThisMonth = ref(0)

const fetchCustomers = async () => {
  loading.value = true
  try {
    if (!outletId.value) return

    const { data } = await client
      .from('customers')
      .select('*')
      .eq('outlet_id', outletId.value)
      .order('created_at', { ascending: false })

    customers.value = (data || []).map((c: any) => ({
      ...c,
      initials: (c.name || 'U').substring(0, 2).toUpperCase(),
      initialColor: ['bg-blue-100 text-blue-600', 'bg-red-100 text-red-600', 'bg-green-100 text-green-600', 'bg-purple-100 text-purple-600'][Math.floor(Math.random() * 4)],
      joinedDate: new Date(c.created_at).toLocaleDateString('en-MY', { day: '2-digit', month: 'short', year: 'numeric' })
    }))

    totalCustomers.value = customers.value.length

    // Count new this month
    const startOfMonth = new Date()
    startOfMonth.setDate(1)
    startOfMonth.setHours(0, 0, 0, 0)
    newThisMonth.value = customers.value.filter(c => new Date(c.created_at) >= startOfMonth).length
  } finally {
    loading.value = false
  }
}

watch(profileReady, (ready) => { if (ready) fetchCustomers() })

const filteredCustomers = computed(() => {
  if (!search.value) return customers.value
  const q = search.value.toLowerCase()
  return customers.value.filter(c =>
    c.name.toLowerCase().includes(q) ||
    (c.phone || '').includes(q) ||
    (c.email || '').toLowerCase().includes(q)
  )
})

const paginatedCustomers = computed(() => {
  const start = (currentPage.value - 1) * perPage
  return filteredCustomers.value.slice(start, start + perPage)
})
const totalPages = computed(() => Math.ceil(filteredCustomers.value.length / perPage))

const openAdd = () => {
  editingCustomer.value = null
  newCustomer.value = { name: '', phone: '', email: '', address: '' }
  isAddOpen.value = true
}

const openEdit = (c: any) => {
  editingCustomer.value = c
  newCustomer.value = { name: c.name, phone: c.phone || '', email: c.email || '', address: c.address || '' }
  isAddOpen.value = true
}

const saveCustomer = async () => {
  if (!newCustomer.value.name || !user.value || !outletId.value) return
  saving.value = true
  try {
    if (editingCustomer.value) {
      // Update
      await client.from('customers').update({
        name: newCustomer.value.name,
        phone: newCustomer.value.phone || null,
        email: newCustomer.value.email || null,
        address: newCustomer.value.address || null,
      }).eq('id', editingCustomer.value.id)
    } else {
      // Insert
      await client.from('customers').insert({
        name: newCustomer.value.name,
        phone: newCustomer.value.phone || null,
        email: newCustomer.value.email || null,
        address: newCustomer.value.address || null,
        outlet_id: outletId.value
      })
    }
    isAddOpen.value = false
    editingCustomer.value = null
    newCustomer.value = { name: '', phone: '', email: '', address: '' }
    await fetchCustomers()
  } catch (err: any) {
    alert(err.message || 'Failed to save customer')
  } finally {
    saving.value = false
  }
}

const deleteCustomer = async (c: any) => {
  if (!confirm(`Delete "${c.name}"?`)) return
  await client.from('customers').delete().eq('id', c.id)
  await fetchCustomers()
}
</script>

<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex justify-between items-start">
      <div>
        <h2 class="text-2xl font-bold text-gray-900">Customer Management</h2>
        <p class="text-gray-500 text-sm mt-1">Manage your customers and track their activity.</p>
      </div>
      <div class="flex items-center gap-3">
        <UInput v-model="search" icon="i-lucide-search" placeholder="Search customers..." class="w-64" @input="currentPage = 1" />
        <UButton color="primary" label="+ Add Customer" @click="openAdd" />
      </div>
    </div>

    <!-- Pro Tip -->
    <div class="bg-blue-50 border border-blue-200 rounded-xl px-5 py-3 flex items-start gap-3">
      <UIcon name="i-lucide-lightbulb" class="w-5 h-5 text-blue-500 mt-0.5 flex-shrink-0" />
      <p class="text-sm text-blue-700">
        <span class="font-medium text-blue-900">Pro Tip:</span> Add customer details to track repeat visitors. Attach a customer to orders at checkout for better reporting.
      </p>
    </div>

    <!-- 3 Stat Cards -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-5">
      <div class="bg-white rounded-xl p-6 border border-gray-100 shadow-sm">
        <div class="flex items-start justify-between">
          <div>
            <p class="text-xs font-medium text-gray-500 uppercase tracking-wider">TOTAL CUSTOMERS</p>
            <p class="text-3xl font-bold text-gray-900 mt-2">{{ totalCustomers.toLocaleString() }}</p>
            <p class="text-sm mt-2 text-gray-500">All registered customers</p>
          </div>
          <div class="w-12 h-12 bg-blue-50 rounded-xl flex items-center justify-center">
            <UIcon name="i-lucide-users" class="w-6 h-6 text-blue-600" />
          </div>
        </div>
      </div>
      <div class="bg-white rounded-xl p-6 border border-gray-100 shadow-sm">
        <div class="flex items-start justify-between">
          <div>
            <p class="text-xs font-medium text-gray-500 uppercase tracking-wider">NEW THIS MONTH</p>
            <p class="text-3xl font-bold text-gray-900 mt-2">{{ newThisMonth }}</p>
            <p class="text-sm mt-2 text-green-600">Recently added</p>
          </div>
          <div class="w-12 h-12 bg-green-50 rounded-xl flex items-center justify-center">
            <UIcon name="i-lucide-user-plus" class="w-6 h-6 text-green-600" />
          </div>
        </div>
      </div>
      <div class="bg-white rounded-xl p-6 border border-gray-100 shadow-sm">
        <div class="flex items-start justify-between">
          <div>
            <p class="text-xs font-medium text-gray-500 uppercase tracking-wider">DATABASE</p>
            <p class="text-3xl font-bold text-gray-900 mt-2">Active</p>
            <p class="text-sm mt-2 text-gray-500">Connected to Supabase</p>
          </div>
          <div class="w-12 h-12 bg-amber-50 rounded-xl flex items-center justify-center">
            <UIcon name="i-lucide-database" class="w-6 h-6 text-amber-600" />
          </div>
        </div>
      </div>
    </div>

    <!-- Table -->
    <div class="bg-white rounded-xl border border-gray-100 shadow-sm overflow-hidden">
      <div class="px-6 py-4 border-b border-gray-100 flex justify-between items-center">
        <h3 class="font-semibold text-gray-900 text-lg">All Customers</h3>
        <span class="text-sm text-gray-500">{{ filteredCustomers.length }} results</span>
      </div>

      <div v-if="!loading && filteredCustomers.length === 0" class="p-16 text-center">
        <UIcon name="i-lucide-users" class="w-12 h-12 mx-auto mb-4 text-gray-300" />
        <h3 class="text-lg font-semibold text-gray-900 mb-2">No customers yet</h3>
        <p class="text-gray-500 text-sm mb-6">Add your first customer to keep track of regulars.</p>
        <UButton color="primary" label="Add Customer" icon="i-lucide-user-plus" @click="openAdd" />
      </div>

      <table v-else class="w-full text-sm">
        <thead>
          <tr class="border-b border-gray-100">
            <th class="text-left py-4 px-5 text-xs font-medium text-gray-500 uppercase tracking-wider">Customer</th>
            <th class="text-left py-4 px-5 text-xs font-medium text-gray-500 uppercase tracking-wider">Phone</th>
            <th class="text-left py-4 px-5 text-xs font-medium text-gray-500 uppercase tracking-wider">Email</th>
            <th class="text-left py-4 px-5 text-xs font-medium text-gray-500 uppercase tracking-wider">Address</th>
            <th class="text-left py-4 px-5 text-xs font-medium text-gray-500 uppercase tracking-wider">Joined</th>
            <th class="text-left py-4 px-5 text-xs font-medium text-gray-500 uppercase tracking-wider">Action</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-gray-50">
          <tr v-for="c in paginatedCustomers" :key="c.id" class="hover:bg-gray-50 transition-colors">
            <td class="py-4 px-5">
              <div class="flex items-center gap-3">
                <div :class="[c.initialColor, 'w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold flex-shrink-0']">
                  {{ c.initials }}
                </div>
                <span class="font-medium text-gray-900">{{ c.name }}</span>
              </div>
            </td>
            <td class="py-4 px-5 text-gray-600">{{ c.phone || '-' }}</td>
            <td class="py-4 px-5 text-gray-600">{{ c.email || '-' }}</td>
            <td class="py-4 px-5 text-gray-600 max-w-[200px] truncate">{{ c.address || '-' }}</td>
            <td class="py-4 px-5 text-gray-600">{{ c.joinedDate }}</td>
            <td class="py-4 px-5">
              <div class="flex items-center gap-1">
                <UButton icon="i-lucide-pencil" color="neutral" variant="ghost" size="xs" @click="openEdit(c)" />
                <UButton icon="i-lucide-trash-2" color="neutral" variant="ghost" size="xs" @click="deleteCustomer(c)" />
              </div>
            </td>
          </tr>
        </tbody>
      </table>

      <!-- Pagination -->
      <div v-if="totalPages > 1" class="flex items-center justify-between px-6 py-4 border-t border-gray-100">
        <p class="text-sm text-gray-500">
          Showing {{ ((currentPage - 1) * perPage) + 1 }} to {{ Math.min(currentPage * perPage, filteredCustomers.length) }} of {{ filteredCustomers.length }} results
        </p>
        <div class="flex items-center gap-2">
          <button @click="currentPage = Math.max(1, currentPage - 1)" :disabled="currentPage === 1" class="px-4 py-2 text-sm rounded-lg border border-gray-200 text-gray-600 hover:bg-gray-50 disabled:opacity-40">Previous</button>
          <button @click="currentPage = Math.min(totalPages, currentPage + 1)" :disabled="currentPage >= totalPages" class="px-4 py-2 text-sm rounded-lg border border-gray-200 text-gray-600 hover:bg-gray-50 disabled:opacity-40">Next</button>
        </div>
      </div>
    </div>

    <!-- Add/Edit Customer Modal -->
    <UModal v-model:open="isAddOpen">
      <template #content>
        <div class="p-6 bg-white">
          <h3 class="text-base font-semibold text-gray-900 mb-4">{{ editingCustomer ? 'Edit Customer' : 'Add Customer' }}</h3>
          <div class="space-y-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1.5">Name <span class="text-red-500">*</span></label>
              <UInput v-model="newCustomer.name" placeholder="Customer name" />
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1.5">Phone</label>
              <UInput v-model="newCustomer.phone" placeholder="+60 12-345 6789" />
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1.5">Email</label>
              <UInput v-model="newCustomer.email" type="email" placeholder="email@example.com" />
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1.5">Address</label>
              <UInput v-model="newCustomer.address" placeholder="Customer address" />
            </div>
          </div>
          <div class="flex justify-end gap-3 mt-6 pt-4 border-t border-gray-100">
            <UButton color="neutral" variant="ghost" label="Cancel" @click="isAddOpen = false" />
            <UButton color="primary" :label="editingCustomer ? 'Update' : 'Save'" :loading="saving" @click="saveCustomer" />
          </div>
        </div>
      </template>
    </UModal>
  </div>
</template>
