<script setup lang="ts">
definePageMeta({ layout: 'backoffice' })

const { client, outletId, profileReady } = useUserProfile()
const tables = ref<any[]>([])
const loading = ref(true)
const showAddModal = ref(false)
const newTableNumber = ref('')
const newTableColor = ref('#162456')
const showQrModal = ref(false)
const selectedTable = ref<any>(null)
const qrDataUrl = ref('')

const tableColors = [
  { name: 'Navy', value: '#162456' },
  { name: 'Blue', value: '#2563EB' },
  { name: 'Teal', value: '#0D9488' },
  { name: 'Green', value: '#16A34A' },
  { name: 'Purple', value: '#7C3AED' },
  { name: 'Pink', value: '#DB2777' },
  { name: 'Red', value: '#DC2626' },
  { name: 'Orange', value: '#EA580C' },
  { name: 'Amber', value: '#D97706' },
  { name: 'Slate', value: '#475569' },
]

const fetchTables = async () => {
  if (!outletId.value) return
  loading.value = true
  const { data } = await (client as any)
    .from('tables')
    .select('*')
    .eq('outlet_id', outletId.value)
    .order('table_number')
  tables.value = data || []
  loading.value = false
}

watch(profileReady, (ready) => { if (ready) fetchTables() }, { immediate: true })

const addTable = async () => {
  if (!newTableNumber.value || !outletId.value) return
  await (client as any).from('tables').insert({
    table_number: newTableNumber.value,
    outlet_id: outletId.value,
    color: newTableColor.value
  })
  newTableNumber.value = ''
  newTableColor.value = '#162456'
  showAddModal.value = false
  await fetchTables()
}

const deleteTable = async (table: any) => {
  if (!confirm(`Delete Table ${table.table_number}?`)) return
  await (client as any).from('tables').delete().eq('id', table.id)
  await fetchTables()
}

const toggleActive = async (table: any) => {
  await (client as any).from('tables').update({ is_active: !table.is_active }).eq('id', table.id)
  await fetchTables()
}

const getOrderUrl = (table: any) => {
  const base = window.location.origin
  return `${base}/order/${table.qr_token}`
}

const showQr = async (table: any) => {
  selectedTable.value = table
  showQrModal.value = true

  const QRCode = (await import('qrcode')).default
  const url = getOrderUrl(table)
  qrDataUrl.value = await QRCode.toDataURL(url, {
    width: 400,
    margin: 2,
    color: { dark: table.color || '#162456', light: '#ffffff' }
  })
}

const downloadQr = () => {
  if (!qrDataUrl.value || !selectedTable.value) return
  const link = document.createElement('a')
  link.download = `Table-${selectedTable.value.table_number}-QR.png`
  link.href = qrDataUrl.value
  link.click()
}

const printQr = () => {
  const w = window.open()
  if (!w) return
  w.document.write(`
    <html><head><title>Table ${selectedTable.value.table_number} QR</title>
    <style>body{display:flex;flex-direction:column;align-items:center;justify-content:center;min-height:100vh;font-family:system-ui;margin:0}
    img{width:300px} h1{margin-top:20px;font-size:24px} p{color:#666;margin-top:8px}</style></head>
    <body>
    <img src="${qrDataUrl.value}" />
    <h1>Table ${selectedTable.value.table_number}</h1>
    <p>Scan to order</p>
    </body></html>
  `)
  w.document.close()
  w.print()
}
</script>

<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex justify-between items-end">
      <div>
        <h2 class="text-2xl font-bold text-gray-900">Tables & QR Codes</h2>
        <p class="text-gray-500 text-sm mt-1">Manage your tables and generate QR codes for self-ordering.</p>
      </div>
      <UButton color="primary" label="Add Table" icon="i-lucide-plus" class="rounded-xl" @click="showAddModal = true" />
    </div>

    <!-- Empty State -->
    <div v-if="!loading && tables.length === 0" class="bg-white rounded-2xl shadow-sm border border-gray-100 p-16 text-center">
      <UIcon name="i-lucide-qr-code" class="w-12 h-12 mx-auto mb-4 text-gray-300" />
      <h3 class="text-lg font-semibold text-gray-900 mb-2">No tables yet</h3>
      <p class="text-gray-500 text-sm mb-6">Add tables to generate QR codes for self-ordering.</p>
      <UButton color="primary" label="Add First Table" icon="i-lucide-plus" @click="showAddModal = true" />
    </div>

    <!-- Table Grid -->
    <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
      <div
        v-for="table in tables"
        :key="table.id"
        :class="['bg-white rounded-2xl shadow-sm border p-5 transition-all hover:shadow-md',
          table.is_active ? 'border-gray-100' : 'border-dashed border-gray-300 opacity-60']"
      >
        <div class="flex items-start justify-between mb-4">
          <div class="flex items-center gap-3">
            <div
              class="w-12 h-12 rounded-xl flex items-center justify-center"
              :style="{ background: table.is_active ? (table.color || '#162456') : '#E5E7EB' }"
            >
              <UIcon name="i-lucide-grid-2x2" :class="['w-6 h-6', table.is_active ? 'text-white' : 'text-gray-400']" />
            </div>
            <div>
              <h4 class="font-semibold text-gray-900">{{ table.table_number }}</h4>
              <span :class="['text-xs font-medium', table.is_active ? 'text-green-600' : 'text-gray-400']">
                {{ table.is_active ? 'Active' : 'Inactive' }}
              </span>
            </div>
          </div>
        </div>

        <div class="flex items-center gap-2 mt-3">
          <UButton color="primary" variant="soft" icon="i-lucide-qr-code" label="QR Code" size="sm" class="rounded-lg flex-1" @click="showQr(table)" />
          <UButton color="neutral" variant="ghost" :icon="table.is_active ? 'i-lucide-eye-off' : 'i-lucide-eye'" size="sm" class="rounded-lg" @click="toggleActive(table)" />
          <UButton color="neutral" variant="ghost" icon="i-lucide-trash-2" size="sm" class="rounded-lg text-red-500" @click="deleteTable(table)" />
        </div>
      </div>
    </div>

    <!-- Add Table Modal -->
    <UModal v-model:open="showAddModal">
      <template #content>
        <div class="p-6 space-y-5">
          <h3 class="text-lg font-bold text-gray-900">Add New Table</h3>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1.5">Table Number / Name</label>
            <UInput v-model="newTableNumber" placeholder="e.g. 1, A1, VIP-1" size="xl" class="w-full" @keyup.enter="addTable" />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Table Color</label>
            <div class="flex flex-wrap gap-2">
              <button
                v-for="color in tableColors"
                :key="color.value"
                :class="['w-9 h-9 rounded-xl transition-all flex items-center justify-center',
                  newTableColor === color.value ? 'ring-2 ring-offset-2 ring-gray-400 scale-110' : 'hover:scale-105']"
                :style="{ background: color.value }"
                @click="newTableColor = color.value"
                :title="color.name"
              >
                <UIcon v-if="newTableColor === color.value" name="i-lucide-check" class="w-4 h-4 text-white" />
              </button>
            </div>
          </div>
          <div class="flex justify-end gap-3 pt-2">
            <UButton color="neutral" variant="ghost" label="Cancel" @click="showAddModal = false" />
            <UButton color="primary" label="Add Table" icon="i-lucide-plus" class="rounded-xl" @click="addTable" />
          </div>
        </div>
      </template>
    </UModal>

    <!-- QR Code Modal -->
    <UModal v-model:open="showQrModal">
      <template #content>
        <div class="p-6 text-center space-y-4" v-if="selectedTable">
          <h3 class="text-lg font-bold text-gray-900">Table {{ selectedTable.table_number }}</h3>
          <p class="text-sm text-gray-500">Scan this QR code to order from this table</p>

          <div class="flex justify-center">
            <img v-if="qrDataUrl" :src="qrDataUrl" alt="QR Code" class="w-64 h-64 rounded-xl border border-gray-200" />
          </div>

          <p class="text-xs text-gray-400 font-mono break-all px-4">{{ getOrderUrl(selectedTable) }}</p>

          <div class="flex justify-center gap-3 pt-2">
            <UButton color="primary" variant="soft" label="Download" icon="i-lucide-download" class="rounded-xl" @click="downloadQr" />
            <UButton color="primary" label="Print" icon="i-lucide-printer" class="rounded-xl" @click="printQr" />
          </div>
        </div>
      </template>
    </UModal>
  </div>
</template>
