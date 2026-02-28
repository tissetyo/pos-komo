<script setup lang="ts">
definePageMeta({ layout: 'backoffice' })

const client = useSupabaseClient()
const user = useSupabaseUser()
const employees = ref<any[]>([])
const loading = ref(true)
const search = ref('')
const outletId = ref<string | null>(null)

const isAddOpen = ref(false)
const newEmployee = ref({ name: '', email: '', password: '', role: 'cashier' })
const saving = ref(false)

// Real stats
const totalEmployees = ref(0)
const employeeSales = ref<Record<string, number>>({})

const fetchEmployees = async () => {
  loading.value = true
  try {
    if (!user.value) return
    const { data: myProfile } = await client.from('profiles').select('outlet_id').eq('id', user.value.id).single()
    outletId.value = myProfile?.outlet_id || null
    if (!outletId.value) return

    const { data } = await client
      .from('profiles')
      .select('*, outlets(name)')
      .eq('outlet_id', outletId.value)
      .order('created_at', { ascending: false })

    // Get sales per cashier
    const { data: orders } = await client
      .from('orders')
      .select('cashier_id, total')
      .eq('outlet_id', outletId.value)
      .eq('payment_status', 'paid')

    const salesMap: Record<string, number> = {}
    ;(orders || []).forEach((o: any) => {
      if (o.cashier_id) {
        salesMap[o.cashier_id] = (salesMap[o.cashier_id] || 0) + (o.total || 0)
      }
    })
    employeeSales.value = salesMap

    employees.value = (data || []).map((e: any) => ({
      ...e,
      outletName: e.outlets?.name || '-',
      joinedDate: new Date(e.created_at).toLocaleDateString('en-MY', { day: 'numeric', month: 'short', year: 'numeric' }),
      totalSales: salesMap[e.id] || 0,
      initials: ((e.full_name || e.email || 'U').substring(0, 1) + ((e.full_name || '').split(' ')[1] || '').substring(0, 1)).toUpperCase() || 'U',
      initialsColor: ['bg-blue-100 text-blue-600', 'bg-purple-100 text-purple-600', 'bg-green-100 text-green-600', 'bg-orange-100 text-orange-600'][Math.floor(Math.random() * 4)]
    }))

    totalEmployees.value = employees.value.length
  } finally {
    loading.value = false
  }
}

onMounted(fetchEmployees)

const filteredEmployees = computed(() => {
  if (!search.value) return employees.value
  return employees.value.filter(e => (e.full_name || e.email || '').toLowerCase().includes(search.value.toLowerCase()))
})

const formatRM = (amount: number) => 'RM ' + amount.toLocaleString('en-MY', { minimumFractionDigits: 2, maximumFractionDigits: 2 })

const topPerformer = computed(() => {
  if (employees.value.length === 0) return null
  return employees.value.reduce((top, e) => (e.totalSales > (top?.totalSales || 0) ? e : top), employees.value[0])
})

const saveEmployee = async () => {
  if (!newEmployee.value.email || !newEmployee.value.password || !user.value || !outletId.value) return
  saving.value = true
  try {
    const { data: authData, error } = await client.auth.signUp({
      email: newEmployee.value.email,
      password: newEmployee.value.password,
      options: { data: { full_name: newEmployee.value.name, role: newEmployee.value.role } }
    })
    if (error) throw error
    if (!authData.user) return
    await client.from('profiles').update({
      full_name: newEmployee.value.name,
      role: newEmployee.value.role,
      outlet_id: outletId.value,
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
  if (!confirm(`Remove "${emp.full_name || emp.email}" from this outlet?`)) return
  await client.from('profiles').update({ outlet_id: null }).eq('id', emp.id)
  await fetchEmployees()
}
</script>

<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex justify-between items-start">
      <div>
        <h2 class="text-2xl font-bold text-gray-900">Employee Management</h2>
        <p class="text-gray-500 text-sm mt-1">Manage staff roles and view performance.</p>
      </div>
      <div class="flex items-center gap-3">
        <UInput v-model="search" icon="i-lucide-search" placeholder="Search employees..." class="w-64" />
        <UButton color="primary" label="+ Add Employee" icon="i-lucide-user-plus" @click="isAddOpen = true" />
      </div>
    </div>

    <!-- Pro Tip -->
    <div class="bg-blue-50 border border-blue-200 rounded-xl px-5 py-3 flex items-start gap-3">
      <UIcon name="i-lucide-lightbulb" class="w-5 h-5 text-blue-500 mt-0.5 flex-shrink-0" />
      <p class="text-sm text-blue-700">
        <span class="font-medium text-blue-900">Pro Tip:</span> Assign roles (Admin, Manager, Cashier, Kitchen) to control what each staff member can access. Total Sales shows orders processed by each cashier.
      </p>
    </div>

    <!-- 3 Stat Cards -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-5">
      <div class="bg-white rounded-xl p-5 border border-gray-100 shadow-sm">
        <div class="flex items-start justify-between">
          <div>
            <p class="text-xs font-medium text-gray-500 uppercase tracking-wider">TOTAL EMPLOYEES</p>
            <p class="text-2xl font-bold text-gray-900 mt-2">{{ totalEmployees }} Staff</p>
            <p class="text-sm mt-2 text-gray-500">In this outlet</p>
          </div>
          <div class="w-10 h-10 bg-blue-50 rounded-xl flex items-center justify-center">
            <UIcon name="i-lucide-users" class="w-5 h-5 text-blue-600" />
          </div>
        </div>
      </div>
      <div class="bg-white rounded-xl p-5 border border-gray-100 shadow-sm">
        <div class="flex items-start justify-between">
          <div>
            <p class="text-xs font-medium text-gray-500 uppercase tracking-wider">TOP PERFORMER</p>
            <p class="text-2xl font-bold text-gray-900 mt-2">{{ topPerformer?.full_name || '-' }}</p>
            <p class="text-sm mt-2 text-green-600" v-if="topPerformer">{{ formatRM(topPerformer.totalSales) }} total sales</p>
            <p class="text-sm mt-2 text-gray-500" v-else>No sales data yet</p>
          </div>
          <div class="w-10 h-10 bg-amber-50 rounded-xl flex items-center justify-center">
            <UIcon name="i-lucide-trophy" class="w-5 h-5 text-amber-600" />
          </div>
        </div>
      </div>
      <div class="bg-white rounded-xl p-5 border border-gray-100 shadow-sm">
        <div class="flex items-start justify-between">
          <div>
            <p class="text-xs font-medium text-gray-500 uppercase tracking-wider">ROLES</p>
            <p class="text-2xl font-bold text-gray-900 mt-2">4 Types</p>
            <p class="text-sm mt-2 text-gray-500">Admin, Manager, Cashier, Kitchen</p>
          </div>
          <div class="w-10 h-10 bg-purple-50 rounded-xl flex items-center justify-center">
            <UIcon name="i-lucide-shield" class="w-5 h-5 text-purple-600" />
          </div>
        </div>
      </div>
    </div>

    <!-- Employee Table -->
    <div class="bg-white rounded-xl border border-gray-100 shadow-sm overflow-hidden">
      <div class="flex items-center justify-between px-6 py-4 border-b border-gray-100">
        <h3 class="font-semibold text-gray-900">All Employees</h3>
        <span class="text-sm text-gray-500">{{ filteredEmployees.length }} results</span>
      </div>

      <div v-if="!loading && filteredEmployees.length === 0" class="p-16 text-center">
        <UIcon name="i-lucide-users" class="w-12 h-12 mx-auto mb-4 text-gray-300" />
        <h3 class="text-lg font-semibold text-gray-900 mb-2">No employees found</h3>
        <p class="text-gray-500 text-sm mb-6">Add your first team member to get started.</p>
        <UButton color="primary" label="Add Employee" icon="i-lucide-user-plus" @click="isAddOpen = true" />
      </div>

      <table v-else class="w-full text-sm">
        <thead>
          <tr class="border-b border-gray-100">
            <th class="text-left py-3 px-5 text-xs font-medium text-gray-500 uppercase tracking-wider">Staff Name</th>
            <th class="text-left py-3 px-5 text-xs font-medium text-gray-500 uppercase tracking-wider">Email</th>
            <th class="text-left py-3 px-5 text-xs font-medium text-gray-500 uppercase tracking-wider">Role</th>
            <th class="text-left py-3 px-5 text-xs font-medium text-gray-500 uppercase tracking-wider">Total Sales</th>
            <th class="text-left py-3 px-5 text-xs font-medium text-gray-500 uppercase tracking-wider">Joined</th>
            <th class="text-left py-3 px-5 text-xs font-medium text-gray-500 uppercase tracking-wider">Action</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-gray-50">
          <tr v-for="emp in filteredEmployees" :key="emp.id" class="hover:bg-gray-50 transition-colors">
            <td class="py-4 px-5">
              <div class="flex items-center gap-3">
                <div :class="[emp.initialsColor, 'w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold flex-shrink-0']">
                  {{ emp.initials }}
                </div>
                <span class="font-medium text-gray-900">{{ emp.full_name || emp.email }}</span>
              </div>
            </td>
            <td class="py-4 px-5 text-gray-600">{{ emp.email }}</td>
            <td class="py-4 px-5">
              <span :class="[
                'px-3 py-1 rounded-full text-xs font-semibold capitalize',
                emp.role === 'admin' ? 'bg-red-50 text-red-700' :
                emp.role === 'manager' ? 'bg-blue-50 text-blue-700' :
                emp.role === 'cashier' ? 'bg-green-50 text-green-700' :
                'bg-gray-100 text-gray-600'
              ]">
                {{ emp.role || 'Staff' }}
              </span>
            </td>
            <td class="py-4 px-5 font-bold text-gray-900">{{ formatRM(emp.totalSales) }}</td>
            <td class="py-4 px-5 text-gray-600">{{ emp.joinedDate }}</td>
            <td class="py-4 px-5">
              <UButton icon="i-lucide-trash-2" color="neutral" variant="ghost" size="xs" @click="deleteEmployee(emp)" />
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Add Employee Modal -->
    <UModal v-model:open="isAddOpen">
      <template #content>
        <div class="p-6 bg-white">
          <h3 class="text-base font-semibold text-gray-900 mb-4">Add Employee</h3>
          <p class="text-sm text-gray-500 mb-4">This creates a new user account. The employee can log in with these credentials.</p>
          <div class="space-y-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1.5">Full Name</label>
              <UInput v-model="newEmployee.name" placeholder="Employee name" />
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1.5">Email <span class="text-red-500">*</span></label>
              <UInput v-model="newEmployee.email" type="email" placeholder="employee@store.com" />
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1.5">Password <span class="text-red-500">*</span></label>
              <UInput v-model="newEmployee.password" type="password" placeholder="••••••••" />
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1.5">Role</label>
              <select v-model="newEmployee.role" class="w-full h-10 px-3 rounded-lg border border-gray-300 text-sm focus:ring-2 focus:ring-primary outline-none">
                <option value="cashier">Cashier</option>
                <option value="manager">Manager</option>
                <option value="kitchen">Kitchen</option>
              </select>
            </div>
          </div>
          <div class="flex justify-end gap-3 mt-6 pt-4 border-t border-gray-100">
            <UButton color="neutral" variant="ghost" label="Cancel" @click="isAddOpen = false" />
            <UButton color="primary" label="Add Employee" :loading="saving" @click="saveEmployee" />
          </div>
        </div>
      </template>
    </UModal>
  </div>
</template>
