/*import '@primevue/themes/lara-light-blue/theme.css';*/
import 'primeicons/primeicons.css';

// 기타 전역 CSS
import '@/assets/buttons.css';

// JS/라이브러리 import
import { createApp } from 'vue';
import { createPinia } from 'pinia';

import App from './App.vue';
import router from './router';

import PrimeVue from 'primevue/config';
import Aura from '@primevue/themes/aura';
import ConfirmationService from 'primevue/confirmationservice';
import ToastService from 'primevue/toastservice';
import VCalendar from 'v-calendar';
import { library } from '@fortawesome/fontawesome-svg-core'
import { FontAwesomeIcon } from '@fortawesome/vue-fontawesome'
import { 
  faUsers, faBoxArchive, faFilter, faWallet, faList, 
  faListCheck, faUpload, faBullhorn, faBuilding as faBuildingSolid, faCapsules, faPills, faTablets,
  faMoneyBillWave, faFileInvoiceDollar, faCreditCard, faCoins, faBook, faBookOpen
} from '@fortawesome/free-solid-svg-icons'
import { 
  faHospital, faBuilding, faCalendarDays, faFileLines
} from '@fortawesome/free-regular-svg-icons'

// 1. PrimeVue 테마 CSS를 먼저 로드
// import '@primevue/themes/lara-light-blue/theme.css';
import 'v-calendar/style.css';

// 2. 그 다음에 우리 커스텀 CSS를 로드
import '@/assets/buttons.css';
import './assets/main.css';

library.add(
  faUsers, faBoxArchive, faFilter, faWallet, faList, 
  faListCheck, faUpload, faBullhorn, faBuildingSolid, faCapsules, faPills, faTablets,
  faMoneyBillWave, faFileInvoiceDollar, faCreditCard, faCoins, faBook, faBookOpen,
  faHospital, faBuilding, faCalendarDays, faFileLines
)

const app = createApp(App);

app.use(createPinia());
app.use(router);
app.use(PrimeVue, { 
  theme: Aura,
  locale: {
    firstDayOfWeek: 0, // 0: 일요일, 1: 월요일
    dayNames: ['일요일', '월요일', '화요일', '수요일', '목요일', '금요일', '토요일'],
    dayNamesShort: ['일', '월', '화', '수', '목', '금', '토'],
    dayNamesMin: ['일', '월', '화', '수', '목', '금', '토'],
    monthNames: ['1월', '2월', '3월', '4월', '5월', '6월', '7월', '8월', '9월', '10월', '11월', '12월'],
    monthNamesShort: ['1월', '2월', '3월', '4월', '5월', '6월', '7월', '8월', '9월', '10월', '11월', '12월'],
    today: '오늘',
    clear: '초기화',
    // dateFormat: 'yy/mm/dd', // 필요한 경우 전역 날짜 형식 설정
  }
});

// PrimeVue 서비스 등록
app.use(ConfirmationService);
app.use(ToastService);
app.use(VCalendar, {});
app.component('font-awesome-icon', FontAwesomeIcon)

app.mount('#app');
