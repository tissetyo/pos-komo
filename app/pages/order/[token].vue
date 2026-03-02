<script setup lang="ts">
definePageMeta({ layout: 'order', auth: false })

const route = useRoute()
const token = route.params.token as string
const client = useSupabaseClient()

// State
const tableData = ref<any>(null)
const outlet = ref<any>(null)
const products = ref<any[]>([])
const categories = ref<string[]>([])
const activeCategory = ref('All')
const cart = ref<any[]>([])
const showCart = ref(false)
const showCheckout = ref(false)
const showSuccess = ref(false)
const completedOrderNumber = ref('')
const loading = ref(true)
const submitting = ref(false)
const errorMsg = ref('')
const searchQuery = ref('')

// Checkout form
const customerName = ref('')
const customerPhone = ref('')

// Load table + outlet + products
onMounted(async () => {
  // 1. Resolve token → table → outlet
  const { data: tbl, error: tblError } = await (client as any)
    .from('tables')
    .select('*, outlets(*)')
    .eq('qr_token', token)
    .eq('is_active', true)
    .single()

  if (tblError || !tbl) {
    errorMsg.value = 'This table is not available.'
    loading.value = false
    return
  }

  tableData.value = tbl
  outlet.value = tbl.outlets

  // 2. Load products for this outlet
  const { data: prods } = await (client as any)
    .from('products')
    .select('*, categories(name), product_variations(*)')
    .eq('outlet_id', tbl.outlet_id)
    .eq('is_active', true)
    .order('created_at', { ascending: false })

  const loadedProducts = (prods || []).map((p: any) => ({
    ...p,
    category: p.categories?.name || 'Uncategorized'
  }))

  products.value = loadedProducts

  const catNames = [...new Set(loadedProducts.map((p: any) => p.category))] as string[]
  categories.value = ['All', ...catNames]

  loading.value = false
})

// Best picks - random popular items (top 8)
const bestPicks = computed(() => {
  return products.value.slice(0, 8)
})

// Filtered products
const filteredProducts = computed(() => {
  let list = products.value
  if (activeCategory.value !== 'All') {
    list = list.filter(p => p.category === activeCategory.value)
  }
  if (searchQuery.value) {
    const q = searchQuery.value.toLowerCase()
    list = list.filter(p => p.name.toLowerCase().includes(q))
  }
  return list
})

// Currency
const currency = computed(() => outlet.value?.currency || 'MYR')
const formatPrice = (price: number) => {
  const symbols: Record<string, string> = {
    MYR: 'RM', IDR: 'Rp', SGD: 'S$', USD: '$'
  }
  return `${symbols[currency.value] || currency.value}${price.toLocaleString()}`
}

// Cart
const addToCart = (product: any) => {
  const existing = cart.value.find(c => c.id === product.id)
  if (existing) {
    existing.quantity++
  } else {
    cart.value.push({ ...product, quantity: 1 })
  }
}

const updateCartQty = (item: any, delta: number) => {
  item.quantity += delta
  if (item.quantity <= 0) {
    cart.value = cart.value.filter(c => c.id !== item.id)
  }
}

const cartCount = computed(() => cart.value.reduce((s, c) => s + c.quantity, 0))
const cartTotal = computed(() => cart.value.reduce((s, c) => s + c.price * c.quantity, 0))

// Checkout
const openCheckout = () => {
  showCart.value = false
  showCheckout.value = true
}

const canSubmit = computed(() => customerPhone.value.length >= 8 && cart.value.length > 0)

const placeOrder = async () => {
  if (!canSubmit.value || !tableData.value) return
  submitting.value = true

  try {
    // Generate receipt number
    const receiptNumber = `QR-${Date.now().toString(36).toUpperCase()}`

    // Compute totals
    const subtotal = cartTotal.value
    const sst = outlet.value?.sst || 0
    const serviceCharge = outlet.value?.service_charge || 0
    const taxAmount = Math.round(subtotal * sst / 100)
    const serviceAmount = Math.round(subtotal * serviceCharge / 100)
    const total = subtotal + taxAmount + serviceAmount

    // Auto-save or map customer status
    let customerId = null
    const { data: existingCustomer } = await (client as any)
      .from('customers')
      .select('id')
      .eq('phone', customerPhone.value)
      .eq('outlet_id', tableData.value.outlet_id)
      .maybeSingle()

    if (existingCustomer) {
      customerId = existingCustomer.id
      // Update name if a name was provided and it's different/new
      if (customerName.value) {
        await (client as any).from('customers').update({ name: customerName.value }).eq('id', customerId)
      }
    } else {
      // Create new customer
      const { data: newCustomer } = await (client as any).from('customers').insert({
        name: customerName.value || `QR Customer (${customerPhone.value})`,
        phone: customerPhone.value,
        outlet_id: tableData.value.outlet_id
      }).select('id').single()

      if (newCustomer) {
        customerId = newCustomer.id
      }
    }

    // Create order — cast as any to bypass typed client RLS issues
    const { data: order, error: orderErr } = await (client as any).from('orders').insert({
      receipt_number: receiptNumber,
      outlet_id: tableData.value.outlet_id,
      table_id: tableData.value.id,
      customer_id: customerId,
      source: 'qr',
      customer_name: customerName.value || null,
      customer_phone: customerPhone.value,
      subtotal,
      tax: taxAmount,
      total,
      payment_method: 'cash',
      payment_status: 'pending',
      order_status: 'new',
      order_type: 'dine-in'
    }).select().single()

    if (orderErr) throw orderErr

    // Create order items
    const items = cart.value.map(c => ({
      order_id: order.id,
      product_id: c.id,
      quantity: c.quantity,
      unit_price: c.price,
      total_price: c.price * c.quantity
    }))

    await (client as any).from('order_items').insert(items)

    completedOrderNumber.value = receiptNumber
    showCheckout.value = false
    showSuccess.value = true
    cart.value = []
  } catch (err: any) {
    alert(err.message || 'Failed to place order')
  } finally {
    submitting.value = false
  }
}

const newOrder = () => {
  showSuccess.value = false
  customerName.value = ''
  customerPhone.value = ''
  activeCategory.value = 'All'
}

// UI helpers
const cardColors = [
  'linear-gradient(135deg, #FFF3E0 0%, #FFE0B2 100%)',
  'linear-gradient(135deg, #E3F2FD 0%, #BBDEFB 100%)',
  'linear-gradient(135deg, #E8F5E9 0%, #C8E6C9 100%)',
  'linear-gradient(135deg, #F3E5F5 0%, #E1BEE7 100%)',
  'linear-gradient(135deg, #FCE4EC 0%, #F8BBD0 100%)',
  'linear-gradient(135deg, #FFFDE7 0%, #FFF9C4 100%)',
  'linear-gradient(135deg, #E0F2F1 0%, #B2DFDB 100%)',
  'linear-gradient(135deg, #FBE9E7 0%, #FFCCBC 100%)',
]

const foodEmoji = (category: string) => {
  const cat = (category || '').toLowerCase()
  if (cat.includes('drink') || cat.includes('air') || cat.includes('minum') || cat.includes('beverage')) return '🥤'
  if (cat.includes('nasi') || cat.includes('rice')) return '🍚'
  if (cat.includes('mee') || cat.includes('noodle') || cat.includes('pasta')) return '🍜'
  if (cat.includes('ayam') || cat.includes('chicken')) return '🍗'
  if (cat.includes('ikan') || cat.includes('fish') || cat.includes('seafood')) return '🐟'
  if (cat.includes('dessert') || cat.includes('sweet') || cat.includes('cake')) return '🍰'
  if (cat.includes('snack') || cat.includes('goreng')) return '🍟'
  if (cat.includes('soup') || cat.includes('sup')) return '🍲'
  if (cat.includes('coffee') || cat.includes('kopi') || cat.includes('tea') || cat.includes('teh')) return '☕'
  return '🍽️'
}

const categoryEmoji = (cat: string) => {
  if (cat === 'All') return '🔥'
  return foodEmoji(cat)
}

const categoryColors = [
  'linear-gradient(135deg, #FF6B6B 0%, #EE5A24 100%)',
  'linear-gradient(135deg, #FF9FF3 0%, #F368E0 100%)',
  'linear-gradient(135deg, #48DBFB 0%, #0ABDE3 100%)',
  'linear-gradient(135deg, #FECA57 0%, #FF9F43 100%)',
  'linear-gradient(135deg, #1DD1A1 0%, #10AC84 100%)',
  'linear-gradient(135deg, #54A0FF 0%, #2E86DE 100%)',
  'linear-gradient(135deg, #A29BFE 0%, #6C5CE7 100%)',
  'linear-gradient(135deg, #FD79A8 0%, #E84393 100%)',
]
</script>

<template>
  <!-- Loading -->
  <div v-if="loading" class="flex items-center justify-center min-h-screen bg-white">
    <div class="text-center">
      <div class="w-12 h-12 border-4 border-orange-400 border-t-transparent rounded-full animate-spin mx-auto mb-4" />
      <p class="text-gray-500 text-sm font-medium">Loading menu...</p>
    </div>
  </div>

  <!-- Error -->
  <div v-else-if="errorMsg" class="flex items-center justify-center min-h-screen px-6 bg-white">
    <div class="text-center">
      <div class="w-16 h-16 bg-red-100 rounded-2xl flex items-center justify-center mx-auto mb-4">
        <UIcon name="i-lucide-alert-circle" class="w-8 h-8 text-red-500" />
      </div>
      <h2 class="text-xl font-bold text-gray-900 mb-2">Oops!</h2>
      <p class="text-gray-500">{{ errorMsg }}</p>
    </div>
  </div>

  <!-- Success -->
  <div v-else-if="showSuccess" class="flex items-center justify-center min-h-screen px-6 bg-gradient-to-br from-green-50 via-white to-emerald-50">
    <div class="text-center max-w-sm">
      <div class="w-24 h-24 bg-gradient-to-br from-green-400 to-emerald-500 rounded-3xl flex items-center justify-center mx-auto mb-6 shadow-lg shadow-green-200">
        <UIcon name="i-lucide-check" class="w-12 h-12 text-white" />
      </div>
      <h2 class="text-2xl font-bold text-gray-900 mb-2">Order Placed! 🎉</h2>
      <p class="text-gray-500 mb-2">Your order has been sent to the kitchen.</p>
      <p class="text-sm font-mono bg-gray-100 inline-block px-4 py-1.5 rounded-lg text-gray-500 mb-6">{{ completedOrderNumber }}</p>
      <div class="bg-amber-50 border border-amber-200 rounded-2xl p-4 mb-8">
        <p class="text-amber-800 font-semibold">📍 Table {{ tableData.table_number }}</p>
        <p class="text-amber-600 text-sm mt-1">Please wait while we prepare your food.</p>
      </div>
      <button class="w-full bg-gradient-to-r from-orange-500 to-amber-500 text-white rounded-2xl px-6 py-4 font-bold text-base shadow-lg shadow-orange-200 active:scale-[0.98] transition-transform" @click="newOrder">
        🍽️ Order More
      </button>
    </div>
  </div>

  <!-- Checkout -->
  <div v-else-if="showCheckout" class="min-h-screen bg-gray-50">
    <div class="sticky top-0 bg-white/95 backdrop-blur-sm border-b border-gray-100 px-4 py-3 flex items-center gap-3 z-10">
      <button @click="showCheckout = false" class="w-10 h-10 flex items-center justify-center rounded-xl bg-gray-100 hover:bg-gray-200 transition-colors">
        <UIcon name="i-lucide-arrow-left" class="w-5 h-5 text-gray-700" />
      </button>
      <h2 class="text-lg font-bold text-gray-900">Checkout</h2>
    </div>

    <div class="px-4 py-6 space-y-6 max-w-lg mx-auto">
      <div class="bg-white rounded-2xl p-5 shadow-sm border border-gray-100">
        <h3 class="text-sm font-bold text-gray-400 uppercase tracking-wider mb-4">Your Order</h3>
        <div class="space-y-3">
          <div v-for="item in cart" :key="item.id" class="flex justify-between items-center">
            <div class="flex items-center gap-3">
              <span class="w-8 h-8 bg-orange-100 rounded-lg flex items-center justify-center text-sm">🍴</span>
              <div>
                <p class="font-medium text-gray-900 text-sm">{{ item.name }}</p>
                <p class="text-xs text-gray-400">× {{ item.quantity }}</p>
              </div>
            </div>
            <span class="font-semibold text-gray-900 text-sm">{{ formatPrice(item.price * item.quantity) }}</span>
          </div>
        </div>
        <div class="border-t border-dashed border-gray-200 mt-4 pt-4 flex justify-between items-center">
          <span class="font-bold text-gray-900">Total</span>
          <span class="text-xl font-bold bg-gradient-to-r from-orange-600 to-amber-600 bg-clip-text text-transparent">{{ formatPrice(cartTotal) }}</span>
        </div>
      </div>

      <div class="bg-white rounded-2xl p-5 shadow-sm border border-gray-100">
        <h3 class="text-sm font-bold text-gray-400 uppercase tracking-wider mb-4">Your Information</h3>
        <div class="space-y-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1.5">Phone Number <span class="text-red-500">*</span></label>
            <input v-model="customerPhone" type="tel" inputmode="numeric" placeholder="e.g. 0123456789"
              class="w-full h-12 px-4 rounded-xl border border-gray-200 bg-gray-50 text-gray-900 text-base focus:ring-2 focus:ring-orange-400 focus:border-orange-400 focus:bg-white outline-none transition-all" />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1.5">Name <span class="text-gray-400 font-normal">(optional)</span></label>
            <input v-model="customerName" type="text" placeholder="e.g. John"
              class="w-full h-12 px-4 rounded-xl border border-gray-200 bg-gray-50 text-gray-900 text-base focus:ring-2 focus:ring-orange-400 focus:border-orange-400 focus:bg-white outline-none transition-all" />
          </div>
        </div>
      </div>

      <button :disabled="!canSubmit"
        class="w-full bg-gradient-to-r from-green-500 to-emerald-500 disabled:from-gray-300 disabled:to-gray-300 text-white rounded-2xl px-6 py-4 font-bold text-base shadow-lg shadow-green-200 disabled:shadow-none active:scale-[0.98] transition-all"
        @click="placeOrder">
        <span v-if="submitting">Placing Order...</span>
        <span v-else>✅ Place Order — {{ formatPrice(cartTotal) }}</span>
      </button>
    </div>
  </div>

  <!-- Menu Page -->
  <div v-else class="min-h-screen pb-28 bg-white">
    <!-- Sticky Header -->
    <div class="sticky top-0 z-20 bg-white">
      <div class="px-4 pt-4 pb-3">
        <div class="flex items-center justify-between mb-3">
          <div>
            <h1 class="text-xl font-bold text-gray-900">{{ outlet?.name || 'Menu' }}</h1>
            <p class="text-xs text-gray-400">Table {{ tableData.table_number }} · Dine-in</p>
          </div>
          <div class="w-10 h-10 bg-orange-100 rounded-xl flex items-center justify-center">
            <UIcon name="i-lucide-utensils" class="w-5 h-5 text-orange-600" />
          </div>
        </div>
        <!-- Search -->
        <div class="relative">
          <UIcon name="i-lucide-search" class="w-4 h-4 text-gray-400 absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none" />
          <input v-model="searchQuery" placeholder="Search food..."
            class="w-full h-10 pl-10 pr-4 rounded-xl bg-gray-100 text-sm text-gray-900 placeholder:text-gray-400 outline-none focus:ring-2 focus:ring-orange-300 transition-all" />
        </div>
      </div>
    </div>

    <!-- Best Picks Section -->
    <div v-if="bestPicks.length > 0 && !searchQuery" class="px-4 pt-2 pb-4">
      <h2 class="text-lg font-bold text-gray-900 mb-3">🔥 Best Picks</h2>
      <div class="flex gap-3 overflow-x-auto no-scrollbar pb-1">
        <button
          v-for="(product, index) in bestPicks"
          :key="'pick-' + product.id"
          class="flex-shrink-0 w-32 rounded-2xl overflow-hidden bg-white border border-gray-100 shadow-sm active:scale-[0.95] transition-transform"
          @click="addToCart(product)"
        >
          <div class="w-full h-24 flex items-center justify-center overflow-hidden"
            :style="{ background: product.image_url ? '' : cardColors[index % cardColors.length] }">
            <img v-if="product.image_url" :src="product.image_url" class="w-full h-full object-cover" />
            <span v-else class="text-3xl">{{ foodEmoji(product.category) }}</span>
          </div>
          <div class="p-2">
            <p class="text-xs font-semibold text-gray-900 line-clamp-1">{{ product.name }}</p>
            <p class="text-xs font-bold text-orange-600 mt-0.5">{{ formatPrice(product.price) }}</p>
          </div>
        </button>
      </div>
    </div>

    <!-- Categories Section -->
    <div v-if="!searchQuery" class="px-4 pb-4">
      <h2 class="text-lg font-bold text-gray-900 mb-3">📋 Categories</h2>
      <div class="flex gap-2 overflow-x-auto no-scrollbar pb-1">
        <button
          v-for="(cat, ci) in categories"
          :key="cat"
          :class="['flex items-center gap-2 px-4 py-2.5 rounded-2xl text-sm font-semibold whitespace-nowrap transition-all',
            activeCategory === cat
              ? 'text-white shadow-md'
              : 'bg-gray-100 text-gray-600 hover:bg-gray-200']"
          :style="activeCategory === cat ? { background: categoryColors[ci % categoryColors.length] } : {}"
          @click="activeCategory = cat"
        >
          <span class="text-base">{{ categoryEmoji(cat) }}</span>
          {{ cat }}
        </button>
      </div>
    </div>

    <!-- All Items Section -->
    <div class="px-4">
      <h2 v-if="!searchQuery" class="text-lg font-bold text-gray-900 mb-3">
        {{ activeCategory === 'All' ? '🍽️ All Menu' : activeCategory }}
      </h2>
      <h2 v-else class="text-lg font-bold text-gray-900 mb-3">🔍 Search Results</h2>

      <div v-if="filteredProducts.length === 0" class="text-center py-12">
        <div class="w-16 h-16 bg-gray-100 rounded-2xl flex items-center justify-center mx-auto mb-4">
          <UIcon name="i-lucide-search-x" class="w-8 h-8 text-gray-300" />
        </div>
        <p class="text-gray-500 font-medium">No items found.</p>
      </div>

      <div class="grid grid-cols-2 gap-3">
        <button
          v-for="(product, index) in filteredProducts"
          :key="product.id"
          class="bg-white rounded-2xl overflow-hidden text-left shadow-sm border border-gray-100 hover:shadow-md active:scale-[0.97] transition-all"
          @click="addToCart(product)"
        >
          <div class="w-full aspect-[4/3] flex items-center justify-center overflow-hidden"
            :style="!product.image_url ? { background: cardColors[index % cardColors.length] } : {}">
            <img v-if="product.image_url" :src="product.image_url" class="w-full h-full object-cover" />
            <span v-else class="text-4xl">{{ foodEmoji(product.category) }}</span>
          </div>
          <div class="p-3">
            <h3 class="font-semibold text-gray-900 text-sm leading-tight line-clamp-2">{{ product.name }}</h3>
            <div class="flex items-center justify-between mt-2">
              <span class="font-bold text-orange-600 text-sm">{{ formatPrice(product.price) }}</span>
              <span class="w-7 h-7 bg-orange-500 rounded-lg flex items-center justify-center text-white">
                <UIcon name="i-lucide-plus" class="w-4 h-4" />
              </span>
            </div>
          </div>
        </button>
      </div>
    </div>

    <!-- Floating Cart Button -->
    <div v-if="cartCount > 0" class="fixed bottom-0 left-0 right-0 p-4 z-30">
      <button
        class="w-full bg-gradient-to-r from-green-500 to-emerald-500 text-white rounded-2xl px-6 py-4 flex items-center justify-between shadow-xl shadow-green-900/20 active:scale-[0.98] transition-transform"
        @click="showCart = true"
      >
        <div class="flex items-center gap-3">
          <div class="w-8 h-8 bg-white/20 rounded-lg flex items-center justify-center text-sm font-bold">{{ cartCount }}</div>
          <span class="font-semibold">View Cart</span>
        </div>
        <span class="font-bold text-lg">{{ formatPrice(cartTotal) }}</span>
      </button>
    </div>

    <!-- Cart Bottom Sheet -->
    <Teleport to="body">
      <Transition name="slide-up">
        <div v-if="showCart" class="fixed inset-0 z-50">
          <div class="absolute inset-0 bg-black/40 backdrop-blur-sm" @click="showCart = false" />
          <div class="absolute bottom-0 left-0 right-0 bg-white rounded-t-3xl max-h-[80vh] flex flex-col shadow-2xl">
            <div class="flex justify-center py-3">
              <div class="w-10 h-1 bg-gray-300 rounded-full" />
            </div>
            <div class="px-5 pb-2 flex items-center justify-between">
              <h3 class="text-lg font-bold text-gray-900">🛒 Your Cart</h3>
              <button class="text-sm text-red-500 font-semibold px-3 py-1 rounded-lg hover:bg-red-50 transition-colors" @click="cart = []; showCart = false">Clear All</button>
            </div>
            <div class="flex-1 overflow-y-auto px-5 py-3 space-y-3">
              <div v-for="item in cart" :key="item.id" class="flex items-center gap-3 bg-gray-50 rounded-xl p-3">
                <div class="w-10 h-10 bg-orange-100 rounded-lg flex items-center justify-center text-lg shrink-0">
                  {{ foodEmoji(item.category) }}
                </div>
                <div class="flex-1 min-w-0">
                  <p class="font-medium text-gray-900 text-sm truncate">{{ item.name }}</p>
                  <p class="text-xs text-gray-400">{{ formatPrice(item.price) }} each</p>
                </div>
                <div class="flex items-center gap-1.5">
                  <button class="w-8 h-8 rounded-lg bg-white border border-gray-200 flex items-center justify-center text-gray-600 font-bold text-sm shadow-sm" @click="updateCartQty(item, -1)">−</button>
                  <span class="w-7 text-center font-bold text-sm text-gray-900">{{ item.quantity }}</span>
                  <button class="w-8 h-8 rounded-lg bg-orange-500 text-white flex items-center justify-center font-bold text-sm shadow-sm" @click="updateCartQty(item, 1)">+</button>
                </div>
              </div>
            </div>
            <div class="border-t border-gray-100 px-5 py-4">
              <div class="flex justify-between mb-4">
                <span class="font-bold text-gray-900">Total</span>
                <span class="text-xl font-bold bg-gradient-to-r from-orange-600 to-amber-600 bg-clip-text text-transparent">{{ formatPrice(cartTotal) }}</span>
              </div>
              <button class="w-full bg-gradient-to-r from-green-500 to-emerald-500 text-white rounded-2xl px-6 py-4 font-bold text-base shadow-lg shadow-green-200 active:scale-[0.98] transition-transform" @click="openCheckout">
                Checkout — {{ formatPrice(cartTotal) }}
              </button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>
  </div>
</template>

<style scoped>
.no-scrollbar::-webkit-scrollbar { display: none; }
.no-scrollbar { -ms-overflow-style: none; scrollbar-width: none; }
.line-clamp-1 { display: -webkit-box; -webkit-line-clamp: 1; -webkit-box-orient: vertical; overflow: hidden; }
.line-clamp-2 { display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }

.slide-up-enter-active, .slide-up-leave-active { transition: all 0.3s ease; }
.slide-up-enter-from, .slide-up-leave-to { opacity: 0; }
.slide-up-enter-from .absolute.bottom-0,
.slide-up-leave-to .absolute.bottom-0 { transform: translateY(100%); }
</style>
