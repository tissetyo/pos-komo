<script setup lang="ts">
definePageMeta({
  layout: 'cashier'
})

const client = useSupabaseClient()
const user = useSupabaseUser()

// Data from Supabase
const products = ref<any[]>([])
const categories = ref<string[]>(['All Items'])
const activeCategory = ref('All Items')
const searchQuery = ref('')
const loading = ref(true)
const outletId = ref<string | null>(null)

// Category icons
const categoryIcons: Record<string, string> = {
  'All Items': 'i-lucide-grid',
  'Coffee': 'i-lucide-coffee',
  'Tea': 'i-lucide-cup-soda',
  'Pastries': 'i-lucide-cake-slice',
  'Main Course': 'i-lucide-utensils-crossed',
  'Desserts': 'i-lucide-ice-cream-cone',
  'Cold Drinks': 'i-lucide-glass-water',
  'Other': 'i-lucide-package',
}

// Order State
const orderItems = ref<any[]>([])
const isCharging = ref(false)
const orderCompleted = ref(false)
const orderNumber = ref('#3820')

const formatCurrency = (amount: number) => {
  return 'MYR' + amount.toFixed(2)
}

// Load products from Supabase
onMounted(async () => {
  if (!user.value) return
  try {
    const { data: profile } = await client.from('profiles').select('outlet_id').eq('id', user.value.id).single()
    outletId.value = profile?.outlet_id || null
    if (!outletId.value) {
      loading.value = false
      return
    }

    const { data } = await client
      .from('products')
      .select('*, categories(name)')
      .eq('outlet_id', outletId.value)
      .eq('is_active', true)
      .order('name')

    products.value = (data || []).map((p: any) => ({
      id: p.id,
      name: p.name,
      description: p.description || '',
      price: p.price,
      category: p.categories?.name || 'Other',
      image: p.image_url || null,
      stock: p.stock
    }))

    // Build categories
    const cats = new Set(products.value.map(p => p.category))
    categories.value = ['All Items', ...Array.from(cats)]
  } finally {
    loading.value = false
  }
})

const filteredProducts = computed(() => {
  return products.value.filter(p => {
    const matchCategory = activeCategory.value === 'All Items' || p.category === activeCategory.value
    const matchSearch = p.name.toLowerCase().includes(searchQuery.value.toLowerCase())
    return matchCategory && matchSearch
  })
})

const subtotal = computed(() => orderItems.value.reduce((acc, item) => acc + (item.price * item.quantity), 0))
const discount = computed(() => 0)
const tax = computed(() => Math.round(subtotal.value * 0.10 * 100) / 100)
const total = computed(() => subtotal.value - discount.value + tax.value)

const addToOrder = (product: any) => {
  const existing = orderItems.value.find(item => item.id === product.id)
  if (existing) {
    existing.quantity++
  } else {
    orderItems.value.push({ id: product.id, name: product.name, price: product.price, quantity: 1, image: product.image })
  }
}

const updateQuantity = (item: any, delta: number) => {
  const index = orderItems.value.findIndex(i => i.id === item.id)
  if (index !== -1) {
    orderItems.value[index].quantity += delta
    if (orderItems.value[index].quantity <= 0) {
      orderItems.value.splice(index, 1)
    }
  }
}

const clearOrder = () => {
  orderItems.value = []
  orderCompleted.value = false
}

const chargeOrder = async () => {
  if (orderItems.value.length === 0 || !user.value || !outletId.value) return
  isCharging.value = true

  try {
    const receiptNumber = 'TRX-' + Date.now().toString().slice(-6)

    const { data: order, error: orderErr } = await client
      .from('orders')
      .insert({
        receipt_number: receiptNumber,
        outlet_id: outletId.value,
        cashier_id: user.value.id,
        subtotal: subtotal.value,
        tax: tax.value,
        discount: 0,
        total: total.value,
        payment_method: 'cash',
        payment_status: 'paid',
        order_status: 'completed',
        order_type: 'dine-in'
      })
      .select()
      .single()

    if (orderErr) throw orderErr

    const items = orderItems.value.map(item => ({
      order_id: order.id,
      product_id: item.id,
      quantity: item.quantity,
      unit_price: item.price,
      total_price: item.price * item.quantity
    }))

    const { error: itemsErr } = await client.from('order_items').insert(items)
    if (itemsErr) throw itemsErr

    orderCompleted.value = true
    setTimeout(() => {
      orderItems.value = []
      orderCompleted.value = false
    }, 2000)
  } catch (err: any) {
    alert('Failed to complete order: ' + (err.message || 'Unknown error'))
  } finally {
    isCharging.value = false
  }
}
</script>

<template>
  <div class="flex h-full w-full">
    <!-- Left Sidebar: Categories -->
    <aside class="w-44 bg-white border-r border-gray-200 flex flex-col shrink-0">
      <div class="px-4 py-4">
        <p class="text-xs font-semibold text-gray-400 uppercase tracking-wider">Categories</p>
      </div>
      <nav class="flex-1 px-2 space-y-1 overflow-y-auto">
        <button
          v-for="cat in categories"
          :key="cat"
          @click="activeCategory = cat"
          :class="[
            'w-full flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium transition-all text-left',
            activeCategory === cat
              ? 'bg-[#1E293B] text-white shadow-md'
              : 'text-gray-600 hover:bg-gray-100'
          ]"
        >
          <UIcon :name="categoryIcons[cat] || 'i-lucide-tag'" class="w-5 h-5 flex-shrink-0" />
          {{ cat }}
        </button>
      </nav>

      <!-- Need Help -->
      <div class="p-3 mt-auto">
        <button class="w-full flex items-center gap-2 px-3 py-2.5 bg-emerald-50 text-emerald-700 rounded-xl text-sm font-medium hover:bg-emerald-100 transition-colors">
          <UIcon name="i-lucide-headphones" class="w-5 h-5" />
          <div class="text-left">
            <p class="font-semibold text-xs">Need Help?</p>
            <p class="text-[10px] text-emerald-600">Contact Manager</p>
          </div>
        </button>
      </div>
    </aside>

    <!-- Center: Product Grid -->
    <div class="flex-1 flex flex-col p-5 overflow-hidden bg-gray-50/50">
      <!-- Title + Badge -->
      <div class="flex items-center justify-between mb-4">
        <div>
          <h2 class="text-xl font-bold text-gray-900">Choose Order</h2>
          <p class="text-sm text-gray-500">Select items to add to the current order</p>
        </div>
        <span class="bg-emerald-50 text-emerald-700 text-xs font-semibold px-3 py-1.5 rounded-full border border-emerald-200">
          Showing {{ filteredProducts.length }} items
        </span>
      </div>

      <!-- Loading state -->
      <div v-if="loading" class="flex-1 flex items-center justify-center">
        <div class="text-center text-gray-400">
          <UIcon name="i-lucide-loader-2" class="w-8 h-8 animate-spin mx-auto mb-2" />
          <p>Loading products...</p>
        </div>
      </div>

      <!-- Empty state -->
      <div v-else-if="filteredProducts.length === 0" class="flex-1 flex items-center justify-center">
        <div class="text-center text-gray-400">
          <UIcon name="i-lucide-package" class="w-12 h-12 mx-auto mb-3 opacity-40" />
          <p class="text-lg font-medium mb-1">No products found</p>
          <p class="text-sm">Add products from the backoffice to start selling.</p>
          <UButton to="/backoffice/products" color="primary" variant="soft" class="mt-4" label="Go to Products" icon="i-lucide-arrow-right" />
        </div>
      </div>

      <!-- Product Grid -->
      <div v-else class="flex-1 overflow-y-auto pr-1 custom-scrollbar">
        <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
          <div
            v-for="product in filteredProducts"
            :key="product.id"
            class="bg-[#1E293B] rounded-2xl overflow-hidden cursor-pointer hover:shadow-lg transition-all duration-200 transform hover:-translate-y-1 group flex flex-col"
            @click="addToOrder(product)"
          >
            <!-- Product Image -->
            <div class="aspect-[4/3] w-full relative overflow-hidden">
              <img v-if="product.image" :src="product.image" :alt="product.name" class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300" />
              <div v-else class="w-full h-full flex items-center justify-center bg-[#2d3a4f]">
                <UIcon name="i-lucide-coffee" class="w-12 h-12 text-gray-500" />
              </div>
              <!-- Price Badge -->
              <span class="absolute top-3 left-3 bg-emerald-500 text-white text-xs font-bold px-2.5 py-1 rounded-lg shadow-md">
                {{ formatCurrency(product.price) }}
              </span>
            </div>
            <!-- Product Info -->
            <div class="p-3">
              <h3 class="font-semibold text-white text-sm leading-tight line-clamp-1">{{ product.name }}</h3>
              <p class="text-gray-400 text-xs mt-1 line-clamp-1">{{ product.description || product.category }}</p>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Right Sidebar: Order Summary -->
    <div class="w-80 lg:w-96 bg-white border-l border-gray-200 flex flex-col shrink-0">
      <!-- Order Header -->
      <div class="px-5 py-4 border-b border-gray-100">
        <div class="flex items-center justify-between">
          <h2 class="font-bold text-lg text-gray-900">Current Order</h2>
          <span class="bg-[#1E293B] text-white text-xs font-bold w-8 h-8 rounded-lg flex items-center justify-center">
            DI
          </span>
        </div>
        <p class="text-xs text-gray-500 mt-1">Order {{ orderNumber }} • Dine-in</p>
      </div>

      <!-- Order Items List -->
      <div class="flex-1 overflow-y-auto px-4 py-3 custom-scrollbar space-y-3">
        <div v-if="orderItems.length === 0 && !orderCompleted" class="flex flex-col items-center justify-center h-full text-center text-gray-400 space-y-4">
          <UIcon name="i-lucide-shopping-cart" class="w-12 h-12 text-gray-200" />
          <p class="text-sm">Order is empty.<br>Select items from the menu.</p>
        </div>

        <!-- Success message -->
        <div v-if="orderCompleted" class="flex flex-col items-center justify-center h-full text-center space-y-4">
          <div class="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center text-green-600">
            <UIcon name="i-lucide-check" class="w-8 h-8" />
          </div>
          <p class="text-green-600 font-semibold text-lg">Order Complete!</p>
        </div>

        <!-- Order Items -->
        <div v-for="item in orderItems" :key="item.id" class="flex items-center gap-3">
          <!-- Product Thumbnail -->
          <div class="w-12 h-12 rounded-xl overflow-hidden bg-gray-100 flex-shrink-0">
            <img v-if="item.image" :src="item.image" :alt="item.name" class="w-full h-full object-cover" />
            <div v-else class="w-full h-full flex items-center justify-center">
              <UIcon name="i-lucide-coffee" class="w-5 h-5 text-gray-400" />
            </div>
          </div>
          <!-- Details -->
          <div class="flex-1 min-w-0">
            <h4 class="font-semibold text-sm text-gray-900 truncate">{{ item.name }}</h4>
            <p class="text-xs text-gray-500">{{ formatCurrency(item.price) }}</p>
          </div>
          <!-- Qty Controls -->
          <div class="flex items-center gap-2 bg-gray-50 rounded-lg border border-gray-200 px-1 py-0.5">
            <button class="w-7 h-7 flex items-center justify-center text-gray-500 hover:bg-gray-200 rounded transition-colors" @click.stop="updateQuantity(item, -1)">
              <UIcon name="i-lucide-minus" class="w-3.5 h-3.5" />
            </button>
            <span class="w-6 text-center text-sm font-semibold text-gray-900">{{ item.quantity }}</span>
            <button class="w-7 h-7 flex items-center justify-center text-gray-500 hover:bg-gray-200 rounded transition-colors" @click.stop="updateQuantity(item, 1)">
              <UIcon name="i-lucide-plus" class="w-3.5 h-3.5" />
            </button>
          </div>
        </div>
      </div>

      <!-- Totals & Actions -->
      <div class="border-t border-gray-200 p-5">
        <!-- Breakdown -->
        <div class="space-y-2 mb-4">
          <div class="flex justify-between text-sm">
            <span class="text-gray-500">Subtotal</span>
            <span class="font-medium text-gray-900">{{ formatCurrency(subtotal) }}</span>
          </div>
          <div class="flex justify-between text-sm">
            <span class="text-gray-500">Discount</span>
            <span class="font-medium text-gray-900">{{ formatCurrency(discount) }}</span>
          </div>
          <div class="flex justify-between text-sm">
            <span class="text-gray-500">Tax (10%)</span>
            <span class="font-medium text-gray-900">{{ formatCurrency(tax) }}</span>
          </div>
          <div class="border-t border-dashed border-gray-200 my-2 pt-2">
            <div class="flex justify-between items-center">
              <span class="font-semibold text-gray-900">Total</span>
              <span class="font-bold text-2xl text-gray-900">{{ formatCurrency(total) }}</span>
            </div>
          </div>
        </div>

        <!-- Action Buttons -->
        <div class="flex gap-3 mb-3">
          <button
            class="flex-1 flex items-center justify-center gap-2 py-3 rounded-xl border-2 border-gray-200 text-gray-600 font-semibold text-sm hover:bg-gray-50 transition-colors"
            :disabled="orderItems.length === 0"
          >
            <UIcon name="i-lucide-pause" class="w-4 h-4" />
            Hold Order
          </button>
          <button
            class="flex-1 flex items-center justify-center gap-2 py-3 rounded-xl border-2 border-gray-200 text-gray-600 font-semibold text-sm hover:bg-gray-50 transition-colors"
          >
            <UIcon name="i-lucide-file-text" class="w-4 h-4" />
            Add Note
          </button>
        </div>

        <button
          @click="chargeOrder"
          class="w-full flex items-center justify-center gap-3 py-4 rounded-xl bg-[#1E293B] text-white font-bold text-lg hover:bg-[#334155] transition-colors disabled:opacity-50"
          :disabled="orderItems.length === 0 || isCharging"
        >
          <UIcon name="i-lucide-wallet" class="w-5 h-5" />
          Checkout
        </button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.custom-scrollbar::-webkit-scrollbar {
  width: 6px;
  height: 6px;
}
.custom-scrollbar::-webkit-scrollbar-track {
  background: transparent;
}
.custom-scrollbar::-webkit-scrollbar-thumb {
  background-color: #cbd5e1;
  border-radius: 20px;
}
</style>
