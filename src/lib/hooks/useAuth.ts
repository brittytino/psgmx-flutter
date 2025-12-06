'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import axios from 'axios';

export interface User {
  id: string;
  registerNumber: string;
  email: string;
  role: string;
  fullName?: string;
  isProfileComplete?: boolean;
}

export function useAuth() {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const router = useRouter();

  useEffect(() => {
    checkSession();
  }, []);

  const checkSession = async () => {
    try {
      const response = await axios.get('/api/auth/session');
      if (response.data.success) {
        setUser(response.data.data);
      }
    } catch (error) {
      setUser(null);
    } finally {
      setLoading(false);
    }
  };

  const login = async (registerNumber: string, password: string) => {
    const response = await axios.post('/api/auth/login', {
      registerNumber,
      password,
    });
    
    if (response.data.success) {
      setUser(response.data.data.user);
      return response.data.data.user;
    }
    throw new Error('Login failed');
  };

  const logout = async () => {
    await axios.post('/api/auth/logout');
    setUser(null);
    router.push('/login');
  };

  return {
    user,
    loading,
    login,
    logout,
    checkSession,
  };
}
