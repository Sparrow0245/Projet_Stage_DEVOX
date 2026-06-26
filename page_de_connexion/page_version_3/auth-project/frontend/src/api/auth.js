import axios from 'axios'

// Mode : 'session' ou 'jwt' — à changer selon le backend lancé
// En production, lire depuis une variable d'env Vite : import.meta.env.VITE_AUTH_MODE
const AUTH_MODE = import.meta.env.VITE_AUTH_MODE || 'session'

const api = axios.create({
  baseURL: '/api/auth',
  withCredentials: true, // toujours true : nécessaire pour les cookies de session
})

// Intercepteur JWT : injecte le token Authorization si présent
api.interceptors.request.use(config => {
  if (AUTH_MODE === 'jwt') {
    const token = localStorage.getItem('jwt_token')
    if (token) config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

export const authMode = AUTH_MODE

export const register = (name, email, password) =>
  api.post('/register', { name, email, password })

export const login = async (email, password) => {
  const res = await api.post('/login', { email, password })
  if (AUTH_MODE === 'jwt' && res.data.token) {
    localStorage.setItem('jwt_token', res.data.token)
  }
  return res
}

export const getMe = () => api.get('/me')

export const updateMe = (name, password) =>
  api.put('/me', { name, password })

export const deleteMe = () => api.delete('/me')

export const logout = async () => {
  await api.post('/logout')
  if (AUTH_MODE === 'jwt') {
    localStorage.removeItem('jwt_token')
  }
}

export const isLoggedIn = () => {
  if (AUTH_MODE === 'jwt') return !!localStorage.getItem('jwt_token')
  return true // la session est opaque, on tente /me pour vérifier
}
