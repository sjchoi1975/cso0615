import { createRouter, createWebHistory } from 'vue-router'
import HomeView from '../views/HomeView.vue'
import LoginView from '../views/LoginView.vue'
import SignupView from '../views/SignupView.vue'

import AdminNoticeList from '../views/admin/AdminNoticeList.vue'
import AdminNoticeCreate from '../views/admin/AdminNoticeCreate.vue'
import AdminNoticeEdit from '../views/admin/AdminNoticeEdit.vue'
import AdminNoticeDetail from '../views/admin/AdminNoticeDetail.vue' /* 공지사항 상세 미사용 */
import AdminMembersList from '../views/admin/AdminMembersList.vue'
import AdminProductsList from '../views/admin/AdminProductsList.vue'
import AdminProductsCreate from '../views/admin/AdminProductsCreate.vue'
import AdminFilterList from '../views/admin/AdminFilterList.vue'
import AdminPharmaceuticalCompanies from '../views/admin/AdminPharmaceuticalCompanies.vue'
import AdminEdiList from '../views/admin/AdminEdiList.vue'
import AdminSettlementMonth from '../views/admin/AdminSettlementMonth.vue'
import AdminSettlementMonthDetail from '../views/admin/AdminSettlementMonthDetail.vue'

import UserNoticesList from '../views/user/UserNoticesList.vue'
import UserNoticesDatail from '../views/user/UserNoticesDatail.vue'
import UserProductsList from '../views/user/UserProductsList.vue'
import UserFilterCreate from '../views/user/UserFilterCreate.vue'
import UserFilterList from '../views/user/UserFilterList.vue'
import UserEdisubmit from '../views/user/UserEdiSubmit.vue'
import UserEdiList from '../views/user/UserEdiList.vue'
import UserSettlementMonth from '../views/user/UserSettlementMonth.vue'
import UserSettlementMonthDatail from '../views/user/UserSettlementMonthDatail.vue'

import { supabase } from '@/supabase';

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
    {
      path: '/admin/members/list',
      name: 'admin-members-list',
      component: AdminMembersList,
    },
    {
      path: '/admin/notice/list',
      name: 'admin-notice-list',
      component: AdminNoticeList,
    },
    {
      path: '/admin/filter/list',
      name: 'admin-filter-list',
      component: AdminFilterList,
    },
    {
      path: '/admin/pharmaceutical-companies',
      name: 'admin-pharmaceutical-companies',
      component: AdminPharmaceuticalCompanies,
    },
    {
      path: '/admin/edi/list',
      name: 'admin-edi-list',
      component: () => import('../views/admin/AdminEdiList.vue'),
      meta: { requiresAuth: true, role: 'admin' },
    },
    {
      path: '/admin/edi/months',
      name: 'admin-edi-months',
      component: () => import('@/views/admin/AdminEdiMonths.vue'),
    },
    {
      path: '/admin/settlement/month',
      name: 'admin-settlement-month',
      component: AdminSettlementMonth,
    },
    {
      path: '/admin/settlement/month/:month',
      name: 'admin-settlement-month-detail',
      component: AdminSettlementMonthDetail,
    },
    {
      path: '/admin/products/create',
      name: 'admin-products-create',
      component: AdminProductsCreate,
    },
    {
      path: '/admin/products/edit/:id',
      name: 'admin-products-edit',
      component: () => import('@/views/admin/AdminProductsEdit.vue'),
    },
    {
      path: '/admin/notices/list',
      name: 'AdminNoticeList',
      component: AdminNoticeList,
    },
    {
      path: '/admin/notices/create',
      name: 'AdminNoticeCreate',
      component: AdminNoticeCreate,
    },
    {
      path: '/admin/notices/detail/:id',
      name: 'AdminNoticeDetail',
      component: AdminNoticeDetail,
    },
    {
      path: '/admin/notices/edit/:id',
      name: 'AdminNoticeEdit',
      component: AdminNoticeEdit,
    },
    {
      path: '/signup',
      name: 'signup',
      component: SignupView,
    },
    {
      path: '/login',
      name: 'login',
      component: LoginView,
    },
    {
      path: '/filter/list',
      name: 'user-filter-list',
      component: UserFilterList,
    },
    {
      path: '/filter/create',
      name: 'user-filter-create',
      component: UserFilterCreate,
    },
    {
      path: '/edi/list',
      name: 'user-edi-list',
      component: UserEdiList,
    },
    {
      path: '/edi/submit',
      name: 'user-edi-submit',
      component: () => import('@/views/user/UserEdiSubmit.vue'),
    },
    {
      path: '/settlement/month',
      name: 'user-settlement-month',
      component: UserSettlementMonth,
    },
    {
      path: '/settlement/month/:month',
      name: 'user-settlement-month-detail',
      component: UserSettlementMonthDatail,
    },
    {
      path: '/products/list',
      name: 'user-products-list',
      component: UserProductsList,
    },
    {
      path: '/notice/list',
      name: 'UserNoticesList',
      component: UserNoticesList,
    },
    {
      path: '/notice/detail/:id',
      name: 'UserNoticesDatail',
      component: UserNoticesDatail,
    },
    {
      path: '/admin/hospitals/list',
      name: 'AdminHospitalsList',
      component: () => import('@/views/admin/AdminHospitalsList.vue'),
      meta: { requiresAuth: true, admin: true }
    },
    {
      path: '/admin/hospitals/create',
      name: 'AdminHospitalsCreate',
      component: () => import('@/views/admin/AdminHospitalsCreate.vue'),
      meta: { requiresAuth: true, admin: true }
    },
    {
      path: '/hospitals/list',
      name: 'UserHospitalsList',
      component: () => import('@/views/user/UserHospitalsList.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/hospitals/create',
      name: 'UserHospitalsCreate',
      component: () => import('@/views/user/UserHospitalsCreate.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/hospitals/edit/:id',
      name: 'UserHospitalsEdit',
      component: () => import('@/views/user/UserHospitalsEdit.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/edi/submit/:settlementMonthId/:hospitalId',
      name: 'user-edi-file-detail',
      component: () => import('@/views/user/UserEdiSubmitDetail.vue'),
    },
    {
      path: '/admin/hospitals/edit/:id',
      name: 'AdminHospitalsEdit',
      component: () => import('@/views/admin/AdminHospitalsEdit.vue'),
      meta: { requiresAuth: true, admin: true }
    },
  ],
})

router.beforeEach(async (to, from, next) => {
  // 로그인, 회원가입 페이지는 항상 허용
  if (to.path === '/login' || to.path === '/signup') {
    return next();
  }
  // Supabase 인증 체크
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) {
    // 비로그인 상태면 무조건 /login으로 이동
    return next('/login');
  }
  // 로그인 상태면 정상 진행
  next();
});

export default router
