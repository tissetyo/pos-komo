<script setup lang="ts">
definePageMeta({ layout: 'backoffice' })

const client = useSupabaseClient()
const user = useSupabaseUser()
const employees = ref<any[]>([])
const loading = ref(true)
const search = ref('')

const columns = [
  { id: 'name', key: 'name', label: 'Employee' },
  { id: 'role', key: 'role', label: 'Role & Outlet' },
  { id: 'status', key: 'status', label: 'Status' },
  { id: 'joined', key: 'joined', label: 'Date Joined' },
  { id: 'actions', key: 'actions', label: '' }
]

const isAddOpen = ref(false)
const newEmployee = ref({ name: '', email: '', password: '', role: 'cashier' })
const saving = ref(false)

const fetchEmployees = async () => {
  loading.value = true
  try {
    if (!user.value) return
    const { data: myProfile } = await client.from('profiles').select('outlet_id').eq('id', user.value.id).single()
    if (!myProfile?.outlet_id) return

    const { data } = await client
      .from('profiles')
      .select('*, outlets(name)')
      .eq('outlet_id', myProfile.outlet_id)
      .neq('id', user.value.id)
      .order('created_at', { ascending: false })

    employees.value = (data || []).map((e: any) => ({
      ...e,
      outletName: e.outlets?.name || '-',
      joinedDate: new Date(e.created_at).toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric' }),
      status: 'Active'
    }))
  } finally {
    loading.value = false
  }
}

onMounted(fetchEmployees)

const filteredEmployees = computed(() => {
  if (!search.value) return employees.value
  return employees.value.filter(e => (e.full_name || '').toLowerCase().includes(search.value.toLowerCase()))
})

const saveEmployee = async () => {
  if (!newEmployee.value.email || !newEmployee.value.password || !user.value) return
  saving.value = true
  try {
    const { data: myProfile } = await client.from('profiles').select('outlet_id').eq('id', user.value.id).single()
    if (!myProfile?.outlet_id) return

    // Sign up new user
    const { data: authData, error } = await client.auth.signUp({
      email: newEmployee.value.email,
      password: newEmployee.value.password,
      options: {
        data: {
          full_name: newEmployee.value.name,
          role: newEmployee.value.role
        }
      }
    })

    if (error) throw error
    if (!authData.user) return

    // Update their profile
    await client.from('profiles').update({
      full_name: newEmployee.value.name,
      role: newEmployee.value.role,
      outlet_id: myProfile.outlet_id,
      onboarding_completed: true
    }).eq('id', authData.user.id)

    isAddOpen.value = false
    newEmployee.value = { name: '', email: '', password: '', role: 'cashier' }
    await fetchEmployees()
  } catch (err: any) {
    alert(err.message || 'Failed to add employee')
  } finally {
    saving.value = false
  }
}

const deleteEmployee = async (emp: any) => {
  if (!confirm(`Remove "${emp.full_name || emp.email}"?`)) return
  // We can't delete auth users from client — just remove profile link
  await client.from('profiles').update({ outlet_id: null }).eq('id', emp.id)
  await fetchEmployees()
}
</script>

<template>
  <div class="space-y-6">
    <div class="flex justify-between items-end">
      <div>
        <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Employee Management</h2>
        <p class="text-gray-500 dark:text-gray-400 text-sm mt-1">Manage staff roles and access.</p>
      </div>
      <UButton color="primary" label="Add Employee" icon="i-lucide-user-plus" @click="isAddOpen = true" />
    </div>

    <!-- Search -->
    <div class="bg-white dark:bg-gray-900 p-4 flex items-center rounded-2xl shadow-sm border border-gray-100 dark:border-gray-800">
       <UInput v-model="search" icon="i-lucide-search" placeholder="Search employee..." class="w-72" />
    </div>

    <!-- Empty State -->
    <div v-if="!loading && filteredEmployees.length === 0" class="bg-white dark:bg-gray-900 rounded-2xl shadow-sm border border-gray-100 dark:border-gray-800 p-16 text-center">
      <UIcon name="i-lucide-user-cog" class="w-12 h-12 mx-auto mb-4 text-gray-300 dark:text-gray-600" />
      <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-2">No employees yet</h3>
      <p class="text-gray-500 dark:text-gray-400 text-sm mb-6">Add cashiers, kitchen staff, or managers.</p>
      <UButton color="primary" label="Add Employee" icon="i-lucide-user-plus" @click="isAddOpen = true" />
    </div>

    <!-- Data Table -->
    <div v-else class="bg-white dark:bg-gray-900 rounded-2xl shadow-sm border border-gray-100 dark:border-gray-800 overflow-hidden">
      <UTable :rows="filteredEmployees" :columns="columns" :loading="loading">
        <template #name-data="{ row }">
          <div class="flex items-center gap-3">
            <UAvatar :alt="row.full_name || 'User'" size="sm" />
            <div>
              <p class="font-medium text-gray-900 dark:text-white">{{ row.full_name || row.email }}</p>
              <p class="text-xs text-gray-500 dark:text-gray-400">{{ row.email }}</p>
            </div>
          </div>
        </template>

        <template #role-data="{ row }">
          <div>
            <p class="text-sm font-medium text-gray-900 dark:text-white capitalize">{{ row.role }}</p>
            <p class="text-xs text-gray-500 dark:text-gray-400 flex items-center gap-1 mt-0.5">
               <UIcon name="i-lucide-map-pin" class="w-3 h-3" /> {{ row.outletName }}
            </p>
          </div>
        </template>

        <template #status-data="{ row }">
          <UBadge color="success" variant="soft" class="px-2.5 py-1 rounded-full text-xs font-medium">
            {{ row.status }}
          </UBadge>
        </template>

        <template #joined-data="{ row }">
          <span class="text-sm text-gray-600 dark:text-gray-400">{{ row.joinedDate }}</span>
        </template>

        <template #actions-data="{ row }">
          <div class="flex justify-end gap-2 pr-4 text-gray-400">
             <UButton color="neutral" variant="ghost" icon="i-lucide-trash-2" size="xs" @click="deleteEmployee(row)" />
          </div>
        </template>
      </UTable>
    </div>

    <!-- Add Employee Modal -->
    <UModal v-model:open="isAddOpen">
      <template #content>
        <div class="p-6 bg-white dark:bg-gray-900">
          <h3 class="text-base font-semibold text-gray-900 dark:text-white mb-4">Add Employee</h3>
          <div class="space-y-4">
            <UFormGroup label="Full Name" required>
              <UInput v-model="newEmployee.name" placeholder="Employee name" />
            </UFormGroup>
            <UFormGroup label="Email" required>
              <UInput v-model="newEmployee.email" type="email" placeholder="employee@store.com" />
            </UFormGroup>
            <UFormGroup label="Password" required>
              <UInput v-model="newEmployee.password" type="password" placeholder="••••••••" />
            </UFormGroup>
            <UFormGroup label="Role">
              <USelect v-model="newEmployee.role" :options="['cashier', 'manager', 'kitchen']" />
            </UFormGroup>
          </div>
          <div class="flex justify-end gap-3 mt-6 pt-4 border-t border-gray-100 dark:border-gray-800">
            <UButton color="neutral" variant="ghost" label="Cancel" @click="isAddOpen = false" />
            <UButton color="primary" label="Add Employee" :loading="saving" @click="saveEmployee" />
          </div>
        </div>
      </template>
    </UModal>
  </div>
</template>
