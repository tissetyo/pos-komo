<script setup lang="ts">
definePageMeta({ layout: 'backoffice' })

const products = [
  { id: 'PRD-001', name: 'Komo Signature Iced Coffee', category: 'Signature', price: 28000, stock: 45, visible: true },
  { id: 'PRD-002', name: 'Iced Caramel Macchiato', category: 'Coffee', price: 32000, stock: 24, visible: true },
  { id: 'PRD-003', name: 'Hot Cafe Latte', category: 'Coffee', price: 25000, stock: 0, visible: false },
  { id: 'PRD-004', name: 'Iced Matcha Latte', category: 'Non-Coffee', price: 30000, stock: 12, visible: true },
  { id: 'PRD-005', name: 'Lychee Tea', category: 'Tea', price: 22000, stock: null, visible: true }, // null means always available
  { id: 'PRD-006', name: 'Butter Croissant', category: 'Pastry', price: 20000, stock: 8, visible: true },
  { id: 'PRD-007', name: 'Brownie Bites', category: 'Snacks', price: 18000, stock: 15, visible: true },
]

const columns = [
  { id: 'name', key: 'name', label: 'Product Info' },
  { id: 'category', key: 'category', label: 'Category' },
  { id: 'price', key: 'price', label: 'Base Price' },
  { id: 'stock', key: 'stock', label: 'Stock' },
  { id: 'visible', key: 'visible', label: 'Visibility' },
  { id: 'actions', key: 'actions', label: '' }
]

const search = ref('')
const isAddModalOpen = ref(false)
const selectedCategoryFilter = ref('All Categories')
</script>

<template>
  <div class="space-y-6">
    <div class="flex justify-between items-end">
      <div>
        <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Products & Menu</h2>
        <p class="text-gray-500 text-sm mt-1">Manage your catalogue, pricing, inventory, and variants.</p>
      </div>
      <UButton color="primary" label="New Product" icon="i-lucide-plus" @click="isAddModalOpen = true" />
    </div>

    <!-- Filters & Search -->
    <div class="bg-white dark:bg-gray-900 p-4 justify-between flex flex-col md:flex-row gap-4 items-center rounded-2xl shadow-sm border border-gray-100 dark:border-gray-800">
       <UInput v-model="search" icon="i-lucide-search" placeholder="Search products or SKU..." class="w-full md:w-80" />
       <div class="flex flex-wrap gap-2 text-sm text-gray-600 w-full md:w-auto">
         <USelectMenu v-model="selectedCategoryFilter" :options="['All Categories', 'Signature', 'Coffee', 'Non-Coffee', 'Tea', 'Pastry', 'Snacks']" class="w-48" />
         <UButton color="gray" variant="ghost" icon="i-lucide-arrow-down-up" label="Sort" />
       </div>
    </div>

    <!-- Data Table -->
    <div class="bg-white dark:bg-gray-900 rounded-2xl shadow-sm border border-gray-100 dark:border-gray-800 overflow-hidden">
      <UTable :rows="products" :columns="columns" :ui="{ td: { padding: 'py-4 px-6' }, th: { padding: 'py-4 px-6 text-gray-500 font-medium bg-gray-50/50 dark:bg-gray-900/50' } }">
        <template #name-data="{ row }">
          <div class="flex items-center gap-3">
            <div class="w-10 h-10 rounded-lg bg-gray-100 flex items-center justify-center flex-shrink-0">
               <UIcon name="i-lucide-image" class="w-5 h-5 text-gray-400" />
            </div>
            <div>
              <p class="font-medium text-gray-900 dark:text-white">{{ row.name }}</p>
              <p class="text-xs text-gray-500 uppercase tracking-widest">{{ row.id }}</p>
            </div>
          </div>
        </template>
        
        <template #category-data="{ row }">
          <UBadge color="gray" variant="soft" class="font-medium">{{ row.category }}</UBadge>
        </template>

        <template #price-data="{ row }">
          <span class="font-semibold text-gray-900 dark:text-white">
            Rp {{ row.price.toLocaleString('id-ID') }}
          </span>
        </template>
        
        <template #stock-data="{ row }">
          <div v-if="row.stock === null" class="text-gray-500"><UIcon name="i-lucide-infinity" class="w-4 h-4 ml-2" /></div>
          <div v-else :class="['font-medium', row.stock === 0 ? 'text-red-500' : 'text-gray-900 dark:text-white']">
            {{ row.stock }}
          </div>
        </template>

         <template #visible-data="{ row }">
          <div class="flex items-center gap-2">
            <UToggle v-model="row.visible" color="primary" size="md" />
            <span class="text-xs text-gray-500 w-12">{{ row.visible ? 'Visible' : 'Hidden' }}</span>
          </div>
        </template>

        <template #actions-data="{ row }">
          <div class="flex justify-end gap-2 pr-4 text-gray-400">
             <UButton color="gray" variant="ghost" icon="i-lucide-edit" size="xs" tooltip="Edit Product & Variants" />
             <UButton color="gray" variant="ghost" icon="i-lucide-copy" size="xs" tooltip="Duplicate" />
          </div>
        </template>
      </UTable>
    </div>

    <!-- Add Product Modal (US-012, US-013) -->
    <UModal v-model="isAddModalOpen">
      <UCard :ui="{ ring: '', divide: 'divide-y divide-gray-100 dark:divide-gray-800' }">
        <template #header>
          <div class="flex items-center justify-between">
            <h3 class="text-base font-semibold leading-6 text-gray-900">
              Create New Product
            </h3>
            <UButton color="gray" variant="ghost" icon="i-lucide-x" class="-my-1" @click="isAddModalOpen = false" />
          </div>
        </template>

        <div class="space-y-4 max-h-[60vh] overflow-y-auto px-1 custom-scrollbar">
           <UFormGroup label="Product Name" required>
              <UInput placeholder="e.g. Vanilla Ice Latte" />
            </UFormGroup>
            <div class="grid grid-cols-2 gap-4">
              <UFormGroup label="Category" required>
                 <USelectMenu placeholder="Select Category" :options="['Signature', 'Coffee', 'Non-Coffee', 'Tea', 'Pastry', 'Snacks']" />
              </UFormGroup>
              <UFormGroup label="Base Price" required>
                 <UInput type="number" placeholder="0" leading-icon="i-lucide-rupiah" />
              </UFormGroup>
            </div>
            <div class="grid grid-cols-2 gap-4">
               <UFormGroup label="SKU (Optional)">
                 <UInput placeholder="Leave blank to auto-generate" />
               </UFormGroup>
               <UFormGroup label="Initial Stock">
                 <UInput type="number" placeholder="Leave blank for unlimited" />
               </UFormGroup>
            </div>

            <!-- Variants (US-013) -->
            <div class="pt-4 mt-4 border-t border-gray-100">
               <div class="flex items-center justify-between mb-2">
                 <label class="block text-sm font-medium text-gray-700">Variants & Modifiers</label>
                 <UButton color="primary" variant="soft" size="xs" icon="i-lucide-plus" label="Add Group" />
               </div>
               <div class="bg-gray-50 border border-gray-200 rounded-lg p-3">
                  <div class="flex items-center justify-between mb-2">
                    <UInput value="Size" class="w-32" size="sm" />
                    <UToggle color="primary" size="sm" :model-value="true" />
                    <span class="text-xs text-gray-500 mr-auto ml-2">Required</span>
                    <UButton color="red" variant="ghost" size="xs" icon="i-lucide-trash" />
                  </div>
                  <div class="space-y-2 pl-4 border-l-2 border-gray-200 ml-2 mt-2">
                     <div class="flex items-center gap-2">
                       <UInput value="Regular" size="xs" class="w-32" />
                       <UInput value="0" type="number" size="xs" class="w-24" placeholder="+Price" />
                        <UButton color="red" variant="ghost" size="xs" icon="i-lucide-x" />
                     </div>
                     <div class="flex items-center gap-2">
                       <UInput value="Large" size="xs" class="w-32" />
                       <UInput value="5000" type="number" size="xs" class="w-24" placeholder="+Price" />
                        <UButton color="red" variant="ghost" size="xs" icon="i-lucide-x" />
                     </div>
                     <UButton color="gray" variant="link" size="xs" icon="i-lucide-plus" label="Add Option" />
                  </div>
               </div>
            </div>
        </div>

        <template #footer>
           <div class="flex justify-end gap-3">
              <UButton color="gray" variant="ghost" label="Cancel" @click="isAddModalOpen = false" />
              <UButton color="primary" label="Save Product" />
           </div>
        </template>
      </UCard>
    </UModal>

  </div>
</template>

<style scoped>
.custom-scrollbar::-webkit-scrollbar { width: 6px; }
.custom-scrollbar::-webkit-scrollbar-track { background: transparent; }
.custom-scrollbar::-webkit-scrollbar-thumb { background-color: #cbd5e1; border-radius: 20px; }
</style>
