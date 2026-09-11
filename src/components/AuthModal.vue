<script setup lang="ts">
import { ref } from 'vue';
import { supabase } from '../supabase';
import { Mail, Lock, KeyRound, ShieldCheck, AlertCircle, CheckCircle2, Sparkles, ArrowRight, LogIn } from 'lucide-vue-next';

const emit = defineEmits(['authenticated']);

const activeTab = ref<'magic-link' | 'password'>('magic-link');
const email = ref('');
const password = ref('');
const otpCode = ref('');
const isOtpSent = ref(false);
const isSignUp = ref(false);

const loading = ref(false);
const errorMsg = ref<string | null>(null);
const successMsg = ref<string | null>(null);

// Validate if the email exists in the official league roster and is approved by Admin
const isEmailWhitelisted = async (userEmail: string): Promise<{ valid: boolean; status?: 'not_found' | 'pending' | 'approved'; name?: string }> => {
  const cleanEmail = userEmail.trim().toLowerCase();
  const { data, error } = await supabase
    .from('players')
    .select('full_name, email, approved')
    .ilike('email', cleanEmail)
    .maybeSingle();

  if (error || !data) {
    return { valid: false, status: 'not_found' };
  }

  // Check if player is explicitly marked as pending (approved === false)
  if (data.approved === false) {
    return { valid: false, status: 'pending', name: data.full_name };
  }

  return { valid: true, status: 'approved', name: data.full_name };
};

// Magic Link / OTP Flow
const handleSendOtp = async () => {
  errorMsg.value = null;
  successMsg.value = null;

  if (!email.value.trim()) {
    errorMsg.value = 'Please enter your email address.';
    return;
  }

  loading.value = true;

  // 1. Whitelist & Approval Check
  const { valid, status, name } = await isEmailWhitelisted(email.value);
  if (!valid) {
    loading.value = false;
    if (status === 'pending') {
      errorMsg.value = `Welcome ${name || 'player'}! Your intake submission is received and currently pending Admin approval. You will be able to log in as soon as the Admin approves your request.`;
    } else {
      errorMsg.value = 'This email is not registered on the official league roster. Please switch to "Player Intake" to submit your registration.';
    }
    return;
  }

  // 2. Send Magic Link / OTP
  const { error } = await supabase.auth.signInWithOtp({
    email: email.value.trim(),
    options: {
      emailRedirectTo: window.location.origin,
    },
  });

  loading.value = false;

  if (error) {
    errorMsg.value = error.message;
  } else {
    isOtpSent.value = true;
    successMsg.value = `Login code sent! Check your inbox (${email.value}) for a 6-digit passcode or magic link.`;
  }
};

const handleVerifyOtp = async () => {
  errorMsg.value = null;
  successMsg.value = null;

  if (!otpCode.value.trim()) {
    errorMsg.value = 'Please enter the 6-digit code from your email.';
    return;
  }

  loading.value = true;

  const { error } = await supabase.auth.verifyOtp({
    email: email.value.trim(),
    token: otpCode.value.trim(),
    type: 'email',
  });

  loading.value = false;

  if (error) {
    errorMsg.value = error.message;
  } else {
    successMsg.value = 'Authenticated successfully!';
    emit('authenticated');
  }
};

// Password Flow
const handlePasswordAuth = async () => {
  errorMsg.value = null;
  successMsg.value = null;

  if (!email.value.trim() || !password.value.trim()) {
    errorMsg.value = 'Please enter both email and password.';
    return;
  }

  loading.value = true;

  // 1. Whitelist Check
  const { valid, status, name } = await isEmailWhitelisted(email.value);
  if (!valid) {
    loading.value = false;
    if (status === 'pending') {
      errorMsg.value = `Welcome ${name || 'player'}! Your intake submission is received and currently pending Admin approval. You will be able to log in as soon as the Admin approves your request.`;
    } else {
      errorMsg.value = 'This email is not registered on the official league roster. Please switch to "Player Intake" to submit your registration.';
    }
    return;
  }

  // 2. Authenticate or Sign Up
  if (isSignUp.value) {
    const { error } = await supabase.auth.signUp({
      email: email.value.trim(),
      password: password.value.trim(),
    });
    loading.value = false;

    if (error) {
      errorMsg.value = error.message;
    } else {
      successMsg.value = 'Account created! You are now logged in.';
      emit('authenticated');
    }
  } else {
    const { error } = await supabase.auth.signInWithPassword({
      email: email.value.trim(),
      password: password.value.trim(),
    });
    loading.value = false;

    if (error) {
      if (error.message.includes('Invalid login credentials')) {
        errorMsg.value = 'Invalid password. If this is your first time logging in with a password, click "First time? Set Password" below or use Magic Link.';
      } else {
        errorMsg.value = error.message;
      }
    } else {
      successMsg.value = 'Logged in successfully!';
      emit('authenticated');
    }
  }
};
</script>

<template>
  <div class="fixed inset-0 z-50 bg-slate-900/60 backdrop-blur-sm flex items-center justify-center p-4">
    <div class="bg-white rounded-2xl shadow-xl max-w-md w-full border border-slate-200 overflow-hidden">
      <!-- Header -->
      <div class="bg-gradient-to-r from-blue-600 to-indigo-700 p-6 text-white text-center">
        <div class="w-12 h-12 bg-white/10 rounded-xl flex items-center justify-center mx-auto mb-3 backdrop-blur-md">
          <ShieldCheck class="w-7 h-7 text-white" />
        </div>
        <h2 class="text-xl font-bold">League Portal Login</h2>
        <p class="text-xs text-blue-100 mt-1">Indoor Winter Tennis League Roster Authentication</p>
      </div>

      <!-- Auth Method Tabs -->
      <div class="flex border-b border-slate-200 bg-slate-50">
        <button
          type="button"
          @click="activeTab = 'magic-link'; errorMsg = null; successMsg = null;"
          :class="activeTab === 'magic-link' ? 'border-blue-600 text-blue-600 bg-white font-semibold' : 'border-transparent text-slate-500 hover:text-slate-700'"
          class="flex-1 py-3 text-xs text-center border-b-2 transition flex items-center justify-center gap-1.5"
        >
          <Sparkles class="w-4 h-4 text-amber-500" />
          Magic Link / OTP
        </button>
        <button
          type="button"
          @click="activeTab = 'password'; errorMsg = null; successMsg = null;"
          :class="activeTab === 'password' ? 'border-blue-600 text-blue-600 bg-white font-semibold' : 'border-transparent text-slate-500 hover:text-slate-700'"
          class="flex-1 py-3 text-xs text-center border-b-2 transition flex items-center justify-center gap-1.5"
        >
          <KeyRound class="w-4 h-4" />
          Password
        </button>
      </div>

      <!-- Form Body -->
      <div class="p-6 space-y-4">
        <!-- Error Banner -->
        <div
          v-if="errorMsg"
          class="p-3 bg-red-50 border border-red-200 rounded-lg text-xs text-red-700 flex items-start gap-2"
        >
          <AlertCircle class="w-4 h-4 flex-shrink-0 mt-0.5" />
          <span>{{ errorMsg }}</span>
        </div>

        <!-- Success Banner -->
        <div
          v-if="successMsg"
          class="p-3 bg-emerald-50 border border-emerald-200 rounded-lg text-xs text-emerald-700 flex items-start gap-2"
        >
          <CheckCircle2 class="w-4 h-4 flex-shrink-0 mt-0.5" />
          <span>{{ successMsg }}</span>
        </div>

        <!-- TAB 1: Magic Link / OTP -->
        <div v-if="activeTab === 'magic-link'" class="space-y-4">
          <div v-if="!isOtpSent" class="space-y-3">
            <div>
              <label class="block text-xs font-medium text-slate-700 mb-1">Roster Email Address</label>
              <div class="relative">
                <Mail class="w-4 h-4 text-slate-400 absolute left-3 top-3" />
                <input
                  v-model="email"
                  type="email"
                  placeholder="your.email@example.com"
                  @keyup.enter="handleSendOtp"
                  class="w-full pl-9 pr-3 py-2 border border-slate-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 outline-none"
                />
              </div>
              <p class="text-[11px] text-slate-400 mt-1">Must match the email registered on the official league roster.</p>
            </div>

            <button
              @click="handleSendOtp"
              :disabled="loading"
              class="w-full py-2.5 bg-blue-600 hover:bg-blue-700 text-white font-semibold text-sm rounded-lg shadow-sm transition flex items-center justify-center gap-2 disabled:opacity-50"
            >
              <span v-if="loading">Checking roster & sending code...</span>
              <span v-else class="flex items-center gap-2">
                Send Magic Code / Link
                <ArrowRight class="w-4 h-4" />
              </span>
            </button>
          </div>

          <!-- OTP Code Verification Form -->
          <div v-else class="space-y-3">
            <div>
              <label class="block text-xs font-medium text-slate-700 mb-1">Enter 6-Digit Email Code</label>
              <input
                v-model="otpCode"
                type="text"
                maxlength="6"
                placeholder="123456"
                @keyup.enter="handleVerifyOtp"
                class="w-full text-center tracking-widest font-mono text-lg py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 outline-none"
              />
            </div>

            <button
              @click="handleVerifyOtp"
              :disabled="loading"
              class="w-full py-2.5 bg-emerald-600 hover:bg-emerald-700 text-white font-semibold text-sm rounded-lg shadow-sm transition flex items-center justify-center gap-2 disabled:opacity-50"
            >
              <span v-if="loading">Verifying code...</span>
              <span v-else class="flex items-center gap-2">
                <LogIn class="w-4 h-4" />
                Verify & Sign In
              </span>
            </button>

            <button
              @click="isOtpSent = false; otpCode = '';"
              class="w-full py-1 text-xs text-slate-500 hover:text-slate-700"
            >
              ← Back / Try different email
            </button>
          </div>
        </div>

        <!-- TAB 2: Email & Password -->
        <div v-else-if="activeTab === 'password'" class="space-y-3">
          <div>
            <label class="block text-xs font-medium text-slate-700 mb-1">Roster Email Address</label>
            <div class="relative">
              <Mail class="w-4 h-4 text-slate-400 absolute left-3 top-3" />
              <input
                v-model="email"
                type="email"
                placeholder="your.email@example.com"
                class="w-full pl-9 pr-3 py-2 border border-slate-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 outline-none"
              />
            </div>
          </div>

          <div>
            <label class="block text-xs font-medium text-slate-700 mb-1">Password</label>
            <div class="relative">
              <Lock class="w-4 h-4 text-slate-400 absolute left-3 top-3" />
              <input
                v-model="password"
                type="password"
                placeholder="••••••••"
                @keyup.enter="handlePasswordAuth"
                class="w-full pl-9 pr-3 py-2 border border-slate-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 outline-none"
              />
            </div>
          </div>

          <button
            @click="handlePasswordAuth"
            :disabled="loading"
            class="w-full py-2.5 bg-blue-600 hover:bg-blue-700 text-white font-semibold text-sm rounded-lg shadow-sm transition flex items-center justify-center gap-2 disabled:opacity-50"
          >
            <span v-if="loading">Authenticating...</span>
            <span v-else>{{ isSignUp ? 'Create Password & Sign In' : 'Sign In with Password' }}</span>
          </button>

          <div class="flex justify-between items-center pt-2 text-xs text-slate-500">
            <button
              @click="isSignUp = !isSignUp"
              class="text-blue-600 hover:underline font-medium"
            >
              {{ isSignUp ? 'Already have a password? Sign In' : 'First time? Create Password' }}
            </button>
          </div>
        </div>
      </div>

      <div class="bg-slate-50 p-4 border-t border-slate-200 text-center">
        <p class="text-[11px] text-slate-400">
          Indoor Winter Tennis League • Roster Verified Portal
        </p>
      </div>
    </div>
  </div>
</template>
