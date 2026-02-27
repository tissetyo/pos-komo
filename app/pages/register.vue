<script setup lang="ts">
definePageMeta({
  layout: 'default'
})

const form = ref({
  storeName: '',
  ownerName: '',
  email: '',
  password: ''
})

const loading = ref(false)

const handleRegister = () => {
  loading.value = true
  setTimeout(() => {
    localStorage.setItem('isAuthenticated', 'true')
    localStorage.removeItem('hasSeenOnboarding') 
    navigateTo('/backoffice')
    loading.value = false
  }, 800)
}
</script>

<template>
  <div class="max-w-[400px] w-full p-8 bg-white dark:bg-gray-900 rounded-[2rem] shadow-[0_8px_30px_rgb(0,0,0,0.04)] dark:shadow-none flex flex-col gap-6 border border-gray-100 dark:border-gray-800 transition-colors duration-300">
    
    <div class="text-center mt-2">
      <div class="w-12 h-12 bg-[#E8F8F0] dark:bg-[#E8F8F0]/10 text-[#00E676] rounded-2xl flex items-center justify-center mx-auto mb-5">
        <UIcon name="i-lucide-store" class="w-6 h-6" />
      </div>
      <h1 class="text-2xl font-bold text-[#0F172A] dark:text-white mb-2 tracking-tight">Create your Store</h1>
      <p class="text-[#64748B] dark:text-gray-400 text-sm font-medium px-4 leading-relaxed">Join Komo POS and start managing your business today</p>
    </div>
    
    <form @submit.prevent="handleRegister" class="flex flex-col gap-3 mt-2">
      
      <div class="relative">
        <div class="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-[#64748B]">
          <UIcon name="i-lucide-building" class="h-4 w-4" />
        </div>
        <input 
          v-model="form.storeName" 
          type="text" 
          placeholder="e.g. Komo Coffee Shop" 
          required
          class="block w-full pl-10 pr-4 py-3 bg-[#0F172A] border border-[#0F172A] rounded-xl text-white placeholder-[#475569] text-sm focus:bg-[#1E293B] focus:border-[#00E676] focus:ring-1 focus:ring-[#00E676] outline-none transition-all"
        />
      </div>

      <div class="relative">
        <div class="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-[#64748B]">
          <UIcon name="i-lucide-user" class="h-4 w-4" />
        </div>
        <input 
          v-model="form.ownerName" 
          type="text" 
          placeholder="e.g. John Doe" 
          required
          class="block w-full pl-10 pr-4 py-3 bg-[#0F172A] border border-[#0F172A] rounded-xl text-white placeholder-[#475569] text-sm focus:bg-[#1E293B] focus:border-[#00E676] focus:ring-1 focus:ring-[#00E676] outline-none transition-all"
        />
      </div>
      
      <div class="relative">
        <div class="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-[#64748B]">
          <UIcon name="i-lucide-mail" class="h-4 w-4" />
        </div>
        <input 
          v-model="form.email" 
          type="email" 
          placeholder="owner@store.com" 
          required
          class="block w-full pl-10 pr-4 py-3 bg-[#0F172A] border border-[#0F172A] rounded-xl text-white placeholder-[#475569] text-sm focus:bg-[#1E293B] focus:border-[#00E676] focus:ring-1 focus:ring-[#00E676] outline-none transition-all"
        />
      </div>
      
      <div class="relative">
        <div class="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-[#64748B]">
          <UIcon name="i-lucide-lock" class="h-4 w-4" />
        </div>
        <input 
          v-model="form.password" 
          type="password" 
          placeholder="••••••••" 
          required
          class="block w-full pl-10 pr-4 py-3 bg-[#0F172A] border border-[#0F172A] rounded-xl text-white placeholder-[#475569] text-sm focus:bg-[#1E293B] focus:border-[#00E676] focus:ring-1 focus:ring-[#00E676] outline-none transition-all"
        />
      </div>
      
      <button 
        type="submit" 
        :disabled="loading"
        class="mt-4 w-full flex items-center justify-center py-3.5 px-4 rounded-xl shadow-sm text-sm font-bold text-[#0F172A] bg-[#00E676] hover:bg-[#00D66B] focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[#00E676] dark:focus:ring-offset-gray-900 transition-colors disabled:opacity-70 disabled:cursor-not-allowed"
      >
        <UIcon v-if="loading" name="i-lucide-loader-2" class="animate-spin h-5 w-5 mr-2" />
        Create Account
      </button>
    </form>
    
    <div class="text-center text-sm text-[#64748B] dark:text-gray-400 mt-2 font-medium">
      Already have an account? 
      <NuxtLink to="/login" class="text-[#00E676] font-semibold hover:text-[#00D66B] transition-colors ml-1">Sign In here</NuxtLink>
    </div>
    
  </div>
</template>
