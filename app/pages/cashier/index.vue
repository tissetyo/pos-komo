<script setup lang="ts">
definePageMeta({
  layout: 'cashier'
})

// Sample data to mimic the UI
const categories = ['All', 'Signature', 'Coffee', 'Non-Coffee', 'Tea', 'Pastry', 'Snacks']
const activeCategory = ref('All')

const products = [
  { id: 1, name: 'Komo Signature Iced Coffee', price: 28000, category: 'Signature', image: 'https://images.unsplash.com/photo-1578314675249-a6910f80cc4e?q=80&w=300&auto=format&fit=crop' },
  { id: 2, name: 'Iced Caramel Macchiato', price: 32000, category: 'Coffee', image: 'https://images.unsplash.com/photo-1510595261313-79d20c5cffde?q=80&w=300&auto=format&fit=crop' },
  { id: 3, name: 'Hot Cafe Latte', price: 25000, category: 'Coffee', image: 'https://images.unsplash.com/photo-1541167760496-1628856ab772?q=80&w=300&auto=format&fit=crop' },
  { id: 4, name: 'Iced Matcha Latte', price: 30000, category: 'Non-Coffee', image: 'https://images.unsplash.com/photo-1515823662972-da6a2e4d3002?q=80&w=300&auto=format&fit=crop' },
  { id: 5, name: 'Lychee Tea', price: 22000, category: 'Tea', image: 'https://images.unsplash.com/photo-1556679343-c7306c1976bc?q=80&w=300&auto=format&fit=crop' },
  { id: 6, name: 'Butter Croissant', price: 20000, category: 'Pastry', image: 'https://images.unsplash.com/photo-1555507036-ab1f40ce88f7?q=80&w=300&auto=format&fit=crop' },
  { id: 7, name: 'Brownie Bites', price: 18000, category: 'Snacks', image: 'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?q=80&w=300&auto=format&fit=crop' },
  { id: 8, name: 'Americano', price: 22000, category: 'Coffee', image: 'https://images.unsplash.com/photo-1551030173-122aabc4489c?q=80&w=300&auto=format&fit=crop' },
  { id: 9, name: 'Choco Lava Cake', price: 26000, category: 'Pastry', image: 'https://images.unsplash.com/photo-1624353365286-cb18d098fb44?q=80&w=300&auto=format&fit=crop' },
  { id: 10, name: 'Cappuccino', price: 28000, category: 'Coffee', image: 'https://images.unsplash.com/photo-1572442388796-11668a67e53d?q=80&w=300&auto=format&fit=crop' },
]

const searchQuery = ref('')

const filteredProducts = computed(() => {
  return products.filter(p => {
    const matchCategory = activeCategory.value === 'All' || p.category === activeCategory.value
    const matchSearch = p.name.toLowerCase().includes(searchQuery.value.toLowerCase())
    return matchCategory && matchSearch
  })
})

const formatCurrency = (amount: number) => {
  return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 }).format(amount)
}

// Order State
const orderItems = ref([
  { id: 1, name: 'Komo Signature Iced Coffee', price: 28000, quantity: 2, options: ['Less Sugar', 'Oat Milk (+5k)'] },
  { id: 6, name: 'Butter Croissant', price: 20000, quantity: 1, options: [] }
])

const activeOrderTab = ref(0)
const orderTabs = [
  { label: 'Order #042', icon: 'i-lucide-receipt' },
  { label: 'Table 4 (Budi)', icon: 'i-lucide-coffee' },
  { icon: 'i-lucide-plus' }
]

const subtotal = computed(() => orderItems.value.reduce((acc, item) => acc + (item.price * item.quantity), 0))
const tax = computed(() => subtotal.value * 0.11)
const total = computed(() => subtotal.value + tax.value)

const addToOrder = (product: any) => {
  const existing = orderItems.value.find(item => item.id === product.id)
  if (existing) {
    existing.quantity++
  } else {
    orderItems.value.push({ id: product.id, name: product.name, price: product.price, quantity: 1, options: [] })
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

const clearOrder = () => orderItems.value = []

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
          ui="{ wrapper: 'rounded-xl', base: 'h-12' }"
        />
        <div class="flex overflow-x-auto pb-2 -mb-2 hide-scrollbar gap-2 flex-1">
          <UButton
            v-for="cat in categories"
            :key="cat"
            :label="cat"
            :color="activeCategory === cat ? 'primary' : 'white'"
            :variant="'solid'"
            class="rounded-full px-5 py-2 font-medium whitespace-nowrap transition-colors"
            :class="activeCategory === cat ? 'text-white' : 'text-gray-700 hover:bg-gray-50 ring-1 ring-inset ring-gray-200'"
            @click="activeCategory = cat"
          />
        </div>
      </div>

      <!-- Product Grid -->
      <div class="flex-1 overflow-y-auto pr-2 custom-scrollbar">
        <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
          <div 
            v-for="product in filteredProducts" 
            :key="product.id"
            class="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden cursor-pointer hover:shadow-md transition-shadow duration-200 transform hover:-translate-y-1 group flex flex-col h-full"
            @click="addToOrder(product)"
          >
            <div class="aspect-square w-full relative overflow-hidden bg-gray-100">
              <img :src="product.image" :alt="product.name" class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300" />
            </div>
            <div class="p-3 flex flex-col flex-1 justify-between">
              <div>
                <div class="text-xs text-primary font-semibold mb-1 uppercase tracking-wider">{{ product.category }}</div>
                <h3 class="font-semibold text-gray-800 leading-tight text-sm md:text-base line-clamp-2">{{ product.name }}</h3>
              </div>
              <div class="mt-2 font-bold text-gray-900">{{ formatCurrency(product.price) }}</div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Right Sidebar - Order Summary -->
    <div class="w-80 md:w-96 lg:w-[400px] bg-white border-l border-gray-200 flex flex-col shrink-0 shadow-lg z-20">
      <!-- Tabs -->
      <UTabs :items="orderTabs" class="w-full px-4 pt-4">
        <template #default="{ item }">
          <div class="flex items-center gap-2 relative truncate">
            <UIcon :name="item.icon" class="w-4 h-4 flex-shrink-0" />
            <span v-if="item.label" class="truncate">{{ item.label }}</span>
          </div>
        </template>
      </UTabs>

      <!-- Order Header -->
      <div class="px-6 py-4 flex items-center justify-between border-b border-gray-100">
        <div>
          <h2 class="font-bold text-lg text-gray-900">Current Order</h2>
          <p class="text-xs text-gray-500 flex items-center gap-1 mt-1">
            <UIcon name="i-lucide-user" class="w-3 h-3" /> Walk-in Customer
          </p>
        </div>
        <UButton icon="i-lucide-more-vertical" color="gray" variant="ghost" class="rounded-full" />
      </div>

      <!-- Order Items List -->
      <div class="flex-1 overflow-y-auto px-4 py-2 custom-scrollbar space-y-3">
        <div v-if="orderItems.length === 0" class="flex flex-col items-center justify-center h-full text-center text-gray-400 space-y-4">
          <UIcon name="i-lucide-shopping-cart" class="w-12 h-12 text-gray-200" />
          <p>Order is empty.<br>Select items from the menu to get started.</p>
        </div>
        
        <div v-for="item in orderItems" :key="item.id" class="flex gap-3 bg-gray-50/50 p-3 rounded-xl border border-gray-100">
          <!-- Qty Controls -->
          <div class="flex flex-col items-center justify-between bg-white rounded-lg border border-gray-200 overflow-hidden w-10">
            <button class="w-full h-8 flex items-center justify-center text-gray-500 hover:bg-gray-50 active:bg-gray-100" @click.stop="updateQuantity(item, 1)">
              <UIcon name="i-lucide-plus" class="w-4 h-4" />
            </button>
            <div class="font-semibold text-sm">{{ item.quantity }}</div>
            <button class="w-full h-8 flex items-center justify-center text-gray-500 hover:bg-gray-50 active:bg-gray-100" @click.stop="updateQuantity(item, -1)">
              <UIcon name="i-lucide-minus" class="w-4 h-4" />
            </button>
          </div>
          
          <!-- Item Details -->
          <div class="flex-1 min-w-0 flex flex-col justify-center">
            <div class="flex justify-between items-start gap-2">
              <h4 class="font-semibold text-sm text-gray-800 leading-tight truncate">{{ item.name }}</h4>
              <div class="font-medium text-sm text-gray-900 whitespace-nowrap">{{ formatCurrency(item.price * item.quantity) }}</div>
            </div>
            
            <div v-if="item.options.length" class="mt-1 text-xs text-gray-500 truncate">
              {{ item.options.join(', ') }}
            </div>
          </div>
        </div>
      </div>

      <!-- Totals & Payment -->
      <div class="p-6 bg-gray-50/80 border-t border-gray-200">
        <div class="space-y-2 mb-6">
          <div class="flex justify-between text-gray-600 text-sm">
            <span>Subtotal</span>
            <span class="font-medium text-gray-900">{{ formatCurrency(subtotal) }}</span>
          </div>
          <div class="flex justify-between text-gray-600 text-sm">
            <span>Tax (11%)</span>
            <span class="font-medium text-gray-900">{{ formatCurrency(tax) }}</span>
          </div>
          <div class="flex justify-between text-gray-600 text-sm">
            <span>Discount</span>
            <span class="font-medium text-primary cursor-pointer hover:underline border-b border-dashed border-primary">Add discount</span>
          </div>
          <div class="border-t border-gray-200 border-dashed my-2 pt-2 flex justify-between items-center">
            <span class="font-semibold text-gray-900">Total</span>
            <span class="font-bold text-2xl text-primary drop-shadow-sm">{{ formatCurrency(total) }}</span>
          </div>
        </div>

        <div class="flex gap-3">
          <UButton 
            v-if="orderItems.length > 0"
            color="red" 
            variant="soft" 
            icon="i-lucide-trash-2"
            class="rounded-xl h-14 w-14 justify-center"
            @click="clearOrder"
          />
          <UButton 
            label="Save Order" 
            color="gray" 
            variant="solid" 
            class="rounded-xl h-14 flex-1 text-base font-semibold shadow-sm"
          />
          <UButton 
            label="Charge" 
            color="primary" 
            class="rounded-xl h-14 flex-[2] text-lg font-bold shadow-md shadow-primary/20 hover:shadow-primary/40 transition-shadow"
            :disabled="orderItems.length === 0"
          />
        </div>
      </div>
    </div>

    <!-- Onboarding Modal -->
    <OnboardingSetup />
  </div>
</template>

<style scoped>
/* Custom scrollbar to keep it clean */
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
