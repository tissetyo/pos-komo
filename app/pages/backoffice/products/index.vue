<script setup lang="ts">
definePageMeta({ layout: 'backoffice' })

const { client, outletId, profileReady } = useUserProfile()
const products = ref<any[]>([])
const categories = ref<any[]>([])
const loading = ref(true)
const search = ref('')
const selectedCategoryFilter = ref('All Categories')
const currentPage = ref(1)
const perPage = 10

const fetchProducts = async () => {
  loading.value = true
  try {
    if (!outletId.value) return

    const { data } = await client
      .from('products')
      .select('*, categories(name)')
      .eq('outlet_id', outletId.value)
      .order('created_at', { ascending: false })

    // Get variation counts
    const productIds = (data || []).map((p: any) => p.id)
    let varMap: Record<string, number> = {}
    if (productIds.length > 0) {
      const { data: vars } = await client
        .from('product_variations')
        .select('product_id')
        .in('product_id', productIds)
      ;(vars || []).forEach((v: any) => {
        varMap[v.product_id] = (varMap[v.product_id] || 0) + 1
      })
    }

    products.value = (data || []).map((p: any) => ({
      ...p,
      categoryName: p.categories?.name || 'Uncategorized',
      visible: p.is_active,
      variationCount: varMap[p.id] || 0
    }))

    const { data: cats } = await client.from('categories').select('id, name').eq('outlet_id', outletId.value)
    categories.value = cats || []
  } finally {
    loading.value = false
  }
}

watch(profileReady, (ready) => { if (ready) fetchProducts() })

const filteredProducts = computed(() => {
  return products.value.filter(p => {
    const matchSearch = p.name.toLowerCase().includes(search.value.toLowerCase()) || (p.sku || '').toLowerCase().includes(search.value.toLowerCase())
    const matchCategory = selectedCategoryFilter.value === 'All Categories' || p.categoryName === selectedCategoryFilter.value
    return matchSearch && matchCategory
  })
})

const paginatedProducts = computed(() => {
  const start = (currentPage.value - 1) * perPage
  return filteredProducts.value.slice(start, start + perPage)
})
const totalPages = computed(() => Math.ceil(filteredProducts.value.length / perPage))

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

const formatPrice = (price: number) => price.toLocaleString('en-MY')

const totalActive = computed(() => products.value.filter(p => p.visible).length)
const totalStock = computed(() => products.value.reduce((s, p) => s + (p.stock || 0), 0))
</script>

<template>
  <div class="space-y-6">
    <div class="flex justify-between items-start">
      <div>
        <h2 class="text-2xl font-bold text-gray-900">Products & Menu</h2>
        <p class="text-gray-500 text-sm mt-1">Manage your catalogue, pricing, inventory, and variants.</p>
      </div>
      <UButton to="/backoffice/products/new" color="primary" label="+ New Product" icon="i-lucide-plus" />
    </div>

    <!-- Pro Tip -->
    <div class="bg-blue-50 border border-blue-200 rounded-xl px-5 py-3 flex items-start gap-3">
      <UIcon name="i-lucide-lightbulb" class="w-5 h-5 text-blue-500 mt-0.5 flex-shrink-0" />
      <p class="text-sm text-blue-700">
        <span class="font-medium text-blue-900">Pro Tip:</span> Add product images and variations (sizes, temperatures) to make the cashier interface more visual. Toggle visibility to temporarily hide items from the POS.
      </p>
    </div>

    <!-- 3 Quick Stats -->
    <div class="grid grid-cols-3 gap-5">
      <div class="bg-white rounded-xl p-4 border border-gray-100 shadow-sm flex items-center gap-4">
        <div class="w-10 h-10 bg-blue-50 rounded-xl flex items-center justify-center">
          <UIcon name="i-lucide-package" class="w-5 h-5 text-blue-600" />
        </div>
        <div>
          <p class="text-sm text-gray-500">Total Products</p>
          <p class="text-xl font-bold text-gray-900">{{ products.length }}</p>
        </div>
      </div>
      <div class="bg-white rounded-xl p-4 border border-gray-100 shadow-sm flex items-center gap-4">
        <div class="w-10 h-10 bg-green-50 rounded-xl flex items-center justify-center">
          <UIcon name="i-lucide-eye" class="w-5 h-5 text-green-600" />
        </div>
        <div>
          <p class="text-sm text-gray-500">Active</p>
          <p class="text-xl font-bold text-gray-900">{{ totalActive }}</p>
        </div>
      </div>
      <div class="bg-white rounded-xl p-4 border border-gray-100 shadow-sm flex items-center gap-4">
        <div class="w-10 h-10 bg-amber-50 rounded-xl flex items-center justify-center">
          <UIcon name="i-lucide-boxes" class="w-5 h-5 text-amber-600" />
        </div>
        <div>
          <p class="text-sm text-gray-500">Total Stock</p>
          <p class="text-xl font-bold text-gray-900">{{ totalStock.toLocaleString() }}</p>
        </div>
      </div>
    </div>

    <!-- Filters -->
    <div class="bg-white p-4 justify-between flex gap-4 items-center rounded-xl shadow-sm border border-gray-100">
      <UInput v-model="search" icon="i-lucide-search" placeholder="Search products or SKU..." class="w-80" @input="currentPage = 1" />
      <select v-model="selectedCategoryFilter" @change="currentPage = 1" class="h-10 px-4 rounded-lg border border-gray-300 bg-white text-sm focus:ring-2 focus:ring-primary outline-none">
        <option v-for="opt in categoryFilterOptions" :key="opt" :value="opt">{{ opt }}</option>
      </select>
    </div>

    <!-- Empty State -->
    <div v-if="!loading && filteredProducts.length === 0" class="bg-white rounded-xl shadow-sm border border-gray-100 p-16 text-center">
      <UIcon name="i-lucide-package" class="w-12 h-12 mx-auto mb-4 text-gray-300" />
      <h3 class="text-lg font-semibold text-gray-900 mb-2">No products yet</h3>
      <p class="text-gray-500 text-sm mb-6">Add your first product to start selling.</p>
      <UButton to="/backoffice/products/new" color="primary" label="Add Product" icon="i-lucide-plus" />
    </div>

    <!-- Products Table -->
    <div v-else class="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
      <table class="w-full text-sm">
        <thead>
          <tr class="border-b border-gray-100">
            <th class="text-left py-4 px-5 text-xs font-medium text-gray-500 uppercase tracking-wider">Product</th>
            <th class="text-left py-4 px-5 text-xs font-medium text-gray-500 uppercase tracking-wider">Category</th>
            <th class="text-left py-4 px-5 text-xs font-medium text-gray-500 uppercase tracking-wider">Price</th>
            <th class="text-left py-4 px-5 text-xs font-medium text-gray-500 uppercase tracking-wider">Stock</th>
            <th class="text-left py-4 px-5 text-xs font-medium text-gray-500 uppercase tracking-wider">Variants</th>
            <th class="text-left py-4 px-5 text-xs font-medium text-gray-500 uppercase tracking-wider">Visible</th>
            <th class="text-left py-4 px-5 text-xs font-medium text-gray-500 uppercase tracking-wider">Action</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-gray-50">
          <tr v-for="product in paginatedProducts" :key="product.id" class="hover:bg-gray-50 transition-colors">
            <td class="py-4 px-5">
              <div class="flex items-center gap-3">
                <div class="w-10 h-10 rounded-lg bg-gray-100 flex items-center justify-center flex-shrink-0 overflow-hidden">
                  <img v-if="product.image_url" :src="product.image_url" :alt="product.name" class="w-full h-full object-cover" />
                  <UIcon v-else name="i-lucide-image" class="w-5 h-5 text-gray-400" />
                </div>
                <div>
                  <p class="font-medium text-gray-900">{{ product.name }}</p>
                  <p class="text-xs text-gray-500 uppercase tracking-wider">{{ product.sku || product.id.substring(0, 8) }}</p>
                </div>
              </div>
            </td>
            <td class="py-4 px-5">
              <span class="bg-gray-100 text-gray-700 px-3 py-1 rounded-full text-xs font-medium">{{ product.categoryName }}</span>
            </td>
            <td class="py-4 px-5 font-semibold text-gray-900">{{ formatPrice(product.price) }}</td>
            <td class="py-4 px-5">
              <span v-if="product.stock === null" class="text-gray-500">∞</span>
              <span v-else :class="product.stock === 0 ? 'text-red-500 font-medium' : 'text-gray-900'">{{ product.stock }}</span>
            </td>
            <td class="py-4 px-5">
              <span v-if="product.variationCount > 0" class="bg-purple-50 text-purple-700 px-2.5 py-1 rounded-full text-xs font-medium">
                {{ product.variationCount }} group{{ product.variationCount > 1 ? 's' : '' }}
              </span>
              <span v-else class="text-gray-400 text-xs">None</span>
            </td>
            <td class="py-4 px-5">
              <button
                :class="['relative inline-flex h-6 w-11 items-center rounded-full transition-colors',
                  product.visible ? 'bg-primary' : 'bg-gray-300']"
                @click="toggleVisibility(product)"
              >
                <span :class="['inline-block h-4 w-4 transform rounded-full bg-white transition-transform shadow',
                  product.visible ? 'translate-x-6' : 'translate-x-1']" />
              </button>
            </td>
            <td class="py-4 px-5">
              <div class="flex gap-1">
                <UButton color="neutral" variant="ghost" icon="i-lucide-trash-2" size="xs" @click="deleteProduct(product)" />
              </div>
            </td>
          </tr>
        </tbody>
      </table>

      <div v-if="totalPages > 1" class="flex items-center justify-between px-6 py-4 border-t border-gray-100">
        <p class="text-sm text-gray-500">{{ filteredProducts.length }} products</p>
        <div class="flex items-center gap-2">
          <button @click="currentPage = Math.max(1, currentPage - 1)" :disabled="currentPage === 1" class="px-4 py-2 text-sm rounded-lg border border-gray-200 text-gray-600 hover:bg-gray-50 disabled:opacity-40">Previous</button>
          <button @click="currentPage = Math.min(totalPages, currentPage + 1)" :disabled="currentPage >= totalPages" class="px-4 py-2 text-sm rounded-lg border border-gray-200 text-gray-600 hover:bg-gray-50 disabled:opacity-40">Next</button>
        </div>
      </div>
    </div>
  </div>
</template>
