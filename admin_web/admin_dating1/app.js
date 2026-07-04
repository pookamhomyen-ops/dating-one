// Dating One - Admin Panel Controller Logic
// Built using vanilla ES6 JS and Supabase SDK client

// Default Project Configurations
const DEFAULT_URL = 'https://kjvfvttvdnjpomchwaoi.supabase.co';
const DEFAULT_ANON = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtqdmZ2dHR2ZG5qcG9tY2h3YW9pIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk4MDA0MDQsImV4cCI6MjA5NTM3NjQwNH0.1_euqabF7oiUH3S2uVwaT2PCgK8iLuFGGbSVhYuDwnc';

// Supabase Clients
let supabaseClient = null;
let supabaseGameClient = null;
let hasServiceRole = false;

// App State
const state = {
    activeTab: 'dashboard',
    currentPage: 1,
    pageSize: 10,
    totalMembersCount: 0,
    profilesCache: [],
    interestsCache: [],
    settlementsCache: [],
    selectedProfileId: null,
    selectedReportId: null,
    selectedSettlementId: null,
    reportsStatusFilter: 'pending',
    postsSearch: '',
    settlementsSearch: '',
    filters: {
        search: '',
        gender: 'all',
        status: 'all',
        province: '',
        ageMin: 18,
        ageMax: 60
    }
};

// Initialize Application
document.addEventListener('DOMContentLoaded', async () => {
    initSettings();
    initSupabase();
    setupEventListeners();
    await checkDatabaseConnection();
    await loadActiveTab();
});

// =============================================================================
// Supabase Client Setup & Connection Check
// =============================================================================

function initSettings() {
    // Fill settings page with saved configs or defaults
    const url = localStorage.getItem('admin_supabase_url') || DEFAULT_URL;
    const anon = localStorage.getItem('admin_supabase_anon') || DEFAULT_ANON;
    const service = localStorage.getItem('admin_supabase_service') || '';

    document.getElementById('settings-supabase-url').value = url;
    document.getElementById('settings-supabase-anon').value = anon;
    document.getElementById('settings-supabase-service').value = service;
}

function initSupabase() {
    const url = document.getElementById('settings-supabase-url').value.trim();
    const anon = document.getElementById('settings-supabase-anon').value.trim();
    const service = document.getElementById('settings-supabase-service').value.trim();

    // Use Service Role Key if provided to bypass RLS, otherwise fallback to Anon Key
    const key = service ? service : anon;
    hasServiceRole = !!service;

    if (!url || !key) {
        showToast('กรุณาตั้งค่า Supabase URL และ Key ในหน้าตั้งค่า', 'danger');
        updateConnectionStatus('error', 'ไม่มีการตั้งค่า Key');
        return;
    }

    try {
        const { createClient } = supabase;
        // Client for public schema
        supabaseClient = createClient(url, key, {
            auth: { persistSession: false }
        });

        // Client for game schema (for Settlements / Troops / Buildings etc.)
        supabaseGameClient = createClient(url, key, {
            db: { schema: 'game' },
            auth: { persistSession: false }
        });
    } catch (err) {
        console.error('Supabase initialization failed:', err);
        showToast('ไม่สามารถเชื่อมต่อ Supabase SDK ได้: ' + err.message, 'danger');
        updateConnectionStatus('error', 'เกิดข้อผิดพลาด SDK');
    }
}

async function checkDatabaseConnection() {
    if (!supabaseClient) return;
    
    updateConnectionStatus('checking', 'กำลังตรวจสอบ...');
    try {
        // Quick select to check if connection works
        const { data, error } = await supabaseClient.from('profiles').select('id', { count: 'exact', head: true });
        
        if (error) throw error;

        if (hasServiceRole) {
            updateConnectionStatus('connected', 'ผู้ดูแลระบบ (Bypass RLS)');
        } else {
            updateConnectionStatus('readonly', 'โหมดอ่านอย่างเดียว (ติด RLS)');
        }
        
        // Load report counts for sidebar badge
        updatePendingReportsBadge();
    } catch (err) {
        console.error('Database connection check failed:', err);
        updateConnectionStatus('error', 'เชื่อมต่อล้มเหลว / Key ไม่ถูกต้อง');
        showToast('เชื่อมต่อฐานข้อมูลล้มเหลว กรุณาตรวจสอบการตั้งค่าเชื่อมต่อ', 'danger');
    }
}

function updateConnectionStatus(type, message) {
    const dot = document.getElementById('db-status-dot');
    const text = document.getElementById('db-status-text');
    
    dot.className = 'status-indicator';
    dot.classList.add(type);
    text.innerText = `Supabase: ${message}`;
}

async function updatePendingReportsBadge() {
    if (!supabaseClient) return;
    try {
        const { count, error } = await supabaseClient
            .from('reports')
            .select('id', { count: 'exact', head: true })
            .eq('status', 'pending');
        
        if (!error && count !== null) {
            const badge = document.getElementById('badge-reports-count');
            if (count > 0) {
                badge.innerText = count;
                badge.style.display = 'inline-flex';
            } else {
                badge.style.display = 'none';
            }
        }
    } catch (err) {
        console.error('Error fetching reports badge count:', err);
    }
}

// =============================================================================
// Tab Routing and Loading Logic
// =============================================================================

function setupEventListeners() {
    // 1. Sidebar Tab Switching
    const navItems = document.querySelectorAll('.nav-item');
    navItems.forEach(item => {
        item.addEventListener('click', async (e) => {
            const tabName = e.currentTarget.getAttribute('data-tab');
            switchTab(tabName);
        });
    });

    // 2. Global Refresh Button
    document.getElementById('btn-global-refresh').addEventListener('click', async () => {
        showToast('กำลังโหลดข้อมูลใหม่...', 'info');
        await loadActiveTab();
    });

    // 3. Settings Actions
    document.getElementById('btn-save-settings').addEventListener('click', () => {
        const url = document.getElementById('settings-supabase-url').value.trim();
        const anon = document.getElementById('settings-supabase-anon').value.trim();
        const service = document.getElementById('settings-supabase-service').value.trim();

        localStorage.setItem('admin_supabase_url', url);
        localStorage.setItem('admin_supabase_anon', anon);
        localStorage.setItem('admin_supabase_service', service);

        showToast('บันทึกการตั้งค่าเชื่อมต่อแล้ว กำลังรีโหลด...', 'success');
        initSupabase();
        checkDatabaseConnection().then(() => loadActiveTab());
    });

    document.getElementById('btn-reset-settings').addEventListener('click', () => {
        if (confirm('คุณต้องการรีเซ็ตการตั้งค่าเป็นค่าเริ่มต้นของโปรเจ็กต์ใช่หรือไม่?')) {
            localStorage.removeItem('admin_supabase_url');
            localStorage.removeItem('admin_supabase_anon');
            localStorage.removeItem('admin_supabase_service');
            initSettings();
            initSupabase();
            checkDatabaseConnection().then(() => loadActiveTab());
            showToast('รีเซ็ตเป็นค่าเริ่มต้นเรียบร้อย', 'success');
        }
    });

    // Password toggle
    document.getElementById('btn-toggle-service-key-visibility').addEventListener('click', () => {
        const input = document.getElementById('settings-supabase-service');
        const icon = document.querySelector('#btn-toggle-service-key-visibility i');
        if (input.type === 'password') {
            input.type = 'text';
            icon.className = 'fa-solid fa-eye-slash';
        } else {
            input.type = 'password';
            icon.className = 'fa-solid fa-eye';
        }
    });

    // 4. Double Age Range Slider Listener
    const ageMinSlider = document.getElementById('filter-age-min');
    const ageMaxSlider = document.getElementById('filter-age-max');
    const ageRangeLabel = document.getElementById('label-age-range');

    const updateAgeLabel = () => {
        let min = parseInt(ageMinSlider.value);
        let max = parseInt(ageMaxSlider.value);
        if (min > max) {
            // Prevent overlaying
            const temp = min;
            min = max;
            max = temp;
        }
        ageRangeLabel.innerText = `${min} - ${max} ปี`;
    };

    ageMinSlider.addEventListener('input', updateAgeLabel);
    ageMaxSlider.addEventListener('input', updateAgeLabel);

    // 5. Members Tab Filter Buttons
    document.getElementById('btn-apply-filters').addEventListener('click', async () => {
        state.currentPage = 1;
        state.filters.search = document.getElementById('search-member').value.trim();
        state.filters.gender = document.getElementById('filter-gender').value;
        state.filters.status = document.getElementById('filter-status').value;
        state.filters.province = document.getElementById('filter-province').value.trim();
        
        let min = parseInt(ageMinSlider.value);
        let max = parseInt(ageMaxSlider.value);
        if (min > max) {
            state.filters.ageMin = max;
            state.filters.ageMax = min;
        } else {
            state.filters.ageMin = min;
            state.filters.ageMax = max;
        }

        await fetchMembers();
    });

    document.getElementById('btn-clear-filters').addEventListener('click', async () => {
        document.getElementById('search-member').value = '';
        document.getElementById('filter-gender').value = 'all';
        document.getElementById('filter-status').value = 'all';
        document.getElementById('filter-province').value = '';
        ageMinSlider.value = 18;
        ageMaxSlider.value = 60;
        ageRangeLabel.innerText = '18 - 60 ปี';

        state.currentPage = 1;
        state.filters = {
            search: '',
            gender: 'all',
            status: 'all',
            province: '',
            ageMin: 18,
            ageMax: 60
        };

        await fetchMembers();
    });

    // Pagination
    document.getElementById('btn-prev-page').addEventListener('click', async () => {
        if (state.currentPage > 1) {
            state.currentPage--;
            await fetchMembers();
        }
    });

    document.getElementById('btn-next-page').addEventListener('click', async () => {
        const maxPage = Math.ceil(state.totalMembersCount / state.pageSize);
        if (state.currentPage < maxPage) {
            state.currentPage++;
            await fetchMembers();
        }
    });

    // Dashboard navigation links
    document.querySelectorAll('.btn-view-all-members').forEach(btn => {
        btn.addEventListener('click', () => switchTab('members'));
    });
    document.querySelectorAll('.btn-view-all-reports').forEach(btn => {
        btn.addEventListener('click', () => switchTab('reports'));
    });

    // 6. Reports segmented tabs
    const segmentBtns = document.querySelectorAll('#report-status-tabs .segment-btn');
    segmentBtns.forEach(btn => {
        btn.addEventListener('click', async (e) => {
            segmentBtns.forEach(b => b.classList.remove('active'));
            e.currentTarget.classList.add('active');
            state.reportsStatusFilter = e.currentTarget.getAttribute('data-status');
            await fetchReports();
        });
    });

    // 7. Modals close buttons
    document.getElementById('btn-close-profile-details').addEventListener('click', () => closeModal('modal-profile-details'));
    document.getElementById('btn-close-profile-details-footer').addEventListener('click', () => closeModal('modal-profile-details'));
    document.getElementById('btn-close-edit-profile').addEventListener('click', () => closeModal('modal-edit-profile'));
    document.getElementById('btn-cancel-edit-profile').addEventListener('click', () => closeModal('modal-edit-profile'));
    document.getElementById('btn-close-cheat-resources').addEventListener('click', () => closeModal('modal-cheat-resources'));
    document.getElementById('btn-cancel-cheat-resources').addEventListener('click', () => closeModal('modal-cheat-resources'));

    // Profile detail tabs switching
    const profileTabs = document.querySelectorAll('.profile-tab-btn');
    profileTabs.forEach(btn => {
        btn.addEventListener('click', (e) => {
            profileTabs.forEach(b => b.classList.remove('active'));
            e.currentTarget.classList.add('active');
            
            const profileTabName = e.currentTarget.getAttribute('data-profile-tab');
            document.querySelectorAll('.profile-tab-content').forEach(c => c.classList.remove('active'));
            document.getElementById(`profile-tab-${profileTabName}`).classList.add('active');
        });
    });

    // 8. Profile Update Actions
    document.getElementById('btn-toggle-verify-profile').addEventListener('click', handleToggleProfileVerify);
    document.getElementById('btn-edit-profile-trigger').addEventListener('click', openEditProfileModal);
    document.getElementById('btn-save-edit-profile-action').addEventListener('click', handleSaveProfileEdits);
    document.getElementById('btn-delete-profile-trigger').addEventListener('click', handleDeleteProfile);

    // Photo details addition
    document.getElementById('btn-add-member-interest-action').addEventListener('click', handleAddMemberInterest);

    // 9. Posts search
    document.getElementById('btn-search-posts').addEventListener('click', async () => {
        state.postsSearch = document.getElementById('search-post').value.trim();
        await fetchPosts();
    });

    // 10. Interests Tag Master Form
    document.getElementById('form-add-interest').addEventListener('submit', handleAddMasterInterest);

    // 11. Settlements tab search
    document.getElementById('btn-search-settlement').addEventListener('click', async () => {
        state.settlementsSearch = document.getElementById('search-settlement').value.trim();
        await fetchSettlements();
    });

    // Settlement Resources save cheat modal
    document.getElementById('btn-save-cheat-resources-action').addEventListener('click', handleSaveCheatResources);
}

function switchTab(tabName) {
    state.activeTab = tabName;

    // Toggle active class on sidebar items
    document.querySelectorAll('.nav-item').forEach(item => {
        if (item.getAttribute('data-tab') === tabName) {
            item.classList.add('active');
        } else {
            item.classList.remove('active');
        }
    });

    // Toggle tab content display
    document.querySelectorAll('.tab-content').forEach(content => {
        content.classList.remove('active');
    });
    document.getElementById(`tab-${tabName}`).classList.add('active');

    // Update Header title / description
    const titles = {
        dashboard: ['แดชบอร์ด', 'ดูข้อมูลภาพรวมและสถิติการใช้งานระบบ Dating One'],
        members: ['จัดการสมาชิก', 'ค้นหา, กรองข้อมูลโปรไฟล์, เปิดดูรายละเอียดรูปภาพ และแก้ไขโปรไฟล์สมาชิก'],
        reports: ['ระบบรายงานความประพฤติ', 'จัดการข้อร้องเรียน, ปัญหาความประพฤติ และตรวจสอบสมาชิกที่ทำผิดกฎ'],
        posts: ['จัดการโพสต์ & ฟีด', 'ตรวจสอบความเรียบร้อยของโพสต์และคอมเมนต์ และลบโพสต์ที่ไม่เหมาะสม'],
        interests: ['จัดการแท็กความสนใจ', 'เพิ่มและลบแท็กความสนใจหลัก (Master Interest Tags) ของระบบ'],
        settlements: ['จัดการข้อมูลนิคม (มินิเกม)', 'ตรวจสอบที่ตั้งเมือง พิกัด และปรับแต่งโกงทรัพยากรเกมของแต่ละสมาชิก'],
        settings: ['ตั้งค่าการเชื่อมต่อ', 'เชื่อมต่อกับ Supabase API และเพิ่มสิทธิ์การจัดการระบบด้วย Service Role Key']
    };

    document.getElementById('current-tab-title').innerText = titles[tabName][0];
    document.getElementById('current-tab-desc').innerText = titles[tabName][1];

    loadActiveTab();
}

async function loadActiveTab() {
    if (!supabaseClient) return;

    try {
        switch (state.activeTab) {
            case 'dashboard':
                await fetchStats();
                await fetchRecentData();
                break;
            case 'members':
                await fetchMembers();
                break;
            case 'reports':
                await fetchReports();
                break;
            case 'posts':
                await fetchPosts();
                break;
            case 'interests':
                await fetchInterests();
                break;
            case 'settlements':
                await fetchSettlements();
                break;
        }
    } catch (err) {
        console.error('Error loading tab content:', err);
    }
}

// =============================================================================
// API - 1. Dashboard Operations
// =============================================================================

async function fetchStats() {
    try {
        // Fetch counters via quick count heads
        const getCount = async (table, filterFn = null) => {
            let q = supabaseClient.from(table).select('id', { count: 'exact', head: true });
            if (filterFn) q = filterFn(q);
            const { count, error } = await q;
            if (error) throw error;
            return count || 0;
        };

        const totalMembers = await getCount('profiles');
        const verifiedMembers = await getCount('profiles', q => q.eq('is_verified', true));
        const onlineMembers = await getCount('profiles', q => q.eq('is_online', true));
        const totalMatches = await getCount('matches');
        const pendingReports = await getCount('reports', q => q.eq('status', 'pending'));
        const totalPosts = await getCount('posts');

        document.getElementById('stat-total-members').innerText = totalMembers;
        document.getElementById('stat-verified-members').innerText = verifiedMembers;
        document.getElementById('stat-online-members').innerText = onlineMembers;
        document.getElementById('stat-total-matches').innerText = totalMatches;
        document.getElementById('stat-pending-reports').innerText = pendingReports;
        document.getElementById('stat-total-posts').innerText = totalPosts;

        // Also update reports tab segmented count badge
        document.getElementById('badge-reports-count').innerText = pendingReports;
        if (pendingReports > 0) {
            document.getElementById('badge-reports-count').style.display = 'inline-flex';
        } else {
            document.getElementById('badge-reports-count').style.display = 'none';
        }
    } catch (err) {
        console.error('Stats loading error:', err);
        showToast('เกิดข้อผิดพลาดในการโหลดตัวนับแดชบอร์ด', 'danger');
    }
}

async function fetchRecentData() {
    try {
        // A. Fetch recent signups (last 5 profiles) with photos
        const { data: profiles, error: pErr } = await supabaseClient
            .from('profiles')
            .select('id, display_name, gender, birth_date, province, created_at, profile_photos(public_url)')
            .order('created_at', { ascending: false })
            .limit(5);

        if (pErr) throw pErr;

        const pTbody = document.querySelector('#table-recent-members tbody');
        pTbody.innerHTML = '';
        if (profiles.length === 0) {
            pTbody.innerHTML = `<tr><td colspan="7" class="text-center">ไม่มีสมาชิกในระบบ</td></tr>`;
        } else {
            profiles.forEach(p => {
                // Find primary photo url or get the first sorted photo or fallback avatar
                let photoUrl = 'https://via.placeholder.com/150';
                if (p.profile_photos && p.profile_photos.length > 0) {
                    photoUrl = p.profile_photos[0].public_url || photoUrl;
                }
                
                const tr = document.createElement('tr');
                tr.innerHTML = `
                    <td style="width: 60px;">
                        <img src="${photoUrl}" class="avatar-thumbnail" alt="Avatar">
                    </td>
                    <td>
                        <strong>${escapeHTML(p.display_name)}</strong>
                        <div class="id-hint">${p.id}</div>
                    </td>
                    <td><span class="badge badge-${p.gender}">${translateGender(p.gender)}</span></td>
                    <td>${calculateAge(p.birth_date)} ปี</td>
                    <td>${escapeHTML(p.province) || '-'}</td>
                    <td>${formatDate(p.created_at)}</td>
                    <td>
                        <button class="btn btn-secondary btn-sm btn-view-profile" data-id="${p.id}"><i class="fa-solid fa-eye"></i> ดูข้อมูล</button>
                    </td>
                `;
                pTbody.appendChild(tr);
            });
            
            // Add view profile listeners to buttons
            pTbody.querySelectorAll('.btn-view-profile').forEach(btn => {
                btn.addEventListener('click', (e) => {
                    const id = e.currentTarget.getAttribute('data-id');
                    showProfileDetailsModal(id);
                });
            });
        }

        // B. Fetch recent pending reports (last 5 reports)
        const { data: reports, error: rErr } = await supabaseClient
            .from('reports')
            .select('id, reason, details, created_at, status, reporter:profiles!reporter_id(display_name), reported:profiles!reported_id(display_name)')
            .eq('status', 'pending')
            .order('created_at', { ascending: false })
            .limit(5);

        if (rErr) throw rErr;

        const rTbody = document.querySelector('#table-recent-reports tbody');
        rTbody.innerHTML = '';
        if (reports.length === 0) {
            rTbody.innerHTML = `<tr><td colspan="6" class="text-center">ไม่มีรายงานค้างค้างในระบบ</td></tr>`;
        } else {
            reports.forEach(r => {
                const tr = document.createElement('tr');
                tr.innerHTML = `
                    <td><strong>${escapeHTML(r.reporter?.display_name || 'สมาชิกเก่า')}</strong></td>
                    <td><strong class="text-danger">${escapeHTML(r.reported?.display_name || 'สมาชิกเก่า')}</strong></td>
                    <td><span class="badge badge-danger">${escapeHTML(r.reason)}</span></td>
                    <td>${formatDate(r.created_at)}</td>
                    <td><span class="badge badge-warning">รอดำเนินการ</span></td>
                    <td>
                        <button class="btn btn-primary btn-sm btn-manage-report" data-tab="reports"><i class="fa-solid fa-circle-exclamation"></i> จัดการ</button>
                    </td>
                `;
                rTbody.appendChild(tr);
            });
            
            rTbody.querySelectorAll('.btn-manage-report').forEach(btn => {
                btn.addEventListener('click', () => switchTab('reports'));
            });
        }
    } catch (err) {
        console.error('Error fetching recent dashboard data:', err);
    }
}

// =============================================================================
// API - 2. Members Management
// =============================================================================

async function fetchMembers() {
    try {
        const tbody = document.querySelector('#table-members tbody');
        tbody.innerHTML = `<tr><td colspan="8" class="text-center">กำลังค้นหาข้อมูล...</td></tr>`;

        // Calculate offset for pagination
        const from = (state.currentPage - 1) * state.pageSize;
        const to = from + state.pageSize - 1;

        // Build query
        let query = supabaseClient
            .from('profiles')
            .select('id, display_name, gender, birth_date, province, district, is_verified, is_online, created_at, profile_photos(public_url)', { count: 'exact' });

        // Apply Search (display_name or ID)
        if (state.filters.search) {
            const searchVal = state.filters.search;
            // Check if search is a valid UUID pattern
            const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
            if (uuidRegex.test(searchVal)) {
                query = query.eq('id', searchVal);
            } else {
                query = query.ilike('display_name', `%${searchVal}%`);
            }
        }

        // Apply Gender Filter
        if (state.filters.gender !== 'all') {
            query = query.eq('gender', state.filters.gender);
        }

        // Apply Status Filter
        if (state.filters.status === 'verified') {
            query = query.eq('is_verified', true);
        } else if (state.filters.status === 'unverified') {
            query = query.eq('is_verified', false);
        } else if (state.filters.status === 'online') {
            query = query.eq('is_online', true);
        }

        // Apply Province Filter
        if (state.filters.province) {
            query = query.ilike('province', `%${state.filters.province}%`);
        }

        // Apply Age Range Filter (Calculated via Birth Date)
        const today = new Date();
        const minBirthDate = new Date();
        minBirthDate.setFullYear(today.getFullYear() - state.filters.ageMax - 1);
        const maxBirthDate = new Date();
        maxBirthDate.setFullYear(today.getFullYear() - state.filters.ageMin);

        query = query.gte('birth_date', minBirthDate.toISOString().split('T')[0])
                     .lte('birth_date', maxBirthDate.toISOString().split('T')[0]);

        // Execute query
        const { data, count, error } = await query
            .order('created_at', { ascending: false })
            .range(from, to);

        if (error) throw error;

        state.totalMembersCount = count || 0;
        state.profilesCache = data || [];

        tbody.innerHTML = '';
        document.getElementById('total-members-count').innerText = state.totalMembersCount;

        if (state.profilesCache.length === 0) {
            tbody.innerHTML = `<tr><td colspan="8" class="text-center">ไม่พบสมาชิกตามเงื่อนไขที่กำหนด</td></tr>`;
            updatePaginationUI(0);
            return;
        }

        state.profilesCache.forEach(p => {
            let photoUrl = 'https://via.placeholder.com/150';
            if (p.profile_photos && p.profile_photos.length > 0) {
                photoUrl = p.profile_photos[0].public_url || photoUrl;
            }

            const tr = document.createElement('tr');
            tr.innerHTML = `
                <td style="width: 60px;">
                    <img src="${photoUrl}" class="avatar-thumbnail" alt="Avatar">
                </td>
                <td>
                    <strong>${escapeHTML(p.display_name)}</strong>
                    <div class="id-hint">${p.id}</div>
                </td>
                <td><span class="badge badge-${p.gender}">${translateGender(p.gender)}</span></td>
                <td>${calculateAge(p.birth_date)} ปี</td>
                <td>${escapeHTML(p.province) || '-'} / ${escapeHTML(p.district) || '-'}</td>
                <td>
                    <span class="badge badge-${p.is_verified ? 'success' : 'danger'}">
                        <i class="fa-solid fa-${p.is_verified ? 'circle-check' : 'circle-xmark'}"></i>
                        ${p.is_verified ? 'ยืนยันแล้ว' : 'ยังไม่ยืนยัน'}
                    </span>
                </td>
                <td>
                    <div class="online-indicator">
                        <div class="online-dot ${p.is_online ? 'active' : ''}"></div>
                        <span>${p.is_online ? 'กำลังออนไลน์' : 'ออฟไลน์'}</span>
                    </div>
                </td>
                <td>
                    <button class="btn btn-secondary btn-sm btn-view-profile" data-id="${p.id}"><i class="fa-solid fa-folder-open"></i> รายละเอียด</button>
                </td>
            `;
            tbody.appendChild(tr);
        });

        tbody.querySelectorAll('.btn-view-profile').forEach(btn => {
            btn.addEventListener('click', (e) => {
                const id = e.currentTarget.getAttribute('data-id');
                showProfileDetailsModal(id);
            });
        });

        updatePaginationUI(count);
    } catch (err) {
        console.error('Error fetching members list:', err);
        showToast('เกิดข้อผิดพลาดในการดึงข้อมูลสมาชิก', 'danger');
    }
}

function updatePaginationUI(totalItems) {
    const maxPage = Math.max(1, Math.ceil(totalItems / state.pageSize));
    document.getElementById('page-indicator').innerText = `หน้า ${state.currentPage} / ${maxPage}`;
    
    document.getElementById('btn-prev-page').disabled = (state.currentPage === 1);
    document.getElementById('btn-next-page').disabled = (state.currentPage === maxPage);
}

// =============================================================================
// API - Profile Details Modal & Photo Operations
// =============================================================================

async function showProfileDetailsModal(profileId) {
    state.selectedProfileId = profileId;
    openModal('modal-profile-details');

    // Reset tab on modal load
    document.querySelectorAll('.profile-tab-btn').forEach(b => b.classList.remove('active'));
    document.querySelector('[data-profile-tab="info"]').classList.add('active');
    document.querySelectorAll('.profile-tab-content').forEach(c => c.classList.remove('active'));
    document.getElementById('profile-tab-info').classList.add('active');

    // Fill placeholder states
    document.getElementById('profile-detail-avatar').src = 'https://via.placeholder.com/150';
    document.getElementById('profile-detail-name').innerText = 'กำลังโหลด...';
    document.getElementById('profile-detail-gender').innerText = '-';
    document.getElementById('profile-detail-age').innerText = '-';
    document.getElementById('profile-detail-bio').innerText = 'กำลังโหลดคำแนะนำตัว...';
    document.getElementById('grid-profile-photos').innerHTML = 'กำลังโหลดรูปภาพ...';
    document.getElementById('grid-secret-photos').innerHTML = 'กำลังโหลดรูปภาพลับ...';
    document.getElementById('profile-detail-interests').innerHTML = 'กำลังโหลดความสนใจ...';
    
    try {
        // 1. Fetch Profile info
        const { data: p, error: pErr } = await supabaseClient
            .from('profiles')
            .select('*')
            .eq('id', profileId)
            .single();

        if (pErr) throw pErr;

        // Apply info to left side card
        document.getElementById('profile-detail-name').innerText = p.display_name || 'ไม่มีชื่อแสดง';
        document.getElementById('profile-detail-gender').innerText = translateGender(p.gender);
        document.getElementById('profile-detail-age').innerText = calculateAge(p.birth_date);
        
        // Verification badge status
        const vBadge = document.getElementById('badge-detail-verified');
        vBadge.className = `badge badge-${p.is_verified ? 'success' : 'danger'}`;
        vBadge.innerHTML = `<i class="fa-solid fa-${p.is_verified ? 'circle-check' : 'circle-xmark'}"></i> ${p.is_verified ? 'ยืนยันแล้ว' : 'ยังไม่ยืนยัน'}`;
        
        // Verify action button text
        const vBtn = document.getElementById('btn-toggle-verify-profile');
        vBtn.className = `btn btn-block ${p.is_verified ? 'btn-danger' : 'btn-primary'}`;
        vBtn.innerHTML = p.is_verified ? `<i class="fa-solid fa-circle-xmark"></i> ยกเลิกการยืนยัน` : `<i class="fa-solid fa-circle-check"></i> ยืนยันตัวตนโปรไฟล์`;

        // Online status badge
        const oBadge = document.getElementById('badge-detail-online');
        oBadge.className = `badge badge-${p.is_online ? 'success' : 'warning'}`;
        oBadge.innerText = p.is_online ? 'ออนไลน์' : 'ออฟไลน์';

        // Stats
        document.getElementById('profile-detail-views').innerText = p.profile_views_count;
        document.getElementById('profile-detail-likes').innerText = p.likes_received_count;
        document.getElementById('profile-detail-joined').innerText = formatDate(p.created_at);

        // Apply info to right side details
        document.getElementById('profile-detail-bio').innerText = p.bio || 'ไม่มีคำแนะนำตัว';
        document.getElementById('profile-detail-university').innerText = p.university || 'ไม่ระบุ';
        document.getElementById('profile-detail-occupation').innerText = p.occupation || 'ไม่ระบุ';
        document.getElementById('profile-detail-province').innerText = p.province || 'ไม่ระบุ';
        document.getElementById('profile-detail-district').innerText = p.district || 'ไม่ระบุ';
        document.getElementById('profile-detail-location').innerText = (p.latitude && p.longitude) ? `Lat: ${p.latitude}, Lng: ${p.longitude}` : 'ไม่ได้เชื่อมต่อตำแหน่ง GPS';

        // Social connections
        document.getElementById('profile-detail-line').innerText = p.line_id || '-';
        document.getElementById('profile-detail-ig').innerText = p.instagram || '-';
        document.getElementById('profile-detail-fb').innerText = p.facebook || '-';
        document.getElementById('profile-detail-x').innerText = p.x_handle || '-';

        // 2. Fetch photos
        const { data: photos, error: phErr } = await supabaseClient
            .from('profile_photos')
            .select('*')
            .eq('profile_id', profileId)
            .order('sort_order', { ascending: true });

        if (phErr) throw phErr;

        // Set left panel avatar to primary photo if available
        let primaryPhoto = photos.find(ph => ph.is_primary) || photos[0];
        if (primaryPhoto) {
            document.getElementById('profile-detail-avatar').src = primaryPhoto.public_url;
        }

        // Render public photos tab
        const pGrid = document.getElementById('grid-profile-photos');
        pGrid.innerHTML = '';
        if (photos.length === 0) {
            pGrid.innerHTML = `<div class="text-center py-3 flex-1">ไม่มีรูปโปรไฟล์สาธารณะ</div>`;
        } else {
            photos.forEach(ph => {
                const card = document.createElement('div');
                card.className = 'photo-card';
                card.innerHTML = `
                    <img src="${ph.public_url}" alt="Profile Photo">
                    ${ph.is_primary ? `<span class="photo-badge">หลัก</span>` : ''}
                    <button class="photo-delete-overlay btn-delete-photo" data-id="${ph.id}"><i class="fa-solid fa-trash-can"></i> ลบรูปภาพ</button>
                `;
                pGrid.appendChild(card);
            });
            
            pGrid.querySelectorAll('.btn-delete-photo').forEach(btn => {
                btn.addEventListener('click', (e) => {
                    const photoId = e.currentTarget.getAttribute('data-id');
                    handleDeletePhoto(photoId, false);
                });
            });
        }

        // 3. Fetch Secret Photos
        const { data: secretPhotos, error: secErr } = await supabaseClient
            .from('secret_photos')
            .select('*')
            .eq('profile_id', profileId);

        if (secErr) throw secErr;

        const sGrid = document.getElementById('grid-secret-photos');
        sGrid.innerHTML = '';
        if (secretPhotos.length === 0) {
            sGrid.innerHTML = `<div class="text-center py-3 flex-1">ไม่มีรูปภาพลับ (Secret Photo)</div>`;
        } else {
            secretPhotos.forEach(ph => {
                const card = document.createElement('div');
                card.className = 'photo-card';
                card.innerHTML = `
                    <img src="${ph.public_url}" alt="Secret Photo">
                    <span class="photo-badge-secret"><i class="fa-solid fa-lock"></i> ลับ</span>
                    <button class="photo-delete-overlay btn-delete-secret-photo" data-id="${ph.id}"><i class="fa-solid fa-trash-can"></i> ลบรูปภาพ</button>
                `;
                sGrid.appendChild(card);
            });

            sGrid.querySelectorAll('.btn-delete-secret-photo').forEach(btn => {
                btn.addEventListener('click', (e) => {
                    const photoId = e.currentTarget.getAttribute('data-id');
                    handleDeletePhoto(photoId, true);
                });
            });
        }

        // Update photo counts indicator tab
        document.getElementById('photo-count-indicator').innerText = photos.length + secretPhotos.length;

        // 4. Fetch Interests
        const { data: memberInterests, error: intErr } = await supabaseClient
            .from('profile_interests')
            .select('interest_id, interests(name)')
            .eq('profile_id', profileId);

        if (intErr) throw intErr;

        const intContainer = document.getElementById('profile-detail-interests');
        intContainer.innerHTML = '';
        if (memberInterests.length === 0) {
            intContainer.innerHTML = `<div class="text-secondary" style="font-size: 13px;">ไม่ได้เลือกความสนใจ</div>`;
        } else {
            memberInterests.forEach(item => {
                const pill = document.createElement('div');
                pill.className = 'interest-pill';
                pill.innerHTML = `
                    <span># ${escapeHTML(item.interests?.name || 'แท็กเก่า')}</span>
                    <button class="btn-remove-tag btn-remove-member-interest" data-id="${item.interest_id}"><i class="fa-solid fa-xmark"></i></button>
                `;
                intContainer.appendChild(pill);
            });

            intContainer.querySelectorAll('.btn-remove-member-interest').forEach(btn => {
                btn.addEventListener('click', (e) => {
                    const interestId = e.currentTarget.getAttribute('data-id');
                    handleRemoveMemberInterest(interestId);
                });
            });
        }

        // Fill Add Tag dropdown with master list options that the user does not have yet
        await populateAddInterestDropdown(memberInterests.map(mi => mi.interest_id));

        // 5. Fetch Strategy Game Settlement summary
        await fetchProfileGameInfo(profileId);

    } catch (err) {
        console.error('Error loading profile details:', err);
        showToast('ไม่สามารถดึงข้อมูลรายละเอียดโปรไฟล์ได้: ' + err.message, 'danger');
        closeModal('modal-profile-details');
    }
}

async function populateAddInterestDropdown(userInterestIds) {
    try {
        const select = document.getElementById('select-add-member-interest');
        select.innerHTML = '<option value="">-- เลือกแท็กที่ต้องการเพิ่ม --</option>';

        // Fetch master list of interests
        const { data: allInt, error } = await supabaseClient
            .from('interests')
            .select('id, name')
            .order('name', { ascending: true });

        if (error) throw error;

        allInt.forEach(item => {
            if (!userInterestIds.includes(item.id)) {
                const opt = document.createElement('option');
                opt.value = item.id;
                opt.innerText = item.name;
                select.appendChild(opt);
            }
        });
    } catch (err) {
        console.error('Error populating add interest dropdown:', err);
    }
}

async function fetchProfileGameInfo(profileId) {
    const card = document.getElementById('profile-game-info-card');
    card.innerHTML = `<p class="text-center py-5">กำลังโหลดข้อมูลเมืองมินิเกม...</p>`;

    try {
        // Query settlement from game schema
        const { data: set, error } = await supabaseGameClient
            .from('settlements')
            .select('*')
            .eq('player_id', profileId)
            .maybeSingle();

        if (error) throw error;

        if (!set) {
            card.innerHTML = `
                <div class="text-center py-4">
                    <i class="fa-solid fa-chess-rook text-secondary" style="font-size: 40px; margin-bottom: 12px; display: block;"></i>
                    <p class="text-secondary" style="font-size: 13.5px;">สมาชิกท่านนี้ยังไม่ได้สร้างเมือง/นิคมในมินิเกม</p>
                </div>
            `;
            return;
        }

        // Render mini-game details
        card.innerHTML = `
            <div class="game-summary-header">
                <h3>🏰 เมือง: ${escapeHTML(set.name)}</h3>
                <span class="badge badge-primary">พิกัด X:${set.map_x} Y:${set.map_y}</span>
            </div>
            <div class="game-resources-grid">
                <div class="game-resource-pill">
                    <i class="fa-solid fa-tree text-success"></i>
                    <div>
                        <label>ไม้ (Wood)</label>
                        <strong>${set.wood}</strong>
                    </div>
                </div>
                <div class="game-resource-pill">
                    <i class="fa-solid fa-cubes-stacked text-info"></i>
                    <div>
                        <label>เหล็ก (Iron)</label>
                        <strong>${set.iron}</strong>
                    </div>
                </div>
                <div class="game-resource-pill">
                    <i class="fa-solid fa-wheat-awn text-warning"></i>
                    <div>
                        <label>ข้าว (Rice)</label>
                        <strong>${set.rice}</strong>
                    </div>
                </div>
                <div class="game-resource-pill">
                    <i class="fa-solid fa-wine-glass text-danger"></i>
                    <div>
                        <label>สุรา (Liquor)</label>
                        <strong>${set.liquor}</strong>
                    </div>
                </div>
            </div>
            <div style="margin-top: 16px; text-align: right;">
                <button class="btn btn-secondary btn-sm" id="btn-cheat-profile-settlement" data-id="${set.id}">
                    <i class="fa-solid fa-gear"></i> แก้ไขทรัพยากรเมือง
                </button>
            </div>
        `;

        document.getElementById('btn-cheat-profile-settlement').addEventListener('click', (e) => {
            closeModal('modal-profile-details');
            const id = e.currentTarget.getAttribute('data-id');
            openCheatResourcesModal(id);
        });

    } catch (err) {
        console.error('Error fetching profile game info:', err);
        card.innerHTML = `<p class="text-danger text-center py-4">ไม่สามารถโหลดข้อมูลเกมได้: ${err.message}</p>`;
    }
}

// Action: Toggle Profile Verification
async function handleToggleProfileVerify() {
    if (!state.selectedProfileId) return;

    try {
        // Get current status first
        const { data: p, error: fErr } = await supabaseClient
            .from('profiles')
            .select('is_verified')
            .eq('id', state.selectedProfileId)
            .single();

        if (fErr) throw fErr;

        const nextStatus = !p.is_verified;

        // Perform update
        const { error: uErr } = await supabaseClient
            .from('profiles')
            .update({ is_verified: nextStatus })
            .eq('id', state.selectedProfileId);

        if (uErr) throw uErr;

        showToast(`สลับสถานะยืนยันตัวตนสำเร็จ (${nextStatus ? 'ยืนยันตัวตนแล้ว' : 'ยกเลิกการยืนยันแล้ว'})`, 'success');
        
        // Refresh details modal & active list
        await showProfileDetailsModal(state.selectedProfileId);
        await loadActiveTab();
    } catch (err) {
        console.error('Verify toggle error:', err);
        showToast('ล้มเหลว: ' + err.message, 'danger');
    }
}

// Action: Edit Profile Form Open
async function openEditProfileModal() {
    if (!state.selectedProfileId) return;
    
    try {
        const { data: p, error } = await supabaseClient
            .from('profiles')
            .select('*')
            .eq('id', state.selectedProfileId)
            .single();

        if (error) throw error;

        document.getElementById('edit-display-name').value = p.display_name || '';
        document.getElementById('edit-gender').value = p.gender || 'other';
        document.getElementById('edit-birth-date').value = p.birth_date || '';
        document.getElementById('edit-bio').value = p.bio || '';
        document.getElementById('edit-province').value = p.province || '';
        document.getElementById('edit-district').value = p.district || '';
        document.getElementById('edit-university').value = p.university || '';
        document.getElementById('edit-occupation').value = p.occupation || '';
        document.getElementById('edit-line-id').value = p.line_id || '';
        document.getElementById('edit-instagram').value = p.instagram || '';
        document.getElementById('edit-facebook').value = p.facebook || '';
        document.getElementById('edit-x-handle').value = p.x_handle || '';

        openModal('modal-edit-profile');
    } catch (err) {
        showToast('ดึงข้อมูลแก้ไขล้มเหลว: ' + err.message, 'danger');
    }
}

// Action: Save Edited Profile
async function handleSaveProfileEdits() {
    if (!state.selectedProfileId) return;

    const data = {
        display_name: document.getElementById('edit-display-name').value.trim(),
        gender: document.getElementById('edit-gender').value,
        birth_date: document.getElementById('edit-birth-date').value ? document.getElementById('edit-birth-date').value : null,
        bio: document.getElementById('edit-bio').value.trim(),
        province: document.getElementById('edit-province').value.trim(),
        district: document.getElementById('edit-district').value.trim(),
        university: document.getElementById('edit-university').value.trim(),
        occupation: document.getElementById('edit-occupation').value.trim(),
        line_id: document.getElementById('edit-line-id').value.trim(),
        instagram: document.getElementById('edit-instagram').value.trim(),
        facebook: document.getElementById('edit-facebook').value.trim(),
        x_handle: document.getElementById('edit-x-handle').value.trim(),
        updated_at: new Date().toISOString()
    };

    try {
        const { error } = await supabaseClient
            .from('profiles')
            .update(data)
            .eq('id', state.selectedProfileId);

        if (error) throw error;

        showToast('แก้ไขข้อมูลโปรไฟล์สำเร็จ', 'success');
        closeModal('modal-edit-profile');
        
        // Refresh details modal & active list
        await showProfileDetailsModal(state.selectedProfileId);
        await loadActiveTab();
    } catch (err) {
        console.error('Error saving profile edits:', err);
        showToast('บันทึกล้มเหลว: ' + err.message, 'danger');
    }
}

// Action: Delete Profile
async function handleDeleteProfile() {
    if (!state.selectedProfileId) return;

    if (confirm('คำเตือน! คุณต้องการลบสมาชิกท่านนี้ออกจากระบบใช่หรือไม่?\n\nข้อมูลโปรไฟล์ รูปภาพ ข้อความ รายงาน และนิคมเมืองในเกมทั้งหมดจะถูกลบออกแบบไม่สามารถกู้คืนได้!')) {
        try {
            showToast('กำลังลบข้อมูลสมาชิก...', 'info');

            // Attempt to delete user account using admin API (requires Service Role Key)
            if (hasServiceRole) {
                const { error: authErr } = await supabaseClient.auth.admin.deleteUser(state.selectedProfileId);
                if (authErr) throw authErr;
            } else {
                // If service role is not loaded, delete from profiles directly (requires custom bypass or policies, might trigger RLS check)
                const { error: dbErr } = await supabaseClient.from('profiles').delete().eq('id', state.selectedProfileId);
                if (dbErr) throw dbErr;
            }

            showToast('ลบสมาชิกออกจากระบบเสร็จสิ้น', 'success');
            closeModal('modal-profile-details');
            await loadActiveTab();
        } catch (err) {
            console.error('Error deleting member profile:', err);
            showToast('ลบล้มเหลว (หากไม่ได้ใส่ Service Role Key จะติดสิทธิ์ RLS): ' + err.message, 'danger');
        }
    }
}

// Action: Delete Single Photo
async function handleDeletePhoto(photoId, isSecret) {
    if (confirm('คุณต้องการลบรูปภาพนี้ใช่หรือไม่?')) {
        try {
            const table = isSecret ? 'secret_photos' : 'profile_photos';
            const { error } = await supabaseClient
                .from(table)
                .delete()
                .eq('id', photoId);

            if (error) throw error;

            showToast('ลบรูปภาพสำเร็จ', 'success');
            
            // Refresh photo gallery
            await showProfileDetailsModal(state.selectedProfileId);
        } catch (err) {
            console.error('Error deleting photo:', err);
            showToast('ลบรูปภาพล้มเหลว: ' + err.message, 'danger');
        }
    }
}

// Action: Add Interest to Profile
async function handleAddMemberInterest() {
    const interestId = document.getElementById('select-add-member-interest').value;
    if (!interestId || !state.selectedProfileId) return;

    try {
        const { error } = await supabaseClient
            .from('profile_interests')
            .insert({
                profile_id: state.selectedProfileId,
                interest_id: interestId
            });

        if (error) throw error;

        showToast('เพิ่มแท็กความสนใจเรียบร้อย', 'success');
        await showProfileDetailsModal(state.selectedProfileId);
    } catch (err) {
        console.error('Error adding interest tag:', err);
        showToast('ไม่สามารถเพิ่มแท็กได้: ' + err.message, 'danger');
    }
}

// Action: Remove Interest from Profile
async function handleRemoveMemberInterest(interestId) {
    if (!state.selectedProfileId) return;

    try {
        const { error } = await supabaseClient
            .from('profile_interests')
            .delete()
            .eq('profile_id', state.selectedProfileId)
            .eq('interest_id', interestId);

        if (error) throw error;

        showToast('ลบแท็กความสนใจเรียบร้อย', 'success');
        await showProfileDetailsModal(state.selectedProfileId);
    } catch (err) {
        console.error('Error removing interest tag:', err);
        showToast('ไม่สามารถลบแท็กได้: ' + err.message, 'danger');
    }
}

// =============================================================================
// API - 3. Reports & Moderation Dashboard
// =============================================================================

async function fetchReports() {
    try {
        const tbody = document.querySelector('#table-reports tbody');
        tbody.innerHTML = `<tr><td colspan="7" class="text-center">กำลังโหลดรายงาน...</td></tr>`;

        // Fetch counts for all segmented tabs to update indicators
        const updateSegmentCounts = async () => {
            const getReportCount = async (status) => {
                const { count } = await supabaseClient
                    .from('reports')
                    .select('id', { count: 'exact', head: true })
                    .eq('status', status);
                return count || 0;
            };
            
            document.getElementById('count-pending-rep').innerText = await getReportCount('pending');
            document.getElementById('count-reviewed-rep').innerText = await getReportCount('reviewed');
            document.getElementById('count-resolved-rep').innerText = await getReportCount('resolved');
            document.getElementById('count-dismissed-rep').innerText = await getReportCount('dismissed');
        };
        
        await updateSegmentCounts();

        // Query active state report filter
        const { data: reports, error } = await supabaseClient
            .from('reports')
            .select('*, reporter:profiles!reporter_id(display_name), reported:profiles!reported_id(display_name)')
            .eq('status', state.reportsStatusFilter)
            .order('created_at', { ascending: false });

        if (error) throw error;

        tbody.innerHTML = '';
        if (reports.length === 0) {
            tbody.innerHTML = `<tr><td colspan="7" class="text-center">ไม่มีข้อร้องเรียน/รายงานประเภทนี้ในระบบ</td></tr>`;
            return;
        }

        reports.forEach(r => {
            const tr = document.createElement('tr');
            
            // Build action buttons depending on report status
            let actionHtml = '';
            if (r.status === 'pending') {
                actionHtml = `
                    <div style="display: flex; gap: 4px;">
                        <button class="btn btn-secondary btn-sm btn-action-review" data-id="${r.id}">กำลังตรวจ</button>
                        <button class="btn btn-primary btn-sm btn-action-resolve" data-id="${r.id}"><i class="fa-solid fa-check"></i> เสร็จสิ้น</button>
                        <button class="btn btn-danger btn-sm btn-action-dismiss" data-id="${r.id}"><i class="fa-solid fa-xmark"></i> ละทิ้ง</button>
                    </div>
                `;
            } else if (r.status === 'reviewed') {
                actionHtml = `
                    <div style="display: flex; gap: 4px;">
                        <button class="btn btn-primary btn-sm btn-action-resolve" data-id="${r.id}"><i class="fa-solid fa-check"></i> เสร็จสิ้น</button>
                        <button class="btn btn-danger btn-sm btn-action-dismiss" data-id="${r.id}"><i class="fa-solid fa-xmark"></i> ละทิ้ง</button>
                    </div>
                `;
            } else {
                actionHtml = `<span class="text-secondary" style="font-size:12px;">จัดการเมื่อ ${formatDate(r.resolved_at)}</span>`;
            }

            tr.innerHTML = `
                <td>
                    <strong>${escapeHTML(r.reporter?.display_name || 'สมาชิกเก่า')}</strong>
                    <div class="id-hint">${r.reporter_id}</div>
                </td>
                <td>
                    <strong class="text-danger cursor-pointer btn-reported-profile-view" data-reported-id="${r.reported_id}">
                        ${escapeHTML(r.reported?.display_name || 'สมาชิกเก่า')} <i class="fa-solid fa-circle-arrow-right"></i>
                    </strong>
                    <div class="id-hint">${r.reported_id}</div>
                </td>
                <td><span class="badge badge-danger">${escapeHTML(r.reason)}</span></td>
                <td>
                    <div style="max-width: 250px; font-size:12.5px; white-space: pre-wrap;">${escapeHTML(r.details) || '-'}</div>
                </td>
                <td>${formatDate(r.created_at)}</td>
                <td><span class="badge badge-${getReportBadgeColor(r.status)}">${translateReportStatus(r.status)}</span></td>
                <td>${actionHtml}</td>
            `;
            tbody.appendChild(tr);
        });

        // Set action triggers
        tbody.querySelectorAll('.btn-reported-profile-view').forEach(btn => {
            btn.addEventListener('click', (e) => {
                const id = e.currentTarget.getAttribute('data-reported-id');
                showProfileDetailsModal(id);
            });
        });

        tbody.querySelectorAll('.btn-action-review').forEach(btn => {
            btn.addEventListener('click', async (e) => {
                const id = e.currentTarget.getAttribute('data-id');
                await updateReportStatus(id, 'reviewed');
            });
        });

        tbody.querySelectorAll('.btn-action-resolve').forEach(btn => {
            btn.addEventListener('click', async (e) => {
                const id = e.currentTarget.getAttribute('data-id');
                await updateReportStatus(id, 'resolved');
            });
        });

        tbody.querySelectorAll('.btn-action-dismiss').forEach(btn => {
            btn.addEventListener('click', async (e) => {
                const id = e.currentTarget.getAttribute('data-id');
                await updateReportStatus(id, 'dismissed');
            });
        });

    } catch (err) {
        console.error('Error fetching reports:', err);
        showToast('ไม่สามารถดึงข้อมูลรายงานได้', 'danger');
    }
}

async function updateReportStatus(reportId, status) {
    try {
        const updates = {
            status: status,
            resolved_at: (status === 'resolved' || status === 'dismissed') ? new Date().toISOString() : null
        };

        const { error } = await supabaseClient
            .from('reports')
            .update(updates)
            .eq('id', reportId);

        if (error) throw error;

        showToast(`อัปเดตสถานะการร้องเรียนเรียบร้อย`, 'success');
        
        // Refresh active reports views & sidebar badge count
        await fetchReports();
        await updatePendingReportsBadge();
    } catch (err) {
        console.error('Error updating report status:', err);
        showToast('อัปเดตสถานะรายงานล้มเหลว: ' + err.message, 'danger');
    }
}

// =============================================================================
// API - 4. Feed & Posts Management
// =============================================================================

async function fetchPosts() {
    const container = document.getElementById('posts-container');
    container.innerHTML = `<div class="text-center py-5">กำลังโหลดข้อมูลโพสต์ฟีด...</div>`;

    try {
        let query = supabaseClient
            .from('posts')
            .select('*, author:profiles!author_id(display_name, profile_photos(public_url)), post_media(*), post_comments(count)');

        // Apply Search Filter on content or author name
        if (state.postsSearch) {
            query = query.ilike('content', `%${state.postsSearch}%`);
        }

        const { data: posts, error } = await query.order('created_at', { ascending: false });

        if (error) throw error;

        container.innerHTML = '';
        if (posts.length === 0) {
            container.innerHTML = `<div class="text-center py-5">ไม่พบโพสต์ฟีดในขณะนี้</div>`;
            return;
        }

        posts.forEach(post => {
            // Find avatar
            let avatarUrl = 'https://via.placeholder.com/150';
            if (post.author?.profile_photos && post.author.profile_photos.length > 0) {
                avatarUrl = post.author.profile_photos[0].public_url || avatarUrl;
            }

            // Media files html
            let mediaHtml = '';
            if (post.post_media && post.post_media.length > 0) {
                mediaHtml = `<div class="post-media-grid">`;
                post.post_media.forEach(m => {
                    if (m.media_type === 'video') {
                        mediaHtml += `<div class="post-media-item"><video src="${m.public_url}" controls></video></div>`;
                    } else {
                        mediaHtml += `<div class="post-media-item"><img src="${m.public_url}" alt="Post Media" class="cursor-pointer"></div>`;
                    }
                });
                mediaHtml += `</div>`;
            }

            const commentsCount = post.post_comments && post.post_comments.length > 0 ? post.post_comments[0].count : 0;

            const card = document.createElement('div');
            card.className = 'post-card';
            card.id = `post-card-${post.id}`;
            card.innerHTML = `
                <div class="post-header">
                    <div class="post-author">
                        <img src="${avatarUrl}" class="post-author-avatar" alt="Avatar">
                        <div class="post-author-info">
                            <span class="post-author-name btn-author-profile-open" data-author-id="${post.author_id}">${escapeHTML(post.author?.display_name || 'สมาชิกเก่า')}</span>
                            <span class="post-date">${formatDate(post.created_at)}</span>
                        </div>
                    </div>
                    <div style="display:flex; gap: 8px;">
                        <button class="btn btn-sm ${post.is_published ? 'btn-secondary' : 'btn-primary'} btn-toggle-publish-post" data-id="${post.id}" data-published="${post.is_published}">
                            ${post.is_published ? '<i class="fa-solid fa-eye-slash"></i> ซ่อนโพสต์' : '<i class="fa-solid fa-eye"></i> เผยแพร่'}
                        </button>
                        <button class="btn btn-danger btn-sm btn-delete-post" data-id="${post.id}">
                            <i class="fa-solid fa-trash-can"></i> ลบโพสต์
                        </button>
                    </div>
                </div>
                <div class="post-content">${escapeHTML(post.content)}</div>
                ${mediaHtml}
                <div class="post-footer">
                    <div class="post-stats">
                        <div class="post-stat-btn"><i class="fa-solid fa-heart text-danger"></i> ${post.likes_count}</div>
                        <div class="post-stat-btn"><i class="fa-solid fa-thumbs-down text-secondary"></i> ${post.dislikes_count}</div>
                        <button class="post-stat-btn btn-comments-collapse-toggle" data-id="${post.id}">
                            <i class="fa-solid fa-comment-dots text-primary"></i> <span id="label-count-comment-${post.id}">${commentsCount}</span> ความคิดเห็น
                        </button>
                    </div>
                </div>

                <!-- Comments section -->
                <div class="comments-list-section" id="comments-section-${post.id}">
                    <div class="comments-loader py-3 text-center" style="display:none;">กำลังโหลดคอมเมนต์...</div>
                    <div class="comments-inner-container" id="comments-container-${post.id}"></div>
                </div>
            `;
            container.appendChild(card);
        });

        // Set action triggers on posts
        container.querySelectorAll('.btn-author-profile-open').forEach(btn => {
            btn.addEventListener('click', (e) => {
                const id = e.currentTarget.getAttribute('data-author-id');
                showProfileDetailsModal(id);
            });
        });

        container.querySelectorAll('.btn-toggle-publish-post').forEach(btn => {
            btn.addEventListener('click', async (e) => {
                const id = e.currentTarget.getAttribute('data-id');
                const isPublished = e.currentTarget.getAttribute('data-published') === 'true';
                await togglePublishPost(id, isPublished);
            });
        });

        container.querySelectorAll('.btn-delete-post').forEach(btn => {
            btn.addEventListener('click', async (e) => {
                const id = e.currentTarget.getAttribute('data-id');
                await deletePost(id);
            });
        });

        container.querySelectorAll('.btn-comments-collapse-toggle').forEach(btn => {
            btn.addEventListener('click', async (e) => {
                const id = e.currentTarget.getAttribute('data-id');
                await toggleCommentsSection(id);
            });
        });

    } catch (err) {
        console.error('Error fetching feed posts:', err);
        container.innerHTML = `<div class="text-danger text-center py-5">เกิดข้อผิดพลาดในการโหลดข้อมูลโพสต์ฟีด: ${err.message}</div>`;
    }
}

async function togglePublishPost(postId, isCurrentlyPublished) {
    try {
        const { error } = await supabaseClient
            .from('posts')
            .update({ is_published: !isCurrentlyPublished })
            .eq('id', postId);

        if (error) throw error;

        showToast(isCurrentlyPublished ? 'ซ่อนโพสต์ไม่ให้แสดงผลบนแอปแล้ว' : 'เผยแพร่โพสต์บนแอปแล้ว', 'success');
        await fetchPosts();
    } catch (err) {
        showToast('ดำเนินการล้มเหลว: ' + err.message, 'danger');
    }
}

async function deletePost(postId) {
    if (confirm('คุณต้องการลบโพสต์ฟีดนี้และรูปประกอบทั้งหมดใช่หรือไม่? (การลบจะลบคอมเมนต์ประกอบด้วย)')) {
        try {
            const { error } = await supabaseClient
                .from('posts')
                .delete()
                .eq('id', postId);

            if (error) throw error;

            showToast('ลบโพสต์ฟีดเรียบร้อย', 'success');
            await fetchPosts();
        } catch (err) {
            console.error('Error deleting post:', err);
            showToast('ลบโพสต์ล้มเหลว: ' + err.message, 'danger');
        }
    }
}

async function toggleCommentsSection(postId) {
    const sec = document.getElementById(`comments-section-${postId}`);
    
    // Toggle active display class
    sec.classList.toggle('active');

    if (sec.classList.contains('active')) {
        await loadPostComments(postId);
    }
}

async function loadPostComments(postId) {
    const loader = document.querySelector(`#comments-section-${postId} .comments-loader`);
    const inner = document.getElementById(`comments-container-${postId}`);

    loader.style.display = 'block';
    inner.innerHTML = '';

    try {
        // Query comments and join commenter profile
        const { data: comments, error } = await supabaseClient
            .from('post_comments')
            .select('*, author:profiles!author_id(display_name, profile_photos(public_url))')
            .eq('post_id', postId)
            .order('created_at', { ascending: true });

        if (error) throw error;

        loader.style.display = 'none';

        if (comments.length === 0) {
            inner.innerHTML = `<div class="text-center py-2 text-secondary" style="font-size:12.5px;">ไม่มีความคิดเห็นสำหรับโพสต์นี้</div>`;
            return;
        }

        // Render comments list
        comments.forEach(c => {
            let avatar = 'https://via.placeholder.com/150';
            if (c.author?.profile_photos && c.author.profile_photos.length > 0) {
                avatar = c.author.profile_photos[0].public_url || avatar;
            }

            const row = document.createElement('div');
            row.className = 'comment-row';
            row.id = `comment-row-${c.id}`;
            row.innerHTML = `
                <img src="${avatar}" class="comment-avatar" alt="Avatar">
                <div class="comment-content">
                    <span class="comment-author">${escapeHTML(c.author?.display_name || 'สมาชิกเก่า')}</span>
                    <p class="comment-text">${escapeHTML(c.content)}</p>
                    <span class="comment-date">${formatDate(c.created_at)}</span>
                </div>
                <button class="comment-delete-btn btn-delete-comment" data-id="${c.id}" data-post-id="${postId}">
                    <i class="fa-solid fa-trash-can"></i>
                </button>
            `;
            inner.appendChild(row);
        });

        // Set action triggers on comments delete
        inner.querySelectorAll('.btn-delete-comment').forEach(btn => {
            btn.addEventListener('click', async (e) => {
                const id = e.currentTarget.getAttribute('data-id');
                const pId = e.currentTarget.getAttribute('data-post-id');
                await deleteComment(id, pId);
            });
        });

        // Update comment counter indicator in parent
        document.getElementById(`label-count-comment-${postId}`).innerText = comments.length;

    } catch (err) {
        console.error('Error loading comments:', err);
        loader.style.display = 'none';
        inner.innerHTML = `<div class="text-danger text-center py-2" style="font-size:12.5px;">ล้มเหลว: ${err.message}</div>`;
    }
}

async function deleteComment(commentId, postId) {
    if (confirm('คุณต้องการลบความคิดเห็นนี้ใช่หรือไม่?')) {
        try {
            const { error } = await supabaseClient
                .from('post_comments')
                .delete()
                .eq('id', commentId);

            if (error) throw error;

            showToast('ลบความคิดเห็นเรียบร้อย', 'success');
            // Refresh comments container
            await loadPostComments(postId);
        } catch (err) {
            console.error('Error deleting comment:', err);
            showToast('ลบคอมเมนต์ล้มเหลว: ' + err.message, 'danger');
        }
    }
}

// =============================================================================
// API - 5. Interests Tag Master List Operations
// =============================================================================

async function fetchInterests() {
    const container = document.getElementById('interests-container');
    container.innerHTML = '<div class="text-center py-3">กำลังโหลดข้อมูลแท็กความสนใจ...</div>';

    try {
        const { data: interests, error } = await supabaseClient
            .from('interests')
            .select('*')
            .order('name', { ascending: true });

        if (error) throw error;

        state.interestsCache = interests || [];
        container.innerHTML = '';
        if (interests.length === 0) {
            container.innerHTML = `<div class="text-secondary py-3">ยังไม่มีแท็กความสนใจในระบบ</div>`;
            return;
        }

        interests.forEach(item => {
            const tag = document.createElement('div');
            tag.className = 'interest-tag-card';
            tag.innerHTML = `
                <span># ${escapeHTML(item.name)}</span>
                <button class="btn-delete-tag btn-delete-interest-master" data-id="${item.id}"><i class="fa-solid fa-xmark"></i></button>
            `;
            container.appendChild(tag);
        });

        // Set delete triggers
        container.querySelectorAll('.btn-delete-interest-master').forEach(btn => {
            btn.addEventListener('click', async (e) => {
                const id = e.currentTarget.getAttribute('data-id');
                await deleteMasterInterest(id);
            });
        });
    } catch (err) {
        console.error('Error fetching master interests:', err);
        container.innerHTML = `<div class="text-danger py-3">เกิดข้อผิดพลาดในการโหลดแท็กความสนใจ: ${err.message}</div>`;
    }
}

async function handleAddMasterInterest(e) {
    e.preventDefault();
    const input = document.getElementById('input-new-interest');
    const name = input.value.trim();
    if (!name) return;

    try {
        const nameNormalized = name.toLowerCase();
        const { error } = await supabaseClient
            .from('interests')
            .insert({
                name: name,
                name_normalized: nameNormalized
            });

        if (error) throw error;

        showToast('เพิ่มแท็กความสนใจหลักสำเร็จ', 'success');
        input.value = '';
        await fetchInterests();
    } catch (err) {
        console.error('Error adding master interest:', err);
        showToast('ล้มเหลว (ชื่อแท็กอาจซ้ำกัน): ' + err.message, 'danger');
    }
}

async function deleteMasterInterest(interestId) {
    if (confirm('คำเตือน! คุณต้องการลบแท็กความสนใจนี้ออกจากระบบใช่หรือไม่?\n\nข้อมูลสมาชิกที่เลือกความสนใจแท็กนี้ทั้งหมดจะถูกเชื่อมโยงลบออกแบบถาวร!')) {
        try {
            const { error } = await supabaseClient
                .from('interests')
                .delete()
                .eq('id', interestId);

            if (error) throw error;

            showToast('ลบแท็กความสนใจสำเร็จ', 'success');
            await fetchInterests();
        } catch (err) {
            console.error('Error deleting master interest:', err);
            showToast('ลบแท็กความสนใจล้มเหลว: ' + err.message, 'danger');
        }
    }
}

// =============================================================================
// API - 6. Game Settlements (Mini-Game Integration)
// =============================================================================

async function fetchSettlements() {
    const tbody = document.querySelector('#table-settlements tbody');
    tbody.innerHTML = `<tr><td colspan="8" class="text-center">กำลังโหลดข้อมูลนิคมเมือง...</td></tr>`;

    try {
        // Query settlements (from game schema client)
        let query = supabaseGameClient.from('settlements').select('*');
        
        if (state.settlementsSearch) {
            query = query.ilike('name', `%${state.settlementsSearch}%`);
        }

        const { data: settlements, error: sErr } = await query.order('name', { ascending: true });

        if (sErr) throw sErr;

        // Fetch display names of all profiles to link owners in JS
        const { data: profiles, error: pErr } = await supabaseClient
            .from('profiles')
            .select('id, display_name');

        if (pErr) throw pErr;

        // Map profiles for JS-side joining
        const profileMap = {};
        profiles.forEach(p => {
            profileMap[p.id] = p.display_name;
        });

        state.settlementsCache = settlements || [];
        tbody.innerHTML = '';
        if (settlements.length === 0) {
            tbody.innerHTML = `<tr><td colspan="8" class="text-center">ไม่พบนิคมเมืองในระบบ</td></tr>`;
            return;
        }

        settlements.forEach(s => {
            const ownerName = profileMap[s.player_id] || 'ไม่พบข้อมูลผู้ใช้';
            
            const tr = document.createElement('tr');
            tr.innerHTML = `
                <td>
                    <strong>${escapeHTML(ownerName)}</strong>
                    <div class="id-hint">${s.player_id}</div>
                </td>
                <td><strong>🏰 ${escapeHTML(s.name)}</strong></td>
                <td><span class="badge badge-primary">X:${s.map_x} Y:${s.map_y}</span></td>
                <td><strong>${s.wood}</strong></td>
                <td><strong>${s.iron}</strong></td>
                <td><strong>${s.rice}</strong></td>
                <td><strong>${s.liquor}</strong></td>
                <td>
                    <button class="btn btn-secondary btn-sm btn-cheat-settlement" data-id="${s.id}"><i class="fa-solid fa-gear"></i> ปรับทรัพยากร</button>
                </td>
            `;
            tbody.appendChild(tr);
        });

        // Set action triggers
        tbody.querySelectorAll('.btn-cheat-settlement').forEach(btn => {
            btn.addEventListener('click', (e) => {
                const id = e.currentTarget.getAttribute('data-id');
                openCheatResourcesModal(id);
            });
        });

    } catch (err) {
        console.error('Error fetching settlements:', err);
        tbody.innerHTML = `<tr><td colspan="8" class="text-center text-danger">เกิดข้อผิดพลาดในการโหลด: ${err.message}</td></tr>`;
    }
}

function openCheatResourcesModal(settlementId) {
    state.selectedSettlementId = settlementId;
    const s = state.settlementsCache.find(x => x.id === settlementId);
    if (!s) return;

    document.getElementById('cheat-settlement-id').value = s.id;
    document.getElementById('cheat-settlement-title').innerText = s.name;
    document.getElementById('cheat-settlement-name').value = s.name;
    document.getElementById('cheat-wood').value = s.wood;
    document.getElementById('cheat-iron').value = s.iron;
    document.getElementById('cheat-rice').value = s.rice;
    document.getElementById('cheat-liquor').value = s.liquor;

    openModal('modal-cheat-resources');
}

async function handleSaveCheatResources() {
    const id = document.getElementById('cheat-settlement-id').value;
    const name = document.getElementById('cheat-settlement-name').value.trim();
    const wood = parseInt(document.getElementById('cheat-wood').value) || 0;
    const iron = parseInt(document.getElementById('cheat-iron').value) || 0;
    const rice = parseInt(document.getElementById('cheat-rice').value) || 0;
    const liquor = parseInt(document.getElementById('cheat-liquor').value) || 0;

    if (!id || !name) return;

    try {
        const updates = {
            name: name,
            wood: wood,
            iron: iron,
            rice: rice,
            liquor: liquor,
            updated_at: new Date().toISOString()
        };

        const { error } = await supabaseGameClient
            .from('settlements')
            .update(updates)
            .eq('id', id);

        if (error) throw error;

        showToast('แก้ไขข้อมูลทรัพยากรนิคมสำเร็จ', 'success');
        closeModal('modal-cheat-resources');
        
        // Refresh settlements list & profiles modal if opened
        await fetchSettlements();
        if (state.selectedProfileId) {
            await fetchProfileGameInfo(state.selectedProfileId);
        }
    } catch (err) {
        console.error('Error saving settlement resource cheat:', err);
        showToast('ปรับปรุงทรัพยากรล้มเหลว: ' + err.message, 'danger');
    }
}

// =============================================================================
// Helper Utilities & Modal Controller Functions
// =============================================================================

function openModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
        modal.classList.add('active');
        document.body.style.overflow = 'hidden'; // Lock background scrolling
    }
}

function closeModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
        modal.classList.remove('active');
        document.body.style.overflow = ''; // Unlock background scrolling
    }
}

function showToast(message, type = 'info') {
    const container = document.getElementById('toast-container');
    if (!container) return;

    // Toast Card Element
    const toast = document.createElement('div');
    toast.className = `toast toast-${type}`;
    
    // Choose icon depending on type
    const icons = {
        success: 'fa-solid fa-circle-check',
        danger: 'fa-solid fa-circle-xmark',
        warning: 'fa-solid fa-circle-exclamation',
        info: 'fa-solid fa-circle-info'
    };
    
    toast.innerHTML = `
        <i class="toast-icon ${icons[type]}"></i>
        <div class="toast-message">${escapeHTML(message)}</div>
    `;

    container.appendChild(toast);

    // Auto-remove toast after 4 seconds
    setTimeout(() => {
        toast.classList.add('removing');
        toast.addEventListener('animationend', () => {
            toast.remove();
        });
    }, 4000);
}

// String escaping helper to prevent XSS
function escapeHTML(str) {
    if (!str) return '';
    return str
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#039;');
}

// Calculate Member's age from birthdate string
function calculateAge(birthDateString) {
    if (!birthDateString) return '-';
    const birthDate = new Date(birthDateString);
    const today = new Date();
    let age = today.getFullYear() - birthDate.getFullYear();
    const m = today.getMonth() - birthDate.getMonth();
    if (m < 0 || (m === 0 && today.getDate() < birthDate.getDate())) {
        age--;
    }
    return age;
}

// Format database TIMESTAMPTZ into readable Thai format
function formatDate(dateString) {
    if (!dateString) return '-';
    const d = new Date(dateString);
    return d.toLocaleDateString('th-TH', { 
        year: 'numeric', 
        month: 'short', 
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    });
}

function translateGender(gender) {
    const mapping = {
        male: 'ชาย',
        female: 'หญิง',
        other: 'อื่นๆ'
    };
    return mapping[gender] || gender || '-';
}

function translateReportStatus(status) {
    const mapping = {
        pending: 'รอดำเนินการ',
        reviewed: 'กำลังตรวจสอบ',
        resolved: 'เสร็จสิ้นการแก้ไข',
        dismissed: 'ยกเลิกคำร้อง'
    };
    return mapping[status] || status || '-';
}

function getReportBadgeColor(status) {
    const mapping = {
        pending: 'danger',
        reviewed: 'warning',
        resolved: 'success',
        dismissed: 'info'
    };
    return mapping[status] || 'secondary';
}
