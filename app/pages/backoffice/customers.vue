<script setup lang="ts">
definePageMeta({ layout: 'backoffice' })

const client = useSupabaseClient()
const user = useSupabaseUser()
const customers = ref<any[]>([])
const loading = ref(true)
const search = ref('')

const isAddOpen = ref(false)
const newCustomer = ref({ name: '', phone: '', email: '' })
const saving = ref(false)

const currentPage = ref(1)
const perPage = 5

const stats = ref([
  { label: 'TOTAL MEMBERS', value: '2,453', trend: '↗12.5%', trendText: 'vs last month', icon: 'i-lucide-users', iconBg: 'bg-blue-50', iconColor: 'text-blue-600' },
  { label: 'NEW MEMBERS THIS MONTH', value: '148', trend: '↗8.2%', trendText: 'vs last month', icon: 'i-lucide-user-plus', iconBg: 'bg-green-50', iconColor: 'text-green-600' },
  { label: 'AVERAGE LOYALTY POINTS', value: '850', trend: '↘2.1%', trendText: 'vs last month', icon: 'i-lucide-star', iconBg: 'bg-amber-50', iconColor: 'text-amber-600' },
])

const tiers = ['Gold', 'Silver', 'Bronze']
const tierColors: Record<string, string> = {
  Gold: 'bg-yellow-100 text-yellow-700',
  Silver: 'bg-gray-100 text-gray-600',
  Bronze: 'bg-orange-100 text-orange-700',
}

const fetchCustomers = async () => {
  loading.value = true
  try {
    if (!user.value) return
    const { data: profile } = await client.from('profiles').select('outlet_id').eq('id', user.value.id).single()
    if (!profile?.outlet_id) return

    const { data } = await client
      .from('customers')
      .select('*')
      .eq('outlet_id', profile.outlet_id)
      .order('created_at', { ascending: false })

    customers.value = (data || []).map((c: any, i: number) => ({
      ...c,
      customerId: '#CUS-' + String(921 + i).padStart(5, '0'),
      initials: (c.name || 'U').substring(0, 2).toUpperCase(),
      initialColor: ['bg-blue-100 text-blue-600', 'bg-red-100 text-red-600', 'bg-green-100 text-green-600', 'bg-purple-100 text-purple-600'][i % 4],
      tier: tiers[i % 3],
      points: Math.floor(Math.random() * 3000) + 100,
      lastVisit: new Date(c.created_at).toLocaleDateString('en-MY', { day: '2-digit', month: 'short', year: 'numeric' })
    }))

    // Update stats with real counts
    stats.value[0].value = customers.value.length.toLocaleString()
  } finally {
    loading.value = false
  }
}

onMounted(fetchCustomers)

const filteredCustomers = computed(() => {
  if (!search.value) return customers.value
  const q = search.value.toLowerCase()
  return customers.value.filter(c => c.name.toLowerCase().includes(q) || (c.phone || '').includes(q) || (c.email || '').toLowerCase().includes(q))
})

const paginatedCustomers = computed(() => {
  const start = (currentPage.value - 1) * perPage
  return filteredCustomers.value.slice(start, start + perPage)
})
const totalPages = computed(() => Math.ceil(filteredCustomers.value.length / perPage))

const saveCustomer = async () => {
  if (!newCustomer.value.name || !user.value) return
  saving.value = true
  try {
    const { data: profile } = await client.from('profiles').select('outlet_id').eq('id', user.value.id).single()
    if (!profile?.outlet_id) return
    await client.from('customers').insert({
      name: newCustomer.value.name,
      phone: newCustomer.value.phone || null,
      email: newCustomer.value.email || null,
      outlet_id: profile.outlet_id
    })
    isAddOpen.value = false
    newCustomer.value = { name: '', phone: '', email: '' }
    await fetchCustomers()
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
        <p class="text-gray-500 text-sm mt-1">Manage loyalty members, track points, and view history.</p>
      </div>
      <div class="flex items-center gap-3">
        <UInput v-model="search" icon="i-lucide-search" placeholder="Search customers..." class="w-64" />
        <UButton color="primary" label="+ Add new customers" @click="isAddOpen = true" />
      </div>
    </div>

    <!-- 3 Stat Cards -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-5">
      <div v-for="s in stats" :key="s.label" class="bg-white rounded-xl p-6 border border-gray-100 shadow-sm">
        <div class="flex items-start justify-between">
          <div>
            <p class="text-xs font-medium text-gray-500 uppercase tracking-wider">{{ s.label }}</p>
            <p class="text-3xl font-bold text-gray-900 mt-2">{{ s.value }}</p>
            <p class="text-sm mt-2">
              <span class="text-green-600 font-medium">{{ s.trend }}</span>
              <span class="text-gray-400 ml-1">{{ s.trendText }}</span>
            </p>
          </div>
          <div :class="[s.iconBg, s.iconColor, 'w-12 h-12 rounded-xl flex items-center justify-center']">
            <UIcon :name="s.icon" class="w-6 h-6" />
          </div>
        </div>
      </div>
    </div>

    <!-- Table -->
    <div class="bg-white rounded-xl border border-gray-100 shadow-sm overflow-hidden">
      <div class="px-6 py-4 border-b border-gray-100 flex justify-between items-center">
        <h3 class="font-semibold text-gray-900 text-lg">All Customers</h3>
        <div class="flex items-center gap-3">
          <UButton color="neutral" variant="outline" label="Filter" icon="i-lucide-filter" size="sm" />
          <UButton color="neutral" variant="outline" label="Export" icon="i-lucide-download" size="sm" />
        </div>
      </div>

      <div v-if="!loading && filteredCustomers.length === 0" class="p-16 text-center">
        <UIcon name="i-lucide-users" class="w-12 h-12 mx-auto mb-4 text-gray-300" />
        <h3 class="text-lg font-semibold text-gray-900 mb-2">No customers yet</h3>
        <p class="text-gray-500 text-sm mb-6">Add your first customer to keep track of regulars.</p>
        <UButton color="primary" label="Add Customer" icon="i-lucide-user-plus" @click="isAddOpen = true" />
      </div>

      <table v-else class="w-full text-sm">
        <thead>
          <tr class="border-b border-gray-100">
            <th class="text-left py-4 px-5 text-xs font-medium text-gray-500 uppercase tracking-wider">Customer ID</th>
            <th class="text-left py-4 px-5 text-xs font-medium text-gray-500 uppercase tracking-wider">Customer Name</th>
            <th class="text-left py-4 px-5 text-xs font-medium text-gray-500 uppercase tracking-wider">Phone Number</th>
            <th class="text-left py-4 px-5 text-xs font-medium text-gray-500 uppercase tracking-wider">Email</th>
            <th class="text-left py-4 px-5 text-xs font-medium text-gray-500 uppercase tracking-wider">Membership Tier</th>
            <th class="text-left py-4 px-5 text-xs font-medium text-gray-500 uppercase tracking-wider">Total Points</th>
            <th class="text-left py-4 px-5 text-xs font-medium text-gray-500 uppercase tracking-wider">Last Visit</th>
            <th class="text-left py-4 px-5 text-xs font-medium text-gray-500 uppercase tracking-wider">Action</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-gray-50">
          <tr v-for="c in paginatedCustomers" :key="c.id" class="hover:bg-gray-50 transition-colors">
            <td class="py-4 px-5 text-gray-600 font-mono text-xs">{{ c.customerId }}</td>
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
            <td class="py-4 px-5">
              <span :class="[tierColors[c.tier], 'px-3 py-1 rounded-full text-xs font-semibold']">{{ c.tier }}</span>
            </td>
            <td class="py-4 px-5 font-semibold text-gray-900 text-center">{{ c.points.toLocaleString() }}</td>
            <td class="py-4 px-5 text-gray-600">{{ c.lastVisit }}</td>
            <td class="py-4 px-5">
              <UButton icon="i-lucide-more-vertical" color="neutral" variant="ghost" size="xs" />
            </td>
          </tr>
        </tbody>
      </table>

      <!-- Pagination -->
      <div v-if="filteredCustomers.length > 0" class="flex items-center justify-between px-6 py-4 border-t border-gray-100">
        <p class="text-sm text-gray-500">
          Showing {{ ((currentPage - 1) * perPage) + 1 }} to {{ Math.min(currentPage * perPage, filteredCustomers.length) }} of {{ filteredCustomers.length.toLocaleString() }} results
        </p>
        <div class="flex items-center gap-2">
          <button @click="currentPage = Math.max(1, currentPage - 1)" :disabled="currentPage === 1" class="px-4 py-2 text-sm rounded-lg border border-gray-200 text-gray-600 hover:bg-gray-50 disabled:opacity-40">Previous</button>
          <button @click="currentPage = Math.min(totalPages, currentPage + 1)" :disabled="currentPage >= totalPages" class="px-4 py-2 text-sm rounded-lg border border-gray-200 text-gray-600 hover:bg-gray-50 disabled:opacity-40">Next</button>
        </div>
      </div>
    </div>

    <!-- Add Customer Modal -->
    <UModal v-model:open="isAddOpen">
      <template #content>
        <div class="p-6 bg-white">
          <h3 class="text-base font-semibold text-gray-900 mb-4">Add Customer</h3>
          <div class="space-y-4">
            <UFormGroup label="Name" required>
              <UInput v-model="newCustomer.name" placeholder="Customer name" />
            </UFormGroup>
            <UFormGroup label="Phone">
              <UInput v-model="newCustomer.phone" placeholder="+60 12-345 6789" />
            </UFormGroup>
            <UFormGroup label="Email">
              <UInput v-model="newCustomer.email" type="email" placeholder="email@example.com" />
            </UFormGroup>
          </div>
          <div class="flex justify-end gap-3 mt-6 pt-4 border-t border-gray-100">
            <UButton color="neutral" variant="ghost" label="Cancel" @click="isAddOpen = false" />
            <UButton color="primary" label="Save" :loading="saving" @click="saveCustomer" />
          </div>
        </div>
      </template>
    </UModal>
  </div>
</template>
