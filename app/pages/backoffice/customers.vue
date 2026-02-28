<script setup lang="ts">
definePageMeta({ layout: 'backoffice' })

const client = useSupabaseClient()
const user = useSupabaseUser()
const customers = ref<any[]>([])
const loading = ref(true)
const search = ref('')

const columns = [
  { id: 'name', key: 'name', label: 'Name' },
  { id: 'contact', key: 'contact', label: 'Contact Info' },
  { id: 'lastVisit', key: 'lastVisit', label: 'Added' },
  { id: 'actions', key: 'actions', label: '' }
]

const isAddOpen = ref(false)
const newCustomer = ref({ name: '', phone: '', email: '' })
const saving = ref(false)

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

    customers.value = (data || []).map((c: any) => ({
      ...c,
      addedDate: new Date(c.created_at).toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric' })
    }))
  } finally {
    loading.value = false
  }
}

onMounted(fetchCustomers)

const filteredCustomers = computed(() => {
  if (!search.value) return customers.value
  const q = search.value.toLowerCase()
  return customers.value.filter(c => c.name.toLowerCase().includes(q) || (c.phone || '').includes(q))
})

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
    <div class="flex justify-between items-end">
      <div>
        <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Customers Directory</h2>
        <p class="text-gray-500 dark:text-gray-400 text-sm mt-1">Manage and view your customer list.</p>
      </div>
      <UButton color="primary" label="Add Customer" icon="i-lucide-user-plus" @click="isAddOpen = true" />
    </div>

    <!-- Search -->
    <div class="bg-white dark:bg-gray-900 p-4 flex items-center rounded-2xl shadow-sm border border-gray-100 dark:border-gray-800">
       <UInput v-model="search" icon="i-lucide-search" placeholder="Search by name or phone..." class="w-72" />
    </div>

    <!-- Empty State -->
    <div v-if="!loading && filteredCustomers.length === 0" class="bg-white dark:bg-gray-900 rounded-2xl shadow-sm border border-gray-100 dark:border-gray-800 p-16 text-center">
      <UIcon name="i-lucide-users" class="w-12 h-12 mx-auto mb-4 text-gray-300 dark:text-gray-600" />
      <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-2">No customers yet</h3>
      <p class="text-gray-500 dark:text-gray-400 text-sm mb-6">Add your first customer to keep track of regulars.</p>
      <UButton color="primary" label="Add Customer" icon="i-lucide-user-plus" @click="isAddOpen = true" />
    </div>

    <!-- Data Table -->
    <div v-else class="bg-white dark:bg-gray-900 rounded-2xl shadow-sm border border-gray-100 dark:border-gray-800 overflow-hidden">
      <UTable :rows="filteredCustomers" :columns="columns" :loading="loading">
        <template #name-data="{ row }">
          <div class="flex items-center gap-3">
            <UAvatar :alt="row.name" size="sm" />
            <div>
              <p class="font-medium text-gray-900 dark:text-white">{{ row.name }}</p>
            </div>
          </div>
        </template>

        <template #contact-data="{ row }">
          <div>
            <p class="text-sm text-gray-900 dark:text-white">{{ row.phone || '-' }}</p>
            <p class="text-xs text-gray-500 dark:text-gray-400">{{ row.email || '-' }}</p>
          </div>
        </template>

        <template #lastVisit-data="{ row }">
          <span class="text-sm text-gray-600 dark:text-gray-400">{{ row.addedDate }}</span>
        </template>

        <template #actions-data="{ row }">
          <div class="flex justify-end pr-4">
             <UButton color="neutral" variant="ghost" icon="i-lucide-trash-2" size="xs" @click="deleteCustomer(row)" />
          </div>
        </template>
      </UTable>
    </div>

    <!-- Add Customer Modal -->
    <UModal v-model:open="isAddOpen">
      <template #content>
        <div class="p-6 bg-white dark:bg-gray-900">
          <h3 class="text-base font-semibold text-gray-900 dark:text-white mb-4">Add Customer</h3>
          <div class="space-y-4">
            <UFormGroup label="Name" required>
              <UInput v-model="newCustomer.name" placeholder="Customer name" />
            </UFormGroup>
            <UFormGroup label="Phone">
              <UInput v-model="newCustomer.phone" placeholder="08xxx" />
            </UFormGroup>
            <UFormGroup label="Email">
              <UInput v-model="newCustomer.email" type="email" placeholder="email@example.com" />
            </UFormGroup>
          </div>
          <div class="flex justify-end gap-3 mt-6 pt-4 border-t border-gray-100 dark:border-gray-800">
            <UButton color="neutral" variant="ghost" label="Cancel" @click="isAddOpen = false" />
            <UButton color="primary" label="Save" :loading="saving" @click="saveCustomer" />
          </div>
        </div>
      </template>
    </UModal>
  </div>
</template>
