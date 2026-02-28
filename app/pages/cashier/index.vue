<script setup lang="ts">
definePageMeta({
  layout: 'cashier'
})

const client = useSupabaseClient()
const user = useSupabaseUser()

// Data from Supabase
const products = ref<any[]>([])
const categories = ref<string[]>(['All'])
const activeCategory = ref('All')
const searchQuery = ref('')
const loading = ref(true)
const outletId = ref<string | null>(null)

// Order State
const orderItems = ref<any[]>([])
const isCharging = ref(false)
const orderCompleted = ref(false)

const formatCurrency = (amount: number) => {
  return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 }).format(amount)
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
      price: p.price,
      category: p.categories?.name || 'Other',
      image: p.image_url || null,
      stock: p.stock
    }))

    // Build categories
    const cats = new Set(products.value.map(p => p.category))
    categories.value = ['All', ...Array.from(cats)]
  } finally {
    loading.value = false
  }
})

const filteredProducts = computed(() => {
  return products.value.filter(p => {
    const matchCategory = activeCategory.value === 'All' || p.category === activeCategory.value
    const matchSearch = p.name.toLowerCase().includes(searchQuery.value.toLowerCase())
    return matchCategory && matchSearch
  })
})

const subtotal = computed(() => orderItems.value.reduce((acc, item) => acc + (item.price * item.quantity), 0))
const tax = computed(() => Math.round(subtotal.value * 0.11))
const total = computed(() => subtotal.value + tax.value)

const addToOrder = (product: any) => {
  const existing = orderItems.value.find(item => item.id === product.id)
  if (existing) {
    existing.quantity++
  } else {
    orderItems.value.push({ id: product.id, name: product.name, price: product.price, quantity: 1 })
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
    // Generate receipt number
    const receiptNumber = 'TRX-' + Date.now().toString().slice(-6)

    // Create order
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

    // Create order items
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
    <!-- Main Menu Area -->
    <div class="flex-1 flex flex-col p-4 md:p-6 overflow-hidden">
      <!-- Search & Filters -->
      <div class="flex flex-col md:flex-row gap-4 mb-6">
        <UInput
          v-model="searchQuery"
          icon="i-lucide-search"
          placeholder="Search products..."
          size="lg"
          class="flex-1 max-w-md shadow-sm"
        />
        <div class="flex overflow-x-auto pb-2 -mb-2 hide-scrollbar gap-2 flex-1">
          <UButton
            v-for="cat in categories"
            :key="cat"
            :label="cat"
            :color="activeCategory === cat ? 'primary' : 'neutral'"
            variant="solid"
            class="rounded-full px-5 py-2 font-medium whitespace-nowrap transition-colors"
            @click="activeCategory = cat"
          />
        </div>
      </div>

      <!-- Loading state -->
      <div v-if="loading" class="flex-1 flex items-center justify-center">
        <div class="text-center text-gray-400 dark:text-gray-500">
          <UIcon name="i-lucide-loader-2" class="w-8 h-8 animate-spin mx-auto mb-2" />
          <p>Loading products...</p>
        </div>
      </div>

      <!-- Empty state -->
      <div v-else-if="filteredProducts.length === 0" class="flex-1 flex items-center justify-center">
        <div class="text-center text-gray-400 dark:text-gray-500">
          <UIcon name="i-lucide-package" class="w-12 h-12 mx-auto mb-3 opacity-40" />
          <p class="text-lg font-medium mb-1">No products found</p>
          <p class="text-sm">Add products from the backoffice to start selling.</p>
          <UButton to="/backoffice/products" color="primary" variant="soft" class="mt-4" label="Go to Products" icon="i-lucide-arrow-right" />
        </div>
      </div>

      <!-- Product Grid -->
      <div v-else class="flex-1 overflow-y-auto pr-2 custom-scrollbar">
        <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
          <div
            v-for="product in filteredProducts"
            :key="product.id"
            class="bg-white dark:bg-gray-900 rounded-2xl shadow-sm border border-gray-100 dark:border-gray-800 overflow-hidden cursor-pointer hover:shadow-md transition-shadow duration-200 transform hover:-translate-y-1 group flex flex-col h-full"
            @click="addToOrder(product)"
          >
            <div class="aspect-square w-full relative overflow-hidden bg-gray-100 dark:bg-gray-800">
              <img v-if="product.image" :src="product.image" :alt="product.name" class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300" />
              <div v-else class="w-full h-full flex items-center justify-center">
                <UIcon name="i-lucide-coffee" class="w-12 h-12 text-gray-300 dark:text-gray-600" />
              </div>
            </div>
            <div class="p-3 flex flex-col flex-1 justify-between">
              <div>
                <div class="text-xs text-primary font-semibold mb-1 uppercase tracking-wider">{{ product.category }}</div>
                <h3 class="font-semibold text-gray-800 dark:text-gray-200 leading-tight text-sm md:text-base line-clamp-2">{{ product.name }}</h3>
              </div>
              <div class="mt-2 font-bold text-gray-900 dark:text-white">{{ formatCurrency(product.price) }}</div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Right Sidebar - Order Summary -->
    <div class="w-80 md:w-96 lg:w-[400px] bg-white dark:bg-gray-900 border-l border-gray-200 dark:border-gray-800 flex flex-col shrink-0 shadow-lg z-20">
      <!-- Order Header -->
      <div class="px-6 py-4 flex items-center justify-between border-b border-gray-100 dark:border-gray-800">
        <div>
          <h2 class="font-bold text-lg text-gray-900 dark:text-white">Current Order</h2>
          <p class="text-xs text-gray-500 dark:text-gray-400 flex items-center gap-1 mt-1">
            <UIcon name="i-lucide-user" class="w-3 h-3" /> Walk-in Customer
          </p>
        </div>
      </div>

      <!-- Order Items List -->
      <div class="flex-1 overflow-y-auto px-4 py-2 custom-scrollbar space-y-3">
        <div v-if="orderItems.length === 0" class="flex flex-col items-center justify-center h-full text-center text-gray-400 dark:text-gray-500 space-y-4">
          <UIcon name="i-lucide-shopping-cart" class="w-12 h-12 text-gray-200 dark:text-gray-700" />
          <p>Order is empty.<br>Select items from the menu to get started.</p>
        </div>

        <!-- Success message -->
        <div v-if="orderCompleted" class="flex flex-col items-center justify-center h-full text-center space-y-4">
          <div class="w-16 h-16 bg-green-100 dark:bg-green-900/30 rounded-full flex items-center justify-center text-green-600">
            <UIcon name="i-lucide-check" class="w-8 h-8" />
          </div>
          <p class="text-green-600 font-semibold text-lg">Order Complete!</p>
        </div>

        <div v-for="item in orderItems" :key="item.id" class="flex gap-3 bg-gray-50/50 dark:bg-gray-800/50 p-3 rounded-xl border border-gray-100 dark:border-gray-700">
          <!-- Qty Controls -->
          <div class="flex flex-col items-center justify-between bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 overflow-hidden w-10">
            <button class="w-full h-8 flex items-center justify-center text-gray-500 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-gray-700 active:bg-gray-100" @click.stop="updateQuantity(item, 1)">
              <UIcon name="i-lucide-plus" class="w-4 h-4" />
            </button>
            <div class="font-semibold text-sm text-gray-900 dark:text-white">{{ item.quantity }}</div>
            <button class="w-full h-8 flex items-center justify-center text-gray-500 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-gray-700 active:bg-gray-100" @click.stop="updateQuantity(item, -1)">
              <UIcon name="i-lucide-minus" class="w-4 h-4" />
            </button>
          </div>

          <!-- Item Details -->
          <div class="flex-1 min-w-0 flex flex-col justify-center">
            <div class="flex justify-between items-start gap-2">
              <h4 class="font-semibold text-sm text-gray-800 dark:text-gray-200 leading-tight truncate">{{ item.name }}</h4>
              <div class="font-medium text-sm text-gray-900 dark:text-white whitespace-nowrap">{{ formatCurrency(item.price * item.quantity) }}</div>
            </div>
          </div>
        </div>
      </div>

      <!-- Totals & Payment -->
      <div class="p-6 bg-gray-50/80 dark:bg-gray-800/50 border-t border-gray-200 dark:border-gray-700">
        <div class="space-y-2 mb-6">
          <div class="flex justify-between text-gray-600 dark:text-gray-400 text-sm">
            <span>Subtotal</span>
            <span class="font-medium text-gray-900 dark:text-white">{{ formatCurrency(subtotal) }}</span>
          </div>
          <div class="flex justify-between text-gray-600 dark:text-gray-400 text-sm">
            <span>Tax (11%)</span>
            <span class="font-medium text-gray-900 dark:text-white">{{ formatCurrency(tax) }}</span>
          </div>
          <div class="border-t border-gray-200 dark:border-gray-700 border-dashed my-2 pt-2 flex justify-between items-center">
            <span class="font-semibold text-gray-900 dark:text-white">Total</span>
            <span class="font-bold text-2xl text-primary drop-shadow-sm">{{ formatCurrency(total) }}</span>
          </div>
        </div>

        <div class="flex gap-3">
          <UButton
            v-if="orderItems.length > 0"
            color="error"
            variant="soft"
            icon="i-lucide-trash-2"
            class="rounded-xl h-14 w-14 justify-center"
            @click="clearOrder"
          />
          <UButton
            label="Charge"
            color="primary"
            class="rounded-xl h-14 flex-1 text-lg font-bold shadow-md shadow-primary/20 hover:shadow-primary/40 transition-shadow"
            :disabled="orderItems.length === 0"
            :loading="isCharging"
            @click="chargeOrder"
          />
        </div>
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
.hide-scrollbar::-webkit-scrollbar {
  display: none;
}
.hide-scrollbar {
  -ms-overflow-style: none;
  scrollbar-width: none;
}
</style>
