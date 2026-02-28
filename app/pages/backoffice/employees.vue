<script setup lang="ts">
definePageMeta({ layout: 'backoffice' })

const client = useSupabaseClient()
const user = useSupabaseUser()
const employees = ref<any[]>([])
const loading = ref(true)
const search = ref('')
const activeFilter = ref('All Staff')

const filters = ['All Staff', 'High Rating', 'Low Attendance']

const isAddOpen = ref(false)
const newEmployee = ref({ name: '', email: '', password: '', role: 'cashier' })
const saving = ref(false)

const stats = ref([
  { label: 'TOTAL EMPLOYEES', value: '24 Staff', sub: '+2 New this month', subColor: 'text-green-600', icon: 'i-lucide-users', iconBg: 'bg-blue-50', iconColor: 'text-blue-600' },
  { label: 'AVG. ATTENDANCE', value: '94%', sub: '+1.5% vs last month', subColor: 'text-green-600', icon: 'i-lucide-calendar-check', iconBg: 'bg-green-50', iconColor: 'text-green-600' },
  { label: 'TOP PERFORMER', value: 'Sarah J.', sub: '482 Sales this week', subColor: 'text-gray-500', icon: 'i-lucide-trophy', iconBg: 'bg-amber-50', iconColor: 'text-amber-600' },
  { label: 'LATE ARRIVALS', value: '5', sub: '⚠ Action needed', subColor: 'text-red-500', icon: 'i-lucide-alarm-clock-off', iconBg: 'bg-red-50', iconColor: 'text-red-600' },
])

const checkIns = ref([
  { name: 'Sarah Jenkins', role: 'Head Barista', time: '08:55 AM', status: 'ON TIME', statusColor: 'bg-green-100 text-green-700', initials: 'SJ', initialsColor: 'bg-blue-100 text-blue-600' },
  { name: 'Michael Ross', role: 'Server', time: '09:02 AM', status: 'ON TIME', statusColor: 'bg-green-100 text-green-700', initials: 'MR', initialsColor: 'bg-purple-100 text-purple-600' },
  { name: 'Amy Lee', role: 'Cashier', time: '09:45 AM (+45m)', status: 'LATE', statusColor: 'bg-red-100 text-red-600', initials: 'AL', initialsColor: 'bg-orange-100 text-orange-600' },
  { name: 'David Kim', role: 'Kitchen Staff', time: '07:50 AM', status: 'ON TIME', statusColor: 'bg-green-100 text-green-700', initials: 'DK', initialsColor: 'bg-green-100 text-green-600' },
])

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

    employees.value = (data || []).map((e: any, i: number) => ({
      ...e,
      outletName: e.outlets?.name || '-',
      joinedDate: new Date(e.created_at).toLocaleDateString('en-MY', { day: 'numeric', month: 'short', year: 'numeric' }),
      status: 'Active',
      totalSales: 'RM ' + (12450 - i * 1200).toLocaleString(),
      attendance: '98%',
      rating: 4.9,
      initials: ((e.full_name || 'U').substring(0, 1) + ((e.full_name || '').split(' ')[1] || '').substring(0, 1)).toUpperCase() || 'U',
      initialsColor: ['bg-blue-100 text-blue-600', 'bg-purple-100 text-purple-600', 'bg-green-100 text-green-600'][i % 3]
    }))

    stats.value[0].value = employees.value.length + ' Staff'
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
  await client.from('profiles').update({ outlet_id: null }).eq('id', emp.id)
  await fetchEmployees()
}
</script>

<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex justify-between items-start">
      <div>
        <h2 class="text-2xl font-bold text-gray-900">Employee Report</h2>
        <p class="text-gray-500 text-sm mt-1">Manage staff roles, attendance, and performance.</p>
      </div>
      <div class="flex items-center gap-3">
        <UButton color="neutral" variant="outline" label="Export" icon="i-lucide-download" />
        <UButton color="primary" label="Update Report" icon="i-lucide-refresh-cw" />
      </div>
    </div>

    <!-- Filter Bar -->
    <div class="flex items-center gap-4">
      <div class="flex items-center gap-2 text-sm text-gray-500 bg-white border border-gray-200 px-4 py-2 rounded-lg">
        <UIcon name="i-lucide-calendar" class="w-4 h-4" />
        This Week <UIcon name="i-lucide-chevron-down" class="w-4 h-4" />
      </div>
      <div class="flex items-center gap-2 text-sm text-gray-500 bg-white border border-gray-200 px-4 py-2 rounded-lg">
        <UIcon name="i-lucide-clock" class="w-4 h-4" />
        All Shifts <UIcon name="i-lucide-chevron-down" class="w-4 h-4" />
      </div>
      <div class="flex items-center gap-2 text-sm text-gray-500 bg-white border border-gray-200 px-4 py-2 rounded-lg">
        <UIcon name="i-lucide-building" class="w-4 h-4" />
        All Outlets <UIcon name="i-lucide-chevron-down" class="w-4 h-4" />
      </div>
    </div>

    <!-- 4 Stat Cards -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-5">
      <div v-for="s in stats" :key="s.label" class="bg-white rounded-xl p-5 border border-gray-100 shadow-sm">
        <div class="flex items-start justify-between">
          <div>
            <p class="text-xs font-medium text-gray-500 uppercase tracking-wider">{{ s.label }}</p>
            <p class="text-2xl font-bold text-gray-900 mt-2">{{ s.value }}</p>
            <p class="text-sm mt-2" :class="s.subColor">{{ s.sub }}</p>
          </div>
          <div :class="[s.iconBg, s.iconColor, 'w-10 h-10 rounded-xl flex items-center justify-center']">
            <UIcon :name="s.icon" class="w-5 h-5" />
          </div>
        </div>
      </div>
    </div>

    <!-- Table + Check-ins -->
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
      <!-- Employee Performance Table -->
      <div class="lg:col-span-2 bg-white rounded-xl border border-gray-100 shadow-sm overflow-hidden">
        <div class="flex items-center justify-between px-6 py-4 border-b border-gray-100">
          <h3 class="font-semibold text-gray-900">Employee Performance</h3>
          <div class="flex gap-1">
            <button
              v-for="f in filters"
              :key="f"
              @click="activeFilter = f"
              :class="[
                'px-4 py-1.5 text-sm rounded-lg transition-colors',
                activeFilter === f ? 'bg-gray-900 text-white' : 'text-gray-500 hover:bg-gray-100 border border-gray-200'
              ]"
            >
              {{ f }}
            </button>
          </div>
        </div>
        <table class="w-full text-sm">
          <thead>
            <tr class="border-b border-gray-100">
              <th class="text-left py-3 px-5 text-xs font-medium text-gray-500 uppercase tracking-wider">Staff Name</th>
              <th class="text-left py-3 px-5 text-xs font-medium text-gray-500 uppercase tracking-wider">Role</th>
              <th class="text-left py-3 px-5 text-xs font-medium text-gray-500 uppercase tracking-wider">Total Sales</th>
              <th class="text-left py-3 px-5 text-xs font-medium text-gray-500 uppercase tracking-wider">Attendance %</th>
              <th class="text-left py-3 px-5 text-xs font-medium text-gray-500 uppercase tracking-wider">Rating</th>
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
              <td class="py-4 px-5 text-gray-600 capitalize">{{ emp.role || 'Staff' }}</td>
              <td class="py-4 px-5 font-bold text-gray-900">{{ emp.totalSales }}</td>
              <td class="py-4 px-5 text-green-600 font-semibold">{{ emp.attendance }}</td>
              <td class="py-4 px-5">
                <span class="flex items-center gap-1 text-gray-600">
                  <UIcon name="i-lucide-star" class="w-4 h-4 text-amber-400" />
                  {{ emp.rating }}
                </span>
              </td>
              <td class="py-4 px-5">
                <button class="text-sm text-primary hover:underline">View Details</button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Recent Check-ins -->
      <div class="bg-white rounded-xl border border-gray-100 shadow-sm">
        <div class="flex items-center justify-between px-5 py-4 border-b border-gray-100">
          <h3 class="font-semibold text-gray-900">Recent Check-ins</h3>
          <UIcon name="i-lucide-clock" class="w-5 h-5 text-gray-400" />
        </div>
        <div class="divide-y divide-gray-50">
          <div v-for="c in checkIns" :key="c.name" class="flex items-center gap-3 px-5 py-4">
            <div :class="[c.initialsColor, 'w-10 h-10 rounded-full flex items-center justify-center text-sm font-bold flex-shrink-0']">
              {{ c.initials }}
            </div>
            <div class="flex-1 min-w-0">
              <p class="font-medium text-gray-900 text-sm">{{ c.name }}</p>
              <p class="text-xs text-gray-500">{{ c.role }}</p>
              <p class="text-xs text-gray-400 mt-0.5">⏱ {{ c.time }}</p>
            </div>
            <span :class="[c.statusColor, 'px-2.5 py-1 rounded-full text-xs font-bold']">
              {{ c.status }}
            </span>
          </div>
        </div>
        <div class="px-5 py-3 border-t border-gray-100">
          <button class="w-full py-2 text-sm text-gray-600 border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors">
            View Full History
          </button>
        </div>
      </div>
    </div>

    <!-- Add Employee Modal -->
    <UModal v-model:open="isAddOpen">
      <template #content>
        <div class="p-6 bg-white">
          <h3 class="text-base font-semibold text-gray-900 mb-4">Add Employee</h3>
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
          <div class="flex justify-end gap-3 mt-6 pt-4 border-t border-gray-100">
            <UButton color="neutral" variant="ghost" label="Cancel" @click="isAddOpen = false" />
            <UButton color="primary" label="Add Employee" :loading="saving" @click="saveEmployee" />
          </div>
        </div>
      </template>
    </UModal>
  </div>
</template>
