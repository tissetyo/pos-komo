<script setup lang="ts">
definePageMeta({ layout: 'backoffice' })

const client = useSupabaseClient()
const user = useSupabaseUser()
const saving = ref(false)

const form = ref({
  name: '',
  category: '',
  price: '',
  sku: '',
  stock: '',
  description: ''
})

const categories = ref<any[]>([])
const outletId = ref<string | null>(null)

onMounted(async () => {
  if (!user.value) return
  const { data: profile } = await client.from('profiles').select('outlet_id').eq('id', user.value.id).single()
  outletId.value = profile?.outlet_id || null
  if (!outletId.value) return

  const { data: cats } = await client.from('categories').select('id, name').eq('outlet_id', outletId.value)
  categories.value = cats || []
})

const saveProduct = async () => {
  if (!form.value.name || !form.value.price || !outletId.value) return
  saving.value = true
  try {
    let categoryId = null
    if (form.value.category) {
      const existing = categories.value.find((c: any) => c.name === form.value.category)
      if (existing) {
        categoryId = existing.id
      } else {
        const { data: cat } = await client.from('categories').insert({ name: form.value.category, outlet_id: outletId.value }).select().single()
        if (cat) categoryId = cat.id
      }
    }

    await client.from('products').insert({
      name: form.value.name,
      price: parseInt(form.value.price),
      sku: form.value.sku || null,
      stock: form.value.stock ? parseInt(form.value.stock) : null,
      description: form.value.description || null,
      category_id: categoryId,
      outlet_id: outletId.value,
      is_active: true
    })

    navigateTo('/backoffice/products')
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <div class="max-w-2xl mx-auto">
    <!-- Header -->
    <div class="flex items-center gap-4 mb-8">
      <UButton to="/backoffice/products" color="neutral" variant="ghost" icon="i-lucide-arrow-left" class="rounded-xl" />
      <div>
        <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Add New Product</h2>
        <p class="text-gray-500 dark:text-gray-400 text-sm mt-1">Fill in the details to create a new product in your catalogue.</p>
      </div>
    </div>

    <!-- Form Card  -->
    <div class="bg-white dark:bg-gray-900 rounded-2xl shadow-sm border border-gray-100 dark:border-gray-800 p-8 space-y-6">

      <div>
        <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1.5">Product Name <span class="text-red-500">*</span></label>
        <UInput v-model="form.name" placeholder="e.g. Vanilla Ice Latte" size="xl" class="w-full" />
      </div>

      <div>
        <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1.5">Description</label>
        <UTextarea v-model="form.description" placeholder="Optional product description" class="w-full" autoresize />
      </div>

      <div class="grid grid-cols-2 gap-6">
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1.5">Category</label>
          <UInput v-model="form.category" placeholder="e.g. Coffee" size="xl" class="w-full" />
          <p v-if="categories.length > 0" class="text-xs text-gray-400 mt-1">
            Existing: {{ categories.map((c: any) => c.name).join(', ') }}
          </p>
        </div>
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1.5">Base Price <span class="text-red-500">*</span></label>
          <UInput v-model="form.price" type="number" placeholder="0" size="xl" class="w-full" />
        </div>
      </div>

      <div class="grid grid-cols-2 gap-6">
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1.5">SKU Code</label>
          <UInput v-model="form.sku" placeholder="Leave blank to auto-generate" size="xl" class="w-full" />
        </div>
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1.5">Initial Stock</label>
          <UInput v-model="form.stock" type="number" placeholder="Leave blank for unlimited" size="xl" class="w-full" />
        </div>
      </div>
    </div>

    <!-- Actions -->
    <div class="flex justify-end gap-4 mt-6">
      <UButton to="/backoffice/products" color="neutral" variant="ghost" label="Cancel" class="px-6 rounded-xl" />
      <UButton color="primary" label="Save Product" icon="i-lucide-check" class="px-8 rounded-xl font-bold" size="lg" :loading="saving" @click="saveProduct" />
    </div>
  </div>
</template>
