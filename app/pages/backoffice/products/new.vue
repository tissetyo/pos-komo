<script setup lang="ts">
definePageMeta({ layout: 'backoffice' })

const client = useSupabaseClient()
const user = useSupabaseUser()
const saving = ref(false)

const form = ref({
  name: '',
  category: '',
  price: '',
  cost: '',
  sku: '',
  stock: '',
  description: ''
})

const categories = ref<any[]>([])
const outletId = ref<string | null>(null)

// Image upload
const imageFile = ref<File | null>(null)
const imagePreview = ref<string | null>(null)

const onImageSelect = (e: Event) => {
  const target = e.target as HTMLInputElement
  if (target.files && target.files[0]) {
    imageFile.value = target.files[0]
    imagePreview.value = URL.createObjectURL(target.files[0])
  }
}

const removeImage = () => {
  imageFile.value = null
  imagePreview.value = null
}

// Variations — dynamic groups
const variations = ref<{ label: string; options: { name: string; price_adj: string }[] }[]>([])

const addVariation = () => {
  variations.value.push({ label: '', options: [{ name: '', price_adj: '0' }] })
}

const removeVariation = (index: number) => {
  variations.value.splice(index, 1)
}

const addOption = (varIndex: number) => {
  variations.value[varIndex].options.push({ name: '', price_adj: '0' })
}

const removeOption = (varIndex: number, optIndex: number) => {
  variations.value[varIndex].options.splice(optIndex, 1)
}

const loadProfile = async () => {
  if (!user.value?.id) return
  const { data: profile } = await client.from('profiles').select('outlet_id').eq('id', user.value.id).single()
  outletId.value = profile?.outlet_id || null
  if (!outletId.value) return

  const { data: cats } = await client.from('categories').select('id, name').eq('outlet_id', outletId.value)
  categories.value = cats || []
}

onMounted(loadProfile)

// Retry if user wasn't ready at mount
watch(user, (val) => {
  if (val?.id && !outletId.value) loadProfile()
}, { immediate: false })

const saveProduct = async () => {
  if (!form.value.name) { alert('Please enter a product name'); return }
  if (!form.value.price) { alert('Please enter a price'); return }

  // Retry getting outletId if it's not set
  if (!outletId.value && user.value?.id) {
    await loadProfile()
  }
  if (!outletId.value) { alert('Could not determine your store. Please reload the page and try again.'); return }
  saving.value = true
  try {
    // 1. Resolve or create category
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

    // 2. Upload image if provided
    let imageUrl = null
    if (imageFile.value) {
      const ext = imageFile.value.name.split('.').pop()
      const path = `${outletId.value}/${Date.now()}.${ext}`
      const { error: uploadErr } = await client.storage.from('product-images').upload(path, imageFile.value)
      if (!uploadErr) {
        const { data: urlData } = client.storage.from('product-images').getPublicUrl(path)
        imageUrl = urlData.publicUrl
      }
    }

    // 3. Insert product
    const { data: product } = await client.from('products').insert({
      name: form.value.name,
      price: parseInt(form.value.price),
      cost: form.value.cost ? parseInt(form.value.cost) : null,
      sku: form.value.sku || null,
      stock: form.value.stock ? parseInt(form.value.stock) : null,
      description: form.value.description || null,
      category_id: categoryId,
      outlet_id: outletId.value,
      image_url: imageUrl,
      is_active: true
    }).select().single()

    // 4. Insert variations
    if (product) {
      const validVars = variations.value.filter(v => v.label && v.options.some(o => o.name))
      for (const v of validVars) {
        const options = v.options
          .filter(o => o.name)
          .map(o => ({ name: o.name, price_adj: parseInt(o.price_adj) || 0 }))
        if (options.length > 0) {
          await client.from('product_variations').insert({
            product_id: product.id,
            label: v.label,
            options
          })
        }
      }
    }

    navigateTo('/backoffice/products')
  } catch (err: any) {
    alert(err.message || 'Failed to save product')
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <div class="max-w-3xl mx-auto">
    <!-- Header -->
    <div class="flex items-center gap-4 mb-8">
      <UButton to="/backoffice/products" color="neutral" variant="ghost" icon="i-lucide-arrow-left" />
      <div>
        <h2 class="text-2xl font-bold text-gray-900">Add New Product</h2>
        <p class="text-gray-500 text-sm mt-1">Fill in the details to create a new product in your catalogue.</p>
      </div>
    </div>

    <!-- Pro Tip -->
    <div class="bg-blue-50 border border-blue-200 rounded-xl px-5 py-3 flex items-start gap-3 mb-6">
      <UIcon name="i-lucide-lightbulb" class="w-5 h-5 text-blue-500 mt-0.5 flex-shrink-0" />
      <p class="text-sm text-blue-700">
        <span class="font-medium text-blue-900">Pro Tip:</span> Add variations for items with options like Hot/Cold or S/M/L sizes. Each option can have a price adjustment (e.g. +500 for Cold).
      </p>
    </div>

    <!-- Main Form -->
    <div class="bg-white rounded-xl shadow-sm border border-gray-100 p-8 space-y-6">
      <!-- Image Upload -->
      <div>
        <label class="block text-sm font-medium text-gray-700 mb-2">Product Image</label>
        <div class="flex items-start gap-4">
          <div class="w-24 h-24 rounded-xl border-2 border-dashed border-gray-300 flex items-center justify-center overflow-hidden bg-gray-50 flex-shrink-0">
            <img v-if="imagePreview" :src="imagePreview" class="w-full h-full object-cover" />
            <UIcon v-else name="i-lucide-image-plus" class="w-8 h-8 text-gray-400" />
          </div>
          <div>
            <label class="inline-flex items-center gap-2 px-4 py-2 bg-white border border-gray-300 rounded-lg text-sm font-medium text-gray-700 hover:bg-gray-50 cursor-pointer transition-colors">
              <UIcon name="i-lucide-upload" class="w-4 h-4" />
              Choose Image
              <input type="file" accept="image/*" class="hidden" @change="onImageSelect" />
            </label>
            <p class="text-xs text-gray-500 mt-1">JPG, PNG up to 2MB. Recommended 400×400px.</p>
            <button v-if="imagePreview" @click="removeImage" class="text-xs text-red-500 hover:underline mt-1">Remove</button>
          </div>
        </div>
      </div>

      <div>
        <label class="block text-sm font-medium text-gray-700 mb-1.5">Product Name <span class="text-red-500">*</span></label>
        <UInput v-model="form.name" placeholder="e.g. Vanilla Ice Latte" class="w-full" />
      </div>

      <div>
        <label class="block text-sm font-medium text-gray-700 mb-1.5">Description</label>
        <UTextarea v-model="form.description" placeholder="Optional product description" class="w-full" autoresize />
      </div>

      <div class="grid grid-cols-2 gap-6">
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1.5">Category</label>
          <UInput v-model="form.category" placeholder="e.g. Coffee" class="w-full" />
          <p v-if="categories.length > 0" class="text-xs text-gray-400 mt-1">
            Existing: {{ categories.map((c: any) => c.name).join(', ') }}
          </p>
        </div>
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1.5">Base Price <span class="text-red-500">*</span></label>
          <UInput v-model="form.price" type="number" placeholder="0" class="w-full" />
        </div>
      </div>

      <div class="grid grid-cols-3 gap-6">
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1.5">Cost Price</label>
          <UInput v-model="form.cost" type="number" placeholder="For COGS calculation" class="w-full" />
        </div>
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1.5">SKU Code</label>
          <UInput v-model="form.sku" placeholder="Auto-generate if blank" class="w-full" />
        </div>
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1.5">Initial Stock</label>
          <UInput v-model="form.stock" type="number" placeholder="∞ if blank" class="w-full" />
        </div>
      </div>
    </div>

    <!-- Variations Section -->
    <div class="bg-white rounded-xl shadow-sm border border-gray-100 p-8 mt-6">
      <div class="flex justify-between items-center mb-4">
        <div>
          <h3 class="text-lg font-semibold text-gray-900">Variations</h3>
          <p class="text-sm text-gray-500">Add option groups like Temperature, Size, Sugar Level</p>
        </div>
        <UButton color="neutral" variant="outline" label="+ Add Group" icon="i-lucide-plus" @click="addVariation" />
      </div>

      <div v-if="variations.length === 0" class="text-center py-8 text-gray-400 border-2 border-dashed border-gray-200 rounded-xl">
        <UIcon name="i-lucide-layers" class="w-8 h-8 mx-auto mb-2 opacity-40" />
        <p class="text-sm">No variations yet. Click "Add Group" to create options like Hot/Cold or S/M/L.</p>
      </div>

      <div v-else class="space-y-6">
        <div v-for="(variation, vi) in variations" :key="vi" class="border border-gray-200 rounded-xl p-5">
          <div class="flex items-center justify-between mb-4">
            <div class="flex-1 mr-4">
              <label class="block text-xs font-medium text-gray-500 uppercase mb-1">Group Name</label>
              <UInput v-model="variation.label" placeholder='e.g. "Temperature", "Size", "Sugar Level"' class="w-full" />
            </div>
            <UButton icon="i-lucide-trash-2" color="neutral" variant="ghost" size="sm" @click="removeVariation(vi)" />
          </div>

          <div class="space-y-2">
            <div v-for="(option, oi) in variation.options" :key="oi" class="flex items-center gap-3">
              <div class="flex-1">
                <UInput v-model="option.name" :placeholder="'Option ' + (oi + 1) + ' (e.g. Hot, Cold, Small, Large)'" class="w-full" />
              </div>
              <div class="w-32">
                <UInput v-model="option.price_adj" type="number" placeholder="+/- price" class="w-full" />
              </div>
              <UButton v-if="variation.options.length > 1" icon="i-lucide-x" color="neutral" variant="ghost" size="xs" @click="removeOption(vi, oi)" />
            </div>
          </div>

          <button @click="addOption(vi)" class="mt-3 text-sm text-primary hover:underline flex items-center gap-1">
            <UIcon name="i-lucide-plus" class="w-3 h-3" /> Add Option
          </button>
        </div>
      </div>
    </div>

    <!-- Actions -->
    <div class="flex justify-end gap-4 mt-6 mb-8">
      <UButton to="/backoffice/products" color="neutral" variant="ghost" label="Cancel" class="px-6" />
      <UButton color="primary" label="Save Product" icon="i-lucide-check" class="px-8 font-bold" size="lg" :loading="saving" @click="saveProduct" />
    </div>
  </div>
</template>
