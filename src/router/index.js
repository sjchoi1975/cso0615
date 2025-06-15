import { createRouter, createWebHistory } from 'vue-router'
import HomeView from '../views/HomeView.vue'
import AdminProductsList from '../views/admin/AdminProductsList.vue'
// (유저용 컴포넌트도 나중에 추가 가능)

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'home',
      component: HomeView,
    },
    {
      path: '/admin/products/list',
      name: 'admin-products-list',
      component: AdminProductsList,
    },
    // 유저용 라우트는 나중에 추가
    // {
    //   path: '/products/list',
    //   name: 'user-products-list',
    //   component: UserProductsList,
    // },
  ],
})

export default router
