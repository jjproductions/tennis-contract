<script setup lang="ts">
import { ref } from 'vue';
import { supabase } from '../supabase';
import { Mail, Lock, KeyRound, ShieldCheck, AlertCircle, CheckCircle2, Sparkles, ArrowRight, X, Eye, EyeOff } from 'lucide-vue-next';

const props = withDefaults(defineProps<{
  mode?: 'normal' | 'recovery';
}>(), {
  mode: 'normal',
});

const emit = defineEmits(['authenticated', 'close']);

const activeTab = ref<'magic-link' | 'password'>('password');
const email = ref('');
const password = ref('');
const confirmPassword = ref('');
const showPassword = ref(false);
const otpCode = ref('');
const isOtpSent = ref(false);
const showCodeInput = ref(false);
const isSignUp = ref(false);
const isConfirmationSent = ref(false);
const isResetSent = ref(false);
const isRecoveryMode = ref(props.mode === 'recovery');
const resetNotice = ref<string | null>(null);
const pendingPassword = ref('');

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
    if (error.message.toLowerCase().includes('rate limit')) {
      errorMsg.value = 'Email sending limit reached. If you have not configured Resend Custom SMTP in Supabase yet, please switch to the "Password" tab to log in, or wait a few minutes.';
    } else {
      errorMsg.value = error.message;
    }
  } else {
    isOtpSent.value = true;
    showCodeInput.value = true;
    successMsg.value = `A 6-digit passcode has been sent to ${email.value}! Enter your code below to log in:`;
  }
};

const handleVerifyOtp = async () => {
  errorMsg.value = null;
  successMsg.value = null;

  const code = otpCode.value.trim();
  const userEmail = email.value.trim();

  if (!code) {
    errorMsg.value = 'Please enter the 6-digit code from your email.';
    return;
  }

  loading.value = true;

  // 1. Try with type 'magiclink' (standard for signInWithOtp)
  let { error } = await supabase.auth.verifyOtp({
    email: userEmail,
    token: code,
    type: 'magiclink',
  });

  // 2. Fallback to 'signup' if user is a new signup
  if (error) {
    const resSignup = await supabase.auth.verifyOtp({
      email: userEmail,
      token: code,
      type: 'signup',
    });
    if (!resSignup.error) {
      error = null;
    } else {
      // 3. Fallback to 'email'
      const resEmail = await supabase.auth.verifyOtp({
        email: userEmail,
        token: code,
        type: 'email',
      });
      if (!resEmail.error) {
        error = null;
      }
    }
  }

  loading.value = false;

  if (error) {
    if (error.status === 403 || error.message.toLowerCase().includes('token')) {
      errorMsg.value = 'Invalid or expired 6-digit passcode. Please double-check the code or click "Back / Re-enter email" to request a fresh code.';
    } else {
      errorMsg.value = error.message;
    }
  } else {
    // If setting a 1st time password during OTP verification
    if (pendingPassword.value) {
      const { error: updateErr } = await supabase.auth.updateUser({
        password: pendingPassword.value,
      });
      pendingPassword.value = '';
      if (updateErr) {
        errorMsg.value = `Authenticated via code, but failed to save password: ${updateErr.message}`;
        return;
      }
      successMsg.value = 'Password created and account activated successfully!';
      emit('authenticated', { type: 'password_created', email: userEmail });
    } else {
      successMsg.value = 'Authenticated successfully!';
      emit('authenticated', { type: 'otp_code', email: userEmail });
    }
  }
};

// Reset / Create Password via OTP Flow
const handleResetPassword = async () => {
  errorMsg.value = null;
  successMsg.value = null;

  if (!email.value.trim()) {
    errorMsg.value = 'Please enter your roster email address above first.';
    return;
  }

  loading.value = true;

  // Check whitelist
  const { valid, status, name } = await isEmailWhitelisted(email.value);
  if (!valid) {
    loading.value = false;
    if (status === 'pending') {
      errorMsg.value = `Welcome ${name || 'player'}! Your intake submission is received and currently pending Admin approval.`;
    } else {
      errorMsg.value = 'This email is not registered on the official league roster. Please switch to "Player Intake" to submit your registration.';
    }
    return;
  }

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
    showCodeInput.value = true;
    activeTab.value = 'magic-link';
    successMsg.value = `A 6-digit passcode has been sent to ${email.value.trim()}! Enter your code below to verify and log in.`;
  }
};

// Password Flow
const handlePasswordAuth = async () => {
  errorMsg.value = null;
  successMsg.value = null;

  // Recovery Mode (Saving new password from email recovery link)
  if (isRecoveryMode.value) {
    if (!password.value.trim()) {
      errorMsg.value = 'Please enter your new password.';
      return;
    }
    if (!confirmPassword.value.trim()) {
      errorMsg.value = 'Please confirm your new password.';
      return;
    }
    if (password.value !== confirmPassword.value) {
      errorMsg.value = 'Passwords do not match.';
      return;
    }
    if (password.value.length < 6) {
      errorMsg.value = 'Password must be at least 6 characters long.';
      return;
    }

    loading.value = true;
    const { error } = await supabase.auth.updateUser({
      password: password.value.trim(),
    });
    loading.value = false;

    if (error) {
      errorMsg.value = error.message;
    } else {
      emit('authenticated', {
        type: 'password_created',
        email: email.value.trim(),
      });
    }
    return;
  }

  if (!email.value.trim() || !password.value.trim()) {
    errorMsg.value = 'Please enter both email and password.';
    return;
  }

  // 1st Time Password Creation: Verify with 6-digit OTP code
  if (isSignUp.value) {
    if (!confirmPassword.value.trim()) {
      errorMsg.value = 'Please confirm your password.';
      return;
    }
    if (password.value !== confirmPassword.value) {
      errorMsg.value = 'Passwords do not match. Please re-enter your password.';
      return;
    }
    if (password.value.length < 6) {
      errorMsg.value = 'Password must be at least 6 characters long.';
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

    // 2. Save pending password & send 6-digit OTP code to email
    pendingPassword.value = password.value.trim();

    const { error: otpErr } = await supabase.auth.signInWithOtp({
      email: email.value.trim(),
      options: {
        emailRedirectTo: window.location.origin,
      },
    });

    loading.value = false;

    if (otpErr) {
      if (otpErr.message.toLowerCase().includes('rate limit')) {
        errorMsg.value = 'Email sending limit reached. Please wait a few minutes before requesting another code.';
      } else {
        errorMsg.value = otpErr.message;
      }
    } else {
      isOtpSent.value = true;
      showCodeInput.value = true;
      activeTab.value = 'magic-link';
      successMsg.value = `A 6-digit passcode has been sent to ${email.value.trim()}! Enter your code below to verify and save your new password.`;
    }
    return;
  }

  // Regular Sign In with Password
  loading.value = true;
  const { error } = await supabase.auth.signInWithPassword({
    email: email.value.trim(),
    password: password.value.trim(),
  });
  loading.value = false;

  if (error) {
    if (error.message.includes('Invalid login credentials')) {
      errorMsg.value = 'Invalid password. If this is your first time logging in with a password, click "First time? Create Password" below or use 6-Digit Passcode.';
    } else {
      errorMsg.value = error.message;
    }
  } else {
    emit('authenticated', {
      type: 'signed_in',
      email: email.value.trim(),
    });
  }
};
</script>

<template>
  <div @click.self="emit('close')" class="fixed inset-0 z-50 bg-slate-900/60 backdrop-blur-sm flex items-center justify-center p-4">
    <div class="bg-white rounded-2xl shadow-xl max-w-md w-full border border-slate-200 overflow-hidden relative">
      <!-- Close Button -->
      <button
        @click="emit('close')"
        class="absolute top-4 right-4 p-1.5 rounded-full text-white/80 hover:text-white hover:bg-white/10 transition z-10"
        title="Close modal"
      >
        <X class="w-5 h-5" />
      </button>

      <!-- Header -->
      <div class="bg-gradient-to-r from-blue-600 to-indigo-700 p-6 text-white text-center relative">
        <div class="w-12 h-12 bg-white/10 rounded-xl flex items-center justify-center mx-auto mb-3 backdrop-blur-md">
          <ShieldCheck class="w-7 h-7 text-white" />
        </div>
        <h2 class="text-xl font-bold">
          {{ isRecoveryMode ? 'Set New Password' : 'League Portal Login' }}
        </h2>
        <p class="text-xs text-blue-100 mt-1">Indoor Winter Tennis League Roster Authentication</p>
      </div>

      <!-- Auth Method Tabs (Hidden when confirmation, reset screen, or recovery mode is active) -->
      <div v-if="!isConfirmationSent && !isResetSent && !isRecoveryMode" class="flex border-b border-slate-200 bg-slate-50">
        <button
          type="button"
          @click="activeTab = 'magic-link'; errorMsg = null; successMsg = null; isSignUp = false;"
          :class="activeTab === 'magic-link' ? 'border-blue-600 text-blue-600 bg-white font-semibold' : 'border-transparent text-slate-500 hover:text-slate-700'"
          class="flex-1 py-3 text-xs text-center border-b-2 transition flex items-center justify-center gap-1.5"
        >
          <Sparkles class="w-4 h-4 text-amber-500" />
          6-Digit Passcode
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

        <!-- RECOVERY MODE: Save New Password Screen -->
        <div v-if="isRecoveryMode" class="space-y-3">
          <div class="p-3 bg-blue-50 border border-blue-200 rounded-lg text-xs text-blue-800 flex items-start gap-2">
            <KeyRound class="w-4 h-4 text-blue-600 flex-shrink-0 mt-0.5" />
            <span>You opened a password setup email link. Enter your new password below to activate your account.</span>
          </div>

          <div>
            <label class="block text-xs font-medium text-slate-700 mb-1">New Password</label>
            <div class="relative">
              <Lock class="w-4 h-4 text-slate-400 absolute left-3 top-3" />
              <input
                v-model="password"
                :type="showPassword ? 'text' : 'password'"
                placeholder="••••••••"
                class="w-full pl-9 pr-10 py-2 border border-slate-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 outline-none"
              />
              <button
                type="button"
                @click="showPassword = !showPassword"
                class="absolute right-3 top-2.5 text-slate-400 hover:text-slate-600 transition"
                :title="showPassword ? 'Hide password' : 'Show password'"
              >
                <EyeOff v-if="showPassword" class="w-4 h-4" />
                <Eye v-else class="w-4 h-4" />
              </button>
            </div>
          </div>

          <div>
            <label class="block text-xs font-medium text-slate-700 mb-1">Confirm New Password</label>
            <div class="relative">
              <Lock class="w-4 h-4 text-slate-400 absolute left-3 top-3" />
              <input
                v-model="confirmPassword"
                :type="showPassword ? 'text' : 'password'"
                placeholder="••••••••"
                @keyup.enter="handlePasswordAuth"
                class="w-full pl-9 pr-10 py-2 border border-slate-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 outline-none"
              />
            </div>
          </div>

          <button
            @click="handlePasswordAuth"
            :disabled="loading"
            class="w-full py-2.5 bg-blue-600 hover:bg-blue-700 text-white font-semibold text-sm rounded-lg shadow-sm transition flex items-center justify-center gap-2 disabled:opacity-50"
          >
            <span v-if="loading">Saving new password...</span>
            <span v-else>Save New Password & Sign In</span>
          </button>
        </div>

        <!-- TAB 1: Magic Link / OTP -->
        <div v-else-if="activeTab === 'magic-link' && !isConfirmationSent && !isResetSent" class="space-y-4">
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
                Send 6-Digit Passcode
                <ArrowRight class="w-4 h-4" />
              </span>
            </button>
          </div>

          <!-- 6-Digit Passcode Sent Screen -->
          <div v-else class="space-y-4 text-center py-2">
            <div class="w-12 h-12 bg-emerald-100 text-emerald-600 rounded-full flex items-center justify-center mx-auto">
              <Mail class="w-6 h-6" />
            </div>
            <div>
              <h4 class="text-base font-bold text-slate-800">Check Your Email Inbox</h4>
              <p class="text-xs text-slate-600 mt-1">
                We sent a 6-digit passcode to <span class="font-semibold text-slate-800">{{ email }}</span>.
              </p>
              <div class="text-xs text-slate-600 mt-3 bg-emerald-50/80 p-3 rounded-xl border border-emerald-200 text-left space-y-1">
                <p class="font-semibold text-emerald-900">How to log in:</p>
                <ol class="list-decimal list-inside space-y-1 text-[11px] text-emerald-800">
                  <li>Open the email from <strong>"Play League"</strong>.</li>
                  <li>Copy or note your <strong>6-digit passcode</strong>.</li>
                  <li>Enter your 6-digit code below to log in.</li>
                </ol>
              </div>
            </div>

            <!-- 6-digit code input -->
            <div class="space-y-3 pt-2 text-left border-t border-slate-100">
              <label class="block text-xs font-medium text-slate-700">Enter 6-Digit Email Code</label>
              <input
                v-model="otpCode"
                type="text"
                maxlength="6"
                placeholder="123456"
                @keyup.enter="handleVerifyOtp"
                class="w-full text-center tracking-widest font-mono text-lg py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 outline-none"
              />
              <button
                @click="handleVerifyOtp"
                :disabled="loading"
                class="w-full py-2 bg-emerald-600 hover:bg-emerald-700 text-white font-semibold text-xs rounded-lg transition"
              >
                <span v-if="loading">Verifying passcode...</span>
                <span v-else>Verify Passcode & Log In</span>
              </button>
            </div>

            <div class="flex flex-col gap-2 pt-1">
              <button
                @click="isOtpSent = false; otpCode = '';"
                class="text-xs text-slate-400 hover:text-slate-600"
              >
                ← Back / Re-enter email
              </button>
            </div>
          </div>
        </div>

        <!-- TAB 2: Email & Password -->
        <div v-else-if="activeTab === 'password' && !isConfirmationSent && !isResetSent && !isRecoveryMode" class="space-y-3">
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
                :type="showPassword ? 'text' : 'password'"
                placeholder="••••••••"
                @keyup.enter="handlePasswordAuth"
                class="w-full pl-9 pr-10 py-2 border border-slate-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 outline-none"
              />
              <button
                type="button"
                @click="showPassword = !showPassword"
                class="absolute right-3 top-2.5 text-slate-400 hover:text-slate-600 transition"
                :title="showPassword ? 'Hide password' : 'Show password'"
              >
                <EyeOff v-if="showPassword" class="w-4 h-4" />
                <Eye v-else class="w-4 h-4" />
              </button>
            </div>
          </div>

          <!-- Confirm Password (shown when creating a new password) -->
          <div v-if="isSignUp">
            <label class="block text-xs font-medium text-slate-700 mb-1">Confirm Password</label>
            <div class="relative">
              <Lock class="w-4 h-4 text-slate-400 absolute left-3 top-3" />
              <input
                v-model="confirmPassword"
                :type="showPassword ? 'text' : 'password'"
                placeholder="••••••••"
                @keyup.enter="handlePasswordAuth"
                class="w-full pl-9 pr-10 py-2 border border-slate-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 outline-none"
              />
            </div>
          </div>

          <button
            @click="handlePasswordAuth"
            :disabled="loading"
            class="w-full py-2.5 bg-blue-600 hover:bg-blue-700 text-white font-semibold text-sm rounded-lg shadow-sm transition flex items-center justify-center gap-2 disabled:opacity-50"
          >
            <span v-if="loading">Sending 6-digit code...</span>
            <span v-else>{{ isSignUp ? 'Send Code & Create Password' : 'Sign In with Password' }}</span>
          </button>

          <div class="flex justify-between items-center pt-2 text-xs text-slate-500">
            <button
              type="button"
              @click="isSignUp = !isSignUp; errorMsg = null; successMsg = null;"
              class="text-blue-600 hover:underline font-medium"
            >
              {{ isSignUp ? 'Already have a password? Sign In' : 'First time? Create Password' }}
            </button>

            <button
              v-if="!isSignUp"
              type="button"
              @click="handleResetPassword"
              class="text-slate-500 hover:text-blue-600 hover:underline font-medium"
            >
              Forgot Password?
            </button>
          </div>
        </div>

        <!-- SPECIAL SCREEN 1: Confirmation Email Sent (When Supabase requires email verification for new accounts) -->
        <div v-if="isConfirmationSent" class="space-y-4 text-center py-2">
          <div class="w-12 h-12 bg-amber-100 text-amber-600 rounded-full flex items-center justify-center mx-auto">
            <Mail class="w-6 h-6" />
          </div>
          <div>
            <h4 class="text-base font-bold text-slate-800">Check Your Inbox to Activate Password</h4>
            <p class="text-xs text-slate-600 mt-1">
              We sent a confirmation email to <span class="font-semibold text-slate-800">{{ email }}</span>.
            </p>
            <div class="text-xs text-slate-600 mt-3 bg-amber-50 p-3 rounded-xl border border-amber-200 text-left space-y-1.5">
              <p class="font-bold text-amber-900">What to do next:</p>
              <ol class="list-decimal list-inside space-y-1 text-[11px] text-amber-800">
                <li>Open the confirmation email from <strong>"Play League"</strong>.</li>
                <li>Click the <strong>"Confirm Email / Activate Account"</strong> link inside.</li>
                <li>Return to this portal and sign in using your email & password!</li>
              </ol>
            </div>
          </div>
          <div class="flex flex-col gap-2 pt-2">
            <button
              @click="isConfirmationSent = false; isSignUp = false;"
              class="w-full py-2 bg-blue-600 hover:bg-blue-700 text-white font-semibold text-xs rounded-lg transition"
            >
              Return to Password Sign In
            </button>
            <button
              @click="emit('close')"
              class="text-xs text-slate-400 hover:text-slate-600"
            >
              Close Window
            </button>
          </div>
        </div>

        <!-- SPECIAL SCREEN 2: Password Reset / Activation Link Sent -->
        <div v-if="isResetSent" class="space-y-4 text-center py-2">
          <div class="w-12 h-12 bg-blue-100 text-blue-600 rounded-full flex items-center justify-center mx-auto">
            <KeyRound class="w-6 h-6" />
          </div>
          <div>
            <h4 class="text-base font-bold text-slate-800">Check Your Email to Set Password</h4>
            <p class="text-xs text-slate-600 mt-1">
              {{ resetNotice || `We sent a password setup link to ${email}.` }}
            </p>
            <div class="text-xs text-slate-600 mt-3 bg-blue-50 p-3.5 rounded-xl border border-blue-200 text-left space-y-1.5">
              <p class="font-bold text-blue-900">What to do next:</p>
              <ol class="list-decimal list-inside space-y-1 text-[11px] text-blue-800">
                <li>Open your email inbox at <strong>{{ email }}</strong>.</li>
                <li>Click the <strong>"Reset Password" / "Log In"</strong> link inside the email.</li>
                <li>You will be redirected back to set your new password!</li>
              </ol>
            </div>
          </div>
          <div class="flex flex-col gap-2 pt-2">
            <button
              @click="isResetSent = false; isSignUp = false;"
              class="w-full py-2 bg-blue-600 hover:bg-blue-700 text-white font-semibold text-xs rounded-lg transition"
            >
              Return to Sign In
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

