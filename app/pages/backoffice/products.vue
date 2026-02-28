<script setup lang="ts">
definePageMeta({ layout: 'backoffice' })

const client = useSupabaseClient()
const user = useSupabaseUser()
const products = ref<any[]>([])
const categories = ref<any[]>([])
const loading = ref(true)
const search = ref('')
const selectedCategoryFilter = ref('All Categories')
const isAddModalOpen = ref(false)

// New product form
const newProduct = ref({
  name: '',
  category: '',
  price: '',
  sku: '',
  stock: ''
})

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

    const { data: profile } = await client
      .from('profiles')
      .select('outlet_id')
      .eq('id', user.value.id)
      .single()

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

    // Fetch categories
    const { data: cats } = await client
      .from('categories')
      .select('id, name')
      .eq('outlet_id', outletId.value)

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
  await client
    .from('products')
    .update({ is_active: product.visible })
    .eq('id', product.id)
}

const savingProduct = ref(false)
const saveProduct = async () => {
  if (!newProduct.value.name || !newProduct.value.price || !outletId.value) return
  savingProduct.value = true

  try {
    // Create or find category
    let categoryId = null
    if (newProduct.value.category) {
      const existing = categories.value.find((c: any) => c.name === newProduct.value.category)
      if (existing) {
        categoryId = existing.id
      } else {
        const { data: cat } = await client
          .from('categories')
          .insert({ name: newProduct.value.category, outlet_id: outletId.value })
          .select()
          .single()
        if (cat) categoryId = cat.id
      }
    }

    await client
      .from('products')
      .insert({
        name: newProduct.value.name,
        price: parseInt(newProduct.value.price),
        sku: newProduct.value.sku || null,
        stock: newProduct.value.stock ? parseInt(newProduct.value.stock) : null,
        category_id: categoryId,
        outlet_id: outletId.value,
        is_active: true
      })

    isAddModalOpen.value = false
    newProduct.value = { name: '', category: '', price: '', sku: '', stock: '' }
    await fetchProducts()
  } finally {
    savingProduct.value = false
  }
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
      <UButton color="primary" label="New Product" icon="i-lucide-plus" @click="isAddModalOpen = true" />
    </div>

    <!-- Filters & Search -->
    <div class="bg-white dark:bg-gray-900 p-4 justify-between flex flex-col md:flex-row gap-4 items-center rounded-2xl shadow-sm border border-gray-100 dark:border-gray-800">
       <UInput v-model="search" icon="i-lucide-search" placeholder="Search products or SKU..." class="w-full md:w-80" />
       <div class="flex flex-wrap gap-2 text-sm w-full md:w-auto">
         <USelect v-model="selectedCategoryFilter" :options="categoryFilterOptions" class="w-48" />
       </div>
    </div>

    <!-- Empty State -->
    <div v-if="!loading && filteredProducts.length === 0" class="bg-white dark:bg-gray-900 rounded-2xl shadow-sm border border-gray-100 dark:border-gray-800 p-16 text-center">
      <UIcon name="i-lucide-package" class="w-12 h-12 mx-auto mb-4 text-gray-300 dark:text-gray-600" />
      <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-2">No products yet</h3>
      <p class="text-gray-500 dark:text-gray-400 text-sm mb-6">Add your first product to start selling.</p>
      <UButton color="primary" label="Add Product" icon="i-lucide-plus" @click="isAddModalOpen = true" />
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
          <span class="font-semibold text-gray-900 dark:text-white">
            Rp {{ row.price.toLocaleString('id-ID') }}
          </span>
        </template>

        <template #stock-data="{ row }">
          <div v-if="row.stock === null" class="text-gray-500 dark:text-gray-400"><UIcon name="i-lucide-infinity" class="w-4 h-4 ml-2" /></div>
          <div v-else :class="['font-medium', row.stock === 0 ? 'text-red-500' : 'text-gray-900 dark:text-white']">
            {{ row.stock }}
          </div>
        </template>

         <template #visible-data="{ row }">
          <div class="flex items-center gap-2">
            <UToggle :model-value="row.visible" color="primary" @update:model-value="toggleVisibility(row)" />
            <span class="text-xs text-gray-500 dark:text-gray-400 w-12">{{ row.visible ? 'Visible' : 'Hidden' }}</span>
          </div>
        </template>

        <template #actions-data="{ row }">
          <div class="flex justify-end gap-2 pr-4 text-gray-400">
             <UButton color="neutral" variant="ghost" icon="i-lucide-trash-2" size="xs" @click="deleteProduct(row)" />
          </div>
        </template>
      </UTable>
    </div>

    <!-- Add Product Modal -->
    <UModal v-model:open="isAddModalOpen">
      <template #content>
        <div class="p-6 bg-white dark:bg-gray-900">
          <div class="flex items-center justify-between mb-6">
            <h3 class="text-base font-semibold text-gray-900 dark:text-white">Create New Product</h3>
            <UButton color="neutral" variant="ghost" icon="i-lucide-x" @click="isAddModalOpen = false" />
          </div>

          <div class="space-y-4">
            <UFormGroup label="Product Name" required>
              <UInput v-model="newProduct.name" placeholder="e.g. Vanilla Ice Latte" />
            </UFormGroup>
            <div class="grid grid-cols-2 gap-4">
              <UFormGroup label="Category">
                <UInput v-model="newProduct.category" placeholder="e.g. Coffee" />
              </UFormGroup>
              <UFormGroup label="Base Price" required>
                <UInput v-model="newProduct.price" type="number" placeholder="0" />
              </UFormGroup>
            </div>
            <div class="grid grid-cols-2 gap-4">
              <UFormGroup label="SKU (Optional)">
                <UInput v-model="newProduct.sku" placeholder="Leave blank to auto-generate" />
              </UFormGroup>
              <UFormGroup label="Initial Stock">
                <UInput v-model="newProduct.stock" type="number" placeholder="Leave blank for unlimited" />
              </UFormGroup>
            </div>
          </div>

          <div class="flex justify-end gap-3 mt-6 pt-4 border-t border-gray-100 dark:border-gray-800">
            <UButton color="neutral" variant="ghost" label="Cancel" @click="isAddModalOpen = false" />
            <UButton color="primary" label="Save Product" :loading="savingProduct" @click="saveProduct" />
          </div>
        </div>
      </template>
    </UModal>
  </div>
</template>
