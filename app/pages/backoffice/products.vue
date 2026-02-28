<script setup lang="ts">
definePageMeta({ layout: 'backoffice' })

const client = useSupabaseClient()
const user = useSupabaseUser()
const products = ref<any[]>([])
const categories = ref<any[]>([])
const loading = ref(true)
const search = ref('')
const selectedCategoryFilter = ref('All Categories')
const outletId = ref<string | null>(null)

const columns = [
  { id: 'name', key: 'name', label: 'Product Info' },
  { id: 'category', key: 'category', label: 'Category' },
  { id: 'price', key: 'price', label: 'Base Price' },
  { id: 'stock', key: 'stock', label: 'Stock' },
  { id: 'visible', key: 'visible', label: 'Visibility' },
  { id: 'actions', key: 'actions', label: '' }
]

const fetchProducts = async () => {
  loading.value = true
  try {
    if (!user.value) return
    const { data: profile } = await client.from('profiles').select('outlet_id').eq('id', user.value.id).single()
    outletId.value = profile?.outlet_id || null
    if (!outletId.value) return

    const { data } = await client
      .from('products')
      .select('*, categories(name)')
      .eq('outlet_id', outletId.value)
      .order('created_at', { ascending: false })

    products.value = (data || []).map((p: any) => ({
      ...p,
      categoryName: p.categories?.name || 'Uncategorized',
      visible: p.is_active
    }))

    const { data: cats } = await client.from('categories').select('id, name').eq('outlet_id', outletId.value)
    categories.value = cats || []
  } finally {
    loading.value = false
  }
}

onMounted(fetchProducts)

const filteredProducts = computed(() => {
  return products.value.filter(p => {
    const matchSearch = p.name.toLowerCase().includes(search.value.toLowerCase()) || (p.sku || '').toLowerCase().includes(search.value.toLowerCase())
    const matchCategory = selectedCategoryFilter.value === 'All Categories' || p.categoryName === selectedCategoryFilter.value
    return matchSearch && matchCategory
  })
})

const categoryFilterOptions = computed(() => {
  const names = categories.value.map((c: any) => c.name)
  return ['All Categories', ...names]
})

const toggleVisibility = async (product: any) => {
  product.visible = !product.visible
  await client.from('products').update({ is_active: product.visible }).eq('id', product.id)
}

const deleteProduct = async (product: any) => {
  if (!confirm(`Delete "${product.name}"?`)) return
  await client.from('products').delete().eq('id', product.id)
  await fetchProducts()
}
</script>

<template>
  <div class="space-y-6">
    <div class="flex justify-between items-end">
      <div>
        <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Products & Menu</h2>
        <p class="text-gray-500 dark:text-gray-400 text-sm mt-1">Manage your catalogue, pricing, inventory, and variants.</p>
      </div>
      <UButton to="/backoffice/products/new" color="primary" label="New Product" icon="i-lucide-plus" class="rounded-xl" />
    </div>

    <!-- Filters & Search -->
    <div class="bg-white dark:bg-gray-900 p-4 justify-between flex flex-col md:flex-row gap-4 items-center rounded-2xl shadow-sm border border-gray-100 dark:border-gray-800">
       <UInput v-model="search" icon="i-lucide-search" placeholder="Search products or SKU..." class="w-full md:w-80" />
       <div class="flex flex-wrap gap-2 text-sm w-full md:w-auto">
         <select v-model="selectedCategoryFilter" class="h-10 px-4 rounded-xl border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 text-gray-900 dark:text-white text-sm focus:ring-2 focus:ring-primary outline-none">
           <option v-for="opt in categoryFilterOptions" :key="opt" :value="opt">{{ opt }}</option>
         </select>
       </div>
    </div>

    <!-- Empty State -->
    <div v-if="!loading && filteredProducts.length === 0" class="bg-white dark:bg-gray-900 rounded-2xl shadow-sm border border-gray-100 dark:border-gray-800 p-16 text-center">
      <UIcon name="i-lucide-package" class="w-12 h-12 mx-auto mb-4 text-gray-300 dark:text-gray-600" />
      <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-2">No products yet</h3>
      <p class="text-gray-500 dark:text-gray-400 text-sm mb-6">Add your first product to start selling.</p>
      <UButton to="/backoffice/products/new" color="primary" label="Add Product" icon="i-lucide-plus" />
    </div>

    <!-- Data Table -->
    <div v-else class="bg-white dark:bg-gray-900 rounded-2xl shadow-sm border border-gray-100 dark:border-gray-800 overflow-hidden">
      <UTable :rows="filteredProducts" :columns="columns" :loading="loading">
        <template #name-data="{ row }">
          <div class="flex items-center gap-3">
            <div class="w-10 h-10 rounded-lg bg-gray-100 dark:bg-gray-800 flex items-center justify-center flex-shrink-0">
               <UIcon name="i-lucide-image" class="w-5 h-5 text-gray-400 dark:text-gray-500" />
            </div>
            <div>
              <p class="font-medium text-gray-900 dark:text-white">{{ row.name }}</p>
              <p class="text-xs text-gray-500 dark:text-gray-400 uppercase tracking-widest">{{ row.sku || row.id.substring(0, 8) }}</p>
            </div>
          </div>
        </template>

        <template #category-data="{ row }">
          <UBadge color="neutral" variant="soft" class="font-medium">{{ row.categoryName }}</UBadge>
        </template>

        <template #price-data="{ row }">
          <span class="font-semibold text-gray-900 dark:text-white">{{ row.price.toLocaleString('en-MY') }}</span>
        </template>

        <template #stock-data="{ row }">
          <div v-if="row.stock === null" class="text-gray-500 dark:text-gray-400"><UIcon name="i-lucide-infinity" class="w-4 h-4 ml-2" /></div>
          <div v-else :class="['font-medium', row.stock === 0 ? 'text-red-500' : 'text-gray-900 dark:text-white']">{{ row.stock }}</div>
        </template>

        <template #visible-data="{ row }">
          <button
            :class="['relative inline-flex h-6 w-11 items-center rounded-full transition-colors',
              row.visible ? 'bg-primary' : 'bg-gray-300 dark:bg-gray-600']"
            @click="toggleVisibility(row)"
          >
            <span :class="['inline-block h-4 w-4 transform rounded-full bg-white transition-transform shadow',
              row.visible ? 'translate-x-6' : 'translate-x-1']" />
          </button>
        </template>

        <template #actions-data="{ row }">
          <div class="flex justify-end gap-2 pr-4 text-gray-400">
             <UButton color="neutral" variant="ghost" icon="i-lucide-trash-2" size="xs" @click="deleteProduct(row)" />
          </div>
        </template>
      </UTable>
    </div>
  </div>
</template>
