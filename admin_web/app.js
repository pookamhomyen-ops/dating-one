// Supabase Credentials
const SUPABASE_URL = 'https://kjvfvttvdnjpomchwaoi.supabase.co/rest/v1';
const ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtqdmZ2dHR2ZG5qcG9tY2h3YW9pIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk4MDA0MDQsImV4cCI6MjA5NTM3NjQwNH0.1_euqabF7oiUH3S2uVwaT2PCgK8iLuFGGbSVhYuDwnc';

// Headers helper
function getHeaders(schema = 'game') {
    return {
        'apikey': ANON_KEY,
        'Authorization': `Bearer ${ANON_KEY}`,
        'Content-Type': 'application/json',
        'Accept-Profile': schema,
        'Content-Profile': schema,
        'Prefer': 'return=representation'
    };
}

// App State
let appData = {
    configs: {
        buildings: {},
        troops: {},
        resources: {}
    },
    players: [],
    settlements: [],
    quests: [],
    activeModalSettlementId: null,
    activeModalTab: 'buildings'
};

// UI Elements & Tab Navigation
document.addEventListener('DOMContentLoaded', () => {
    initApp();
    setupEventListeners();
});

async function initApp() {
    showToast('Loading database configurations...', 'info');
    await fetchConfigs();
    await refreshDashboardData();
}

// ค้นหาฟังก์ชัน setupEventListeners() ในไฟล์ app.js เดิมของคุณ แล้วนำโค้ดนี้ไปแทนที่/อัปเดตเข้าไปครับ

function setupEventListeners() {
    // === ส่วนที่แก้ไขและเพิ่มเติม: ระบบเปลี่ยนภาษา ===
    const btnToggleLang = document.getElementById('btn-toggle-lang');
    if (btnToggleLang) {
        btnToggleLang.addEventListener('click', () => {
            const currentLang = btnToggleLang.getAttribute('data-current');
            const nextLang = currentLang === 'en' ? 'th' : 'en';
            setLanguage(nextLang);
        });
        
        // โหลดภาษาล่าสุดที่เคยบันทึกไว้ในเบราว์เซอร์ (ถ้ามี)
        const savedLang = localStorage.getItem('love_empire_lang') || 'en';
        setLanguage(savedLang);
    }

    // Navigation Tabs
    const navItems = document.querySelectorAll('.nav-item');
    navItems.forEach(item => {
        item.addEventListener('click', (e) => {
            const btn = e.currentTarget;
            const tabName = btn.getAttribute('data-tab');
            
            // Toggle active classes
            document.querySelectorAll('.nav-item').forEach(i => i.classList.remove('active'));
            document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
            
            btn.classList.add('active');
            document.getElementById(`tab-${tabName}`).classList.add('active');
            
            // แก้ไขส่วนนี้ให้ดึงข้อมูลชุดคู่ภาษา (TH/EN) มาใช้งานแทนเพื่อรองรับ Dynamic Tab Switch
            const titles = {
                dashboard: {
                    th: ['แดชบอร์ด & เครื่องมือทดสอบ', 'สร้างผู้เล่นจำลอง, แก้ไขทรัพยากร และรันคำสั่งทดสอบด่วน'],
                    en: ['Dashboard & Test tools', 'Generate mock players, edit resources, and run quick testing actions.']
                },
                buildings: {
                    th: ['อัปเกรดสิ่งปลูกสร้าง', 'จัดการเวลา, ต้นทุน และการคำนวณการผลิตสำหรับสิ่งปลูกสร้างทุกประเภท'],
                    en: ['Building Upgrades', 'Manage times, costs, and production calculations for all building types.']
                },
                troops: {
                    th: ['ฝึกฝนทหาร', 'จัดการเวลาสรรหาทหาร, ต้นทุนต่อยูนิต และสถิติการต่อสู้'],
                    en: ['Troop Training', 'Manage recruitment times, unit costs, and combat statistics.']
                },
                resources: {
                    th: ['ตั้งค่าทรัพยากร', 'จัดการระยะเวลาของติ๊กทรัพยากร และเวลาสะสมสูงสุดขณะออฟไลน์'],
                    en: ['Resource Configs', 'Manage resource tick duration and maximum idle accumulation time.']
                },
                players: {
                    th: ['ผู้เล่น & นิคม', 'ตรวจสอบนิคมของผู้เล่น, เร่งการทำงานให้เสร็จทันที และปรับเปลี่ยนระดับทรัพยากร'],
                    en: ['Player & Settlements', 'Inspect player settlements, instantly finish actions, and adjust resource levels.']
                },
                quests: {
                    th: ['เควสต์ & ฤดูกาล', 'จัดการเควสต์เกม, ของรางวัล และการตั้งค่าสภาพอากาศ/ฤดูกาลที่ใช้งานอยู่'],
                    en: ['Quests & Seasons', 'Manage game quests, rewards, and the active weather/season setting.']
                }
            };
            
            const currentLang = document.getElementById('btn-toggle-lang').getAttribute('data-current') || 'en';
            const headerTitleEl = document.getElementById('current-tab-title');
            const headerDescEl = document.getElementById('current-tab-desc');
            
            // เก็บค่าคู่ภาษาไว้ใน element เผื่อผู้ใช้กดเปลี่ยนภาษาขณะอยู่แท็บอื่นๆ
            headerTitleEl.setAttribute('data-th', titles[tabName]['th'][0]);
            headerTitleEl.setAttribute('data-en', titles[tabName]['en'][0]);
            headerDescEl.setAttribute('data-th', titles[tabName]['th'][1]);
            headerDescEl.setAttribute('data-en', titles[tabName]['en'][1]);
            
            headerTitleEl.innerText = titles[tabName][currentLang][0];
            document.getElementById('current-tab-desc').innerText = titles[tabName][currentLang][1];
        });
    });

    // Refresh Button
    document.getElementById('btn-refresh-data').addEventListener('click', () => {
        refreshDashboardData();
    });

    // Generate Mock Player Button
    document.getElementById('btn-generate-mock').addEventListener('click', generateMockPlayer);

    // Cheat Buttons
    document.getElementById('btn-cheat-resources').addEventListener('click', cheatAddResources);
    document.getElementById('btn-cheat-complete-upgrades').addEventListener('click', cheatCompleteAllUpgrades);
    document.getElementById('btn-cheat-complete-training').addEventListener('click', cheatCompleteAllTraining);
    document.getElementById('btn-cheat-clear-data').addEventListener('click', cheatClearAllTestData);

    // Config Save Buttons
    document.getElementById('btn-save-buildings').addEventListener('click', saveBuildingsConfig);
    document.getElementById('btn-save-troops').addEventListener('click', saveTroopsConfig);
    document.getElementById('btn-save-resources').addEventListener('click', saveResourcesConfig);

    // Settlement update modal
    document.getElementById('btn-update-settlement').addEventListener('click', updateSettlementData);

    // Season update
    document.getElementById('btn-save-season').addEventListener('click', updateSeasonData);
}

// === ฟังก์ชันสำหรับสลับภาษาโกลบอล ===
function setLanguage(lang) {
    const btnToggleLang = document.getElementById('btn-toggle-lang');
    const langLabel = document.getElementById('lang-label');
    
    btnToggleLang.setAttribute('data-current', lang);
    langLabel.innerText = lang === 'en' ? 'TH' : 'EN'; // แสดงผลภาษาถัดไปที่จะเปลี่ยนเป็นตัวใบ้
    localStorage.setItem('love_empire_lang', lang);
    
    // ค้นหา Elements ทั้งหมดที่มี Attributes รองรับสองภาษา
    const elements = document.querySelectorAll('[data-th][data-en]');
    elements.forEach(el => {
        if (lang === 'th') {
            el.innerText = el.getAttribute('data-th');
        } else {
            el.innerText = el.getAttribute('data-en');
        }
    });
}

// ==========================================
// API Operations
// ==========================================

async function fetchConfigs() {
    try {
        const res = await fetch(`${SUPABASE_URL}/game_configs?select=*`, {
            headers: getHeaders()
        });
        if (!res.ok) throw new Error('Failed to load configs');
        const data = await res.json();
        
        data.forEach(item => {
            appData.configs[item.key] = item.value;
        });

        populateBuildingsTable();
        populateTroopsTable();
        populateResourcesForm();
    } catch (err) {
        console.error(err);
        showToast('Error loading configs: ' + err.message, 'danger');
    }
}

async function refreshDashboardData() {
    try {
        // Fetch settlements
        const resSet = await fetch(`${SUPABASE_URL}/settlements?select=*`, {
            headers: getHeaders()
        });
        if (!resSet.ok) throw new Error('Failed to load settlements');
        appData.settlements = await resSet.json();

        // Fetch players (profiles from public schema)
        const resPl = await fetch(`${SUPABASE_URL}/profiles?select=id,display_name`, {
            headers: getHeaders('public')
        });
        appData.players = await resPl.json();

        // Fetch quests
        const resQu = await fetch(`${SUPABASE_URL}/quests?select=*`, {
            headers: getHeaders()
        });
        appData.quests = await resQu.json();

        // Fetch active upgrading buildings count
        const resBld = await fetch(`${SUPABASE_URL}/buildings?is_upgrading=eq.true&select=id`, {
            headers: getHeaders(),
            method: 'GET'
        });
        const upgrading = await resBld.json();

        // Fetch active training troops
        const resTrp = await fetch(`${SUPABASE_URL}/troops?training_count=gt.0&select=id`, {
            headers: getHeaders()
        });
        const training = await resTrp.json();

        // Update Stats
        document.getElementById('stat-players').innerText = appData.players.length;
        document.getElementById('stat-settlements').innerText = appData.settlements.length;
        document.getElementById('stat-upgrades').innerText = upgrading ? upgrading.length : 0;
        document.getElementById('stat-training').innerText = training ? training.length : 0;

        // Populate tables
        populateSettlementsTable();
        populateQuestsTable();
        await fetchSeason();
        showToast('Dashboard data refreshed successfully!', 'success');
    } catch (err) {
        console.error(err);
        showToast('Error refreshing data: ' + err.message, 'danger');
    }
}

// Fetch current season
async function fetchSeason() {
    try {
        const res = await fetch(`${SUPABASE_URL}/season?id=eq.1&select=*`, {
            headers: getHeaders()
        });
        const seasonData = await res.json();
        if (seasonData && seasonData.length > 0) {
            document.getElementById('current-season').value = seasonData[0].current_season;
        }
    } catch (err) {
        console.error(err);
    }
}

// ==========================================
// Config Populations & Saves
// ==========================================

function populateBuildingsTable() {
    const tbody = document.querySelector('#buildings-config-table tbody');
    tbody.innerHTML = '';
    const bConfigs = appData.configs.buildings;
    
    Object.keys(bConfigs).forEach(type => {
        const item = bConfigs[type];
        const tr = document.createElement('tr');
        tr.innerHTML = `
            <td><strong>${type}</strong></td>
            <td><input type="number" class="form-control text-center" style="width:100px;" value="${item.base_seconds}" data-type="${type}" data-field="base_seconds"></td>
            <td><span class="badge badge-info">Multiplier = Level</span></td>
            <td><input type="number" class="form-control text-center" style="width:100px;" value="${item.base_cost?.wood || 0}" data-type="${type}" data-field="wood"></td>
            <td><input type="number" class="form-control text-center" style="width:100px;" value="${item.base_cost?.iron || 0}" data-type="${type}" data-field="iron"></td>
            <td><input type="number" class="form-control text-center" style="width:100px;" value="${item.base_prod_tick ? Object.values(item.base_prod_tick)[0] || 0 : 0}" data-type="${type}" data-field="base_prod"></td>
            <td><input type="number" class="form-control text-center" style="width:100px;" value="${item.prod_tick_per_level ? Object.values(item.prod_tick_per_level)[0] || 0 : 0}" data-type="${type}" data-field="lvl_prod"></td>
        `;
        tbody.appendChild(tr);
    });
}

async function saveBuildingsConfig() {
    try {
        const inputs = document.querySelectorAll('#buildings-config-table input');
        const bConfigs = JSON.parse(JSON.stringify(appData.configs.buildings)); // Deep copy

        inputs.forEach(input => {
            const type = input.getAttribute('data-type');
            const field = input.getAttribute('data-field');
            const val = parseInt(input.value) || 0;

            if (field === 'base_seconds') {
                bConfigs[type].base_seconds = val;
            } else if (field === 'wood' || field === 'iron') {
                if (!bConfigs[type].base_cost) bConfigs[type].base_cost = {};
                bConfigs[type].base_cost[field] = val;
            } else if (field === 'base_prod' || field === 'lvl_prod') {
                // Find resource name
                let resName = 'wood';
                if (type === 'sawmill') resName = 'wood';
                else if (type === 'smelter') resName = 'iron';
                else if (type === 'rice_farm') resName = 'rice';
                else if (type === 'distillery') resName = 'liquor';
                
                if (type === 'sawmill' || type === 'smelter' || type === 'rice_farm' || type === 'distillery') {
                    if (field === 'base_prod') {
                        bConfigs[type].base_prod_tick = {};
                        bConfigs[type].base_prod_tick[resName] = val;
                    } else {
                        bConfigs[type].prod_tick_per_level = {};
                        bConfigs[type].prod_tick_per_level[resName] = val;
                    }
                }
            }
        });

        const res = await fetch(`${SUPABASE_URL}/game_configs?key=eq.buildings`, {
            method: 'PATCH',
            headers: getHeaders(),
            body: JSON.stringify({ value: bConfigs, updated_at: new Date().toISOString() })
        });

        if (!res.ok) throw new Error('Save failed');
        appData.configs.buildings = bConfigs;
        showToast('Buildings configuration saved successfully!', 'success');
    } catch (err) {
        showToast('Error saving buildings configuration: ' + err.message, 'danger');
    }
}

function populateTroopsTable() {
    const tbody = document.querySelector('#troops-config-table tbody');
    tbody.innerHTML = '';
    const tConfigs = appData.configs.troops;

    Object.keys(tConfigs).forEach(type => {
        const item = tConfigs[type];
        const tr = document.createElement('tr');
        tr.innerHTML = `
            <td><strong>${type}</strong></td>
            <td><input type="number" class="form-control text-center" style="width:120px;" value="${item.training_seconds}" data-type="${type}" data-field="training_seconds"></td>
            <td><input type="number" class="form-control text-center" style="width:100px;" value="${item.cost_per_unit?.wood || 0}" data-type="${type}" data-field="wood"></td>
            <td><input type="number" class="form-control text-center" style="width:100px;" value="${item.cost_per_unit?.iron || 0}" data-type="${type}" data-field="iron"></td>
            <td><input type="number" class="form-control text-center" style="width:100px;" value="${item.attack || 0}" data-type="${type}" data-field="attack"></td>
            <td><input type="number" class="form-control text-center" style="width:100px;" value="${item.defense || 0}" data-type="${type}" data-field="defense"></td>
        `;
        tbody.appendChild(tr);
    });
}

async function saveTroopsConfig() {
    try {
        const inputs = document.querySelectorAll('#troops-config-table input');
        const tConfigs = JSON.parse(JSON.stringify(appData.configs.troops));

        inputs.forEach(input => {
            const type = input.getAttribute('data-type');
            const field = input.getAttribute('data-field');
            const val = parseInt(input.value) || 0;

            if (field === 'training_seconds') {
                tConfigs[type].training_seconds = val;
            } else if (field === 'wood' || field === 'iron') {
                if (!tConfigs[type].cost_per_unit) tConfigs[type].cost_per_unit = {};
                tConfigs[type].cost_per_unit[field] = val;
            } else if (field === 'attack' || field === 'defense') {
                tConfigs[type][field] = val;
            }
        });

        const res = await fetch(`${SUPABASE_URL}/game_configs?key=eq.troops`, {
            method: 'PATCH',
            headers: getHeaders(),
            body: JSON.stringify({ value: tConfigs, updated_at: new Date().toISOString() })
        });

        if (!res.ok) throw new Error('Save failed');
        appData.configs.troops = tConfigs;
        showToast('Troops configuration saved successfully!', 'success');
    } catch (err) {
        showToast('Error saving troops configuration: ' + err.message, 'danger');
    }
}

function populateResourcesForm() {
    const resConfig = appData.configs.resources;
    if (resConfig) {
        document.getElementById('config-tick-duration').value = resConfig.tick_duration_minutes || 5;
        document.getElementById('config-offline-cap').value = (resConfig.offline_cap_minutes || 480) / 60;
    }
}

async function saveResourcesConfig() {
    try {
        const ticks = parseInt(document.getElementById('config-tick-duration').value) || 5;
        const capHours = parseInt(document.getElementById('config-offline-cap').value) || 8;
        const resConfig = {
            tick_duration_minutes: ticks,
            offline_cap_minutes: capHours * 60
        };

        const res = await fetch(`${SUPABASE_URL}/game_configs?key=eq.resources`, {
            method: 'PATCH',
            headers: getHeaders(),
            body: JSON.stringify({ value: resConfig, updated_at: new Date().toISOString() })
        });

        if (!res.ok) throw new Error('Save failed');
        appData.configs.resources = resConfig;
        showToast('Global resource configuration saved!', 'success');
    } catch (err) {
        showToast('Error saving resource configurations: ' + err.message, 'danger');
    }
}

// ==========================================
// Settlement Manage operations
// ==========================================

function populateSettlementsTable() {
    const tbody = document.querySelector('#settlements-table tbody');
    tbody.innerHTML = '';
    
    if (appData.settlements.length === 0) {
        tbody.innerHTML = `<tr><td colspan="5" class="text-center">No settlements found. Generate test player on Dashboard.</td></tr>`;
        return;
    }

    appData.settlements.forEach(settlement => {
        // Find player name
        const player = appData.players.find(p => p.id === settlement.player_id);
        const playerName = player ? player.display_name : 'Unknown Player';
        
        const tr = document.createElement('tr');
        tr.innerHTML = `
            <td><strong>${playerName}</strong><br><small class="text-muted">${settlement.player_id.substring(0, 8)}...</small></td>
            <td><strong>${settlement.name}</strong></td>
            <td>${settlement.map_x}, ${settlement.map_y}</td>
            <td>
                <span class="badge badge-success"><i class="fa-solid fa-tree"></i> W: ${settlement.wood}</span>
                <span class="badge badge-info"><i class="fa-solid fa-cubes-stacked"></i> I: ${settlement.iron}</span>
                <span class="badge badge-warning"><i class="fa-solid fa-wheat-awn"></i> R: ${settlement.rice}</span>
                <span class="badge badge-danger"><i class="fa-solid fa-wine-bottle"></i> L: ${settlement.liquor}</span>
            </td>
            <td>
                <button class="btn btn-secondary btn-sm" onclick="openDetailsModal('${settlement.id}')">
                    <i class="fa-solid fa-eye"></i> Buildings/Troops
                </button>
                <button class="btn btn-primary btn-sm" onclick="openEditSettlementModal('${settlement.id}')">
                    <i class="fa-solid fa-pencil"></i> Resources
                </button>
            </td>
        `;
        tbody.appendChild(tr);
    });
}

// Edit Settlement Resources Modal operations
function openEditSettlementModal(settlementId) {
    const settlement = appData.settlements.find(s => s.id === settlementId);
    if (!settlement) return;

    document.getElementById('edit-settlement-id').value = settlement.id;
    document.getElementById('edit-settlement-name').value = settlement.name;
    document.getElementById('edit-wood').value = settlement.wood;
    document.getElementById('edit-iron').value = settlement.iron;
    document.getElementById('edit-rice').value = settlement.rice;
    document.getElementById('edit-liquor').value = settlement.liquor;

    document.getElementById('edit-settlement-modal').classList.add('active');
}

function closeSettlementModal() {
    document.getElementById('edit-settlement-modal').classList.remove('active');
}

async function updateSettlementData() {
    const id = document.getElementById('edit-settlement-id').value;
    const name = document.getElementById('edit-settlement-name').value;
    const wood = parseInt(document.getElementById('edit-wood').value) || 0;
    const iron = parseInt(document.getElementById('edit-iron').value) || 0;
    const rice = parseInt(document.getElementById('edit-rice').value) || 0;
    const liquor = parseInt(document.getElementById('edit-liquor').value) || 0;

    try {
        const res = await fetch(`${SUPABASE_URL}/settlements?id=eq.${id}`, {
            method: 'PATCH',
            headers: getHeaders(),
            body: JSON.stringify({ name, wood, iron, rice, liquor })
        });
        if (!res.ok) throw new Error('Update resources failed');
        closeSettlementModal();
        refreshDashboardData();
        showToast('Settlement resources updated successfully!', 'success');
    } catch (err) {
        showToast('Error updating resources: ' + err.message, 'danger');
    }
}

// Details Modal (Buildings & Troops list)
async function openDetailsModal(settlementId) {
    appData.activeModalSettlementId = settlementId;
    const settlement = appData.settlements.find(s => s.id === settlementId);
    document.getElementById('details-modal-title').innerText = `${settlement.name} — Detailed State`;
    
    document.getElementById('details-modal').classList.add('active');
    showModalTab('buildings');
}

function closeDetailsModal() {
    document.getElementById('details-modal').classList.remove('active');
}

function showModalTab(tabName) {
    appData.activeModalTab = tabName;
    document.getElementById('btn-modal-buildings').className = tabName === 'buildings' ? 'modal-tabactive' : 'modal-tab';
    document.getElementById('btn-modal-troops').className = tabName === 'troops' ? 'modal-tabactive' : 'modal-tab';
    
    document.getElementById('modal-tab-buildings-view').style.display = tabName === 'buildings' ? 'block' : 'none';
    document.getElementById('modal-tab-troops-view').style.display = tabName === 'troops' ? 'block' : 'none';
    
    if (tabName === 'buildings') {
        loadSettlementBuildings();
    } else {
        loadSettlementTroops();
    }
}

async function loadSettlementBuildings() {
    const listBody = document.getElementById('settlement-buildings-list');
    listBody.innerHTML = '<tr><td colspan="4" class="text-center">Loading buildings...</td></tr>';
    
    try {
        const res = await fetch(`${SUPABASE_URL}/buildings?settlement_id=eq.${appData.activeModalSettlementId}&select=*`, {
            headers: getHeaders()
        });
        const buildings = await res.json();
        listBody.innerHTML = '';
        
        if (buildings.length === 0) {
            listBody.innerHTML = '<tr><td colspan="4" class="text-center">No buildings found.</td></tr>';
            return;
        }

        buildings.forEach(building => {
            const displayName = getBuildingDisplayName(building.building_type);
            let status = `<span class="badge badge-success">Idle</span>`;
            let actions = '';
            
            if (building.is_upgrading) {
                const finish = new Date(building.upgrade_finish_at);
                const remainingSecs = Math.max(0, Math.floor((finish - new Date()) / 1000));
                
                status = `<span class="badge badge-warning">Upgrading (Lvl ${building.level} ➜ ${building.level + 1})</span><br><small class="text-muted">${remainingSecs}s left</small>`;
                actions = `<button class="btn btn-warning btn-sm" onclick="completeBuildingUpgrade('${building.id}', ${building.level})">Instant Finish</button>`;
            } else {
                actions = `<button class="btn btn-secondary btn-sm" onclick="triggerUpgrade('${building.id}', ${building.level})">Upgrade Lvl</button>`;
            }

            const tr = document.createElement('tr');
            tr.innerHTML = `
                <td><strong>${displayName}</strong><br><small class="text-muted">${building.building_type}</small></td>
                <td>Level ${building.level}</td>
                <td>${status}</td>
                <td>
                    ${actions}
                    <button class="btn btn-secondary btn-sm" onclick="editBuildingLevel('${building.id}', ${building.level})">Set Level</button>
                </td>
            `;
            listBody.appendChild(tr);
        });
    } catch (err) {
        listBody.innerHTML = `<tr><td colspan="4" class="text-center text-danger">Error: ${err.message}</td></tr>`;
    }
}

async function triggerUpgrade(buildingId, currentLevel) {
    const finishAt = new Date(Date.now() + 60000).toISOString(); // 1 minute from now
    try {
        const res = await fetch(`${SUPABASE_URL}/buildings?id=eq.${buildingId}`, {
            method: 'PATCH',
            headers: getHeaders(),
            body: JSON.stringify({
                is_upgrading: true,
                upgrade_finish_at: finishAt
            })
        });
        if (!res.ok) throw new Error('Failed to start upgrade');
        loadSettlementBuildings();
        showToast('Upgrade started!', 'success');
    } catch (err) {
        showToast(err.message, 'danger');
    }
}

async function completeBuildingUpgrade(buildingId, currentLevel) {
    try {
        const res = await fetch(`${SUPABASE_URL}/buildings?id=eq.${buildingId}`, {
            method: 'PATCH',
            headers: getHeaders(),
            body: JSON.stringify({
                level: currentLevel + 1,
                is_upgrading: false,
                upgrade_finish_at: null
            })
        });
        if (!res.ok) throw new Error('Upgrade completion failed');
        loadSettlementBuildings();
        refreshDashboardData();
        showToast('Building upgrade completed instantly!', 'success');
    } catch (err) {
        showToast('Error completing upgrade: ' + err.message, 'danger');
    }
}

async function editBuildingLevel(buildingId, currentLevel) {
    const newLvlStr = prompt('Enter new building level (1-5):', currentLevel);
    const newLvl = parseInt(newLvlStr);
    if (isNaN(newLvl) || newLvl < 1 || newLvl > 10) return;

    try {
        const res = await fetch(`${SUPABASE_URL}/buildings?id=eq.${buildingId}`, {
            method: 'PATCH',
            headers: getHeaders(),
            body: JSON.stringify({
                level: newLvl,
                is_upgrading: false,
                upgrade_finish_at: null
            })
        });
        if (!res.ok) throw new Error('Failed to update level');
        loadSettlementBuildings();
        showToast('Building level updated!', 'success');
    } catch (err) {
        showToast(err.message, 'danger');
    }
}

async function loadSettlementTroops() {
    const listBody = document.getElementById('settlement-troops-list');
    listBody.innerHTML = '<tr><td colspan="4" class="text-center">Loading troops...</td></tr>';
    
    try {
        const res = await fetch(`${SUPABASE_URL}/troops?settlement_id=eq.${appData.activeModalSettlementId}&select=*`, {
            headers: getHeaders()
        });
        const troops = await res.json();
        listBody.innerHTML = '';
        
        if (troops.length === 0) {
            listBody.innerHTML = '<tr><td colspan="4" class="text-center">No troops slots found.</td></tr>';
            return;
        }

        troops.forEach(troop => {
            const displayName = getTroopDisplayName(troop.troop_type);
            let status = `<span class="badge badge-success">Idle</span>`;
            let actions = '';
            
            if (troop.training_count > 0 && troop.training_finish_at) {
                const finish = new Date(troop.training_finish_at);
                const remainingSecs = Math.max(0, Math.floor((finish - new Date()) / 1000));
                
                status = `<span class="badge badge-warning">Training +${troop.training_count}</span><br><small class="text-muted">${remainingSecs}s left</small>`;
                actions = `<button class="btn btn-warning btn-sm" onclick="completeTroopTraining('${troop.id}', ${troop.count}, ${troop.training_count})">Instant Finish</button>`;
            }

            const tr = document.createElement('tr');
            tr.innerHTML = `
                <td><strong>${displayName}</strong><br><small class="text-muted">${troop.troop_type}</small></td>
                <td>${troop.count} units</td>
                <td>${status}</td>
                <td>
                    ${actions}
                    <button class="btn btn-secondary btn-sm" onclick="editTroopCount('${troop.id}', ${troop.count})">Set Count</button>
                </td>
            `;
            listBody.appendChild(tr);
        });
    } catch (err) {
        listBody.innerHTML = `<tr><td colspan="4" class="text-center text-danger">Error: ${err.message}</td></tr>`;
    }
}

async function completeTroopTraining(troopId, currentCount, trainingCount) {
    try {
        const res = await fetch(`${SUPABASE_URL}/troops?id=eq.${troopId}`, {
            method: 'PATCH',
            headers: getHeaders(),
            body: JSON.stringify({
                count: currentCount + trainingCount,
                training_count: 0,
                training_finish_at: null
            })
        });
        if (!res.ok) throw new Error('Training completion failed');
        loadSettlementTroops();
        refreshDashboardData();
        showToast('Troop training finished instantly!', 'success');
    } catch (err) {
        showToast('Error completing training: ' + err.message, 'danger');
    }
}

async function editTroopCount(troopId, currentCount) {
    const newCountStr = prompt('Enter new troop count:', currentCount);
    const newCount = parseInt(newCountStr);
    if (isNaN(newCount) || newCount < 0) return;

    try {
        const res = await fetch(`${SUPABASE_URL}/troops?id=eq.${troopId}`, {
            method: 'PATCH',
            headers: getHeaders(),
            body: JSON.stringify({
                count: newCount,
                training_count: 0,
                training_finish_at: null
            })
        });
        if (!res.ok) throw new Error('Failed to set troop count');
        loadSettlementTroops();
        showToast('Troop count updated!', 'success');
    } catch (err) {
        showToast(err.message, 'danger');
    }
}

// Helpers for UI naming
function getBuildingDisplayName(type) {
    const names = {
        sawmill: 'โรงไม้ (Sawmill)',
        smelter: 'โรงหลอม (Smelter)',
        rice_farm: 'นาข้าว (Rice Farm)',
        distillery: 'โรงกลั่น (Distillery)',
        house: 'บ้านเรือน (House)',
        tavern: 'ร้านเหล้าตอง (Tavern)',
        shrine: 'ศาลเจ้า (Shrine)',
        barracks: 'ค่ายทหาร (Barracks)',
        elephant_camp: 'โรงช้าง (Elephant Camp)',
        smithy: 'โรงตีเหล็ก (Smithy)',
        wall: 'กำแพงเมือง (Wall)',
        watchtower: 'หอสังเกตการณ์ (Watchtower)',
        town_hall: 'ศาลากลาง (Town Hall)'
    };
    return names[type] || type;
}

function getTroopDisplayName(type) {
    const names = {
        swordsman: '🗡️ พลดาบ (Swordsman)',
        archer: '🏹 พลธนู (Archer)',
        spearman: '🪖 พลทวน (Spearman)',
        cavalry: '🐴 ทหารม้า (Cavalry)',
        elephant: '🐘 ช้างศึก (Elephant)'
    };
    return names[type] || type;
}

// ==========================================
// Mock Generator
// ==========================================

async function generateMockPlayer() {
    const name = document.getElementById('mock-player-name').value.trim() || `Test User ${Math.floor(Math.random() * 900 + 100)}`;
    const mapX = parseInt(document.getElementById('mock-map-x').value) || 25;
    const mapY = parseInt(document.getElementById('mock-map-y').value) || 40;

    showToast(`Generating test player '${name}'...`, 'info');
    try {
        // 1. Sign up user via Supabase Auth to automatically trigger public.profiles insertion
        const email = `test_${Date.now()}_${Math.floor(Math.random() * 1000)}@example.com`;
        const password = 'password123';
        
        const authUrl = SUPABASE_URL.replace('/rest/v1', '/auth/v1/signup');
        const resAuth = await fetch(authUrl, {
            method: 'POST',
            headers: {
                'apikey': ANON_KEY,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                email: email,
                password: password,
                data: {
                    display_name: name
                }
            })
        });
        
        if (!resAuth.ok) {
            const errDetail = await resAuth.json();
            throw new Error('Auth signup failed: ' + (errDetail.msg || errDetail.error_description || JSON.stringify(errDetail)));
        }
        
        const authData = await resAuth.json();
        const playerId = authData.id || (authData.user && authData.user.id);
        if (!playerId) throw new Error('Could not retrieve player ID from Auth Signup');

        // Optional: Trigger profile update just in case metadata display_name didn't trigger
        await fetch(`${SUPABASE_URL}/profiles?id=eq.${playerId}`, {
            method: 'PATCH',
            headers: getHeaders('public'),
            body: JSON.stringify({ display_name: name })
        });

        // 1.5 Insert Player into game.players (to satisfy settlements foreign key constraint)
        const resGamePlayer = await fetch(`${SUPABASE_URL}/players`, {
            method: 'POST',
            headers: getHeaders(),
            body: JSON.stringify({ id: playerId, display_name: name })
        });
        if (!resGamePlayer.ok) {
            const errDetail = await resGamePlayer.json().catch(() => ({}));
            throw new Error('game.players insertion failed: ' + (errDetail.message || JSON.stringify(errDetail)));
        }

        // 2. Insert Settlement
        const settlementId = generateUUID();
        const resSettlement = await fetch(`${SUPABASE_URL}/settlements`, {
            method: 'POST',
            headers: getHeaders(),
            body: JSON.stringify({
                id: settlementId,
                player_id: playerId,
                name: `${name}'s Settlement`,
                map_x: mapX,
                map_y: mapY,
                wood: 5000,
                iron: 5000,
                rice: 5000,
                liquor: 1000,
                population: 15,
                max_population: 100,
                happiness: 100,
                happiness_updated_at: new Date().toISOString()
            })
        });
        if (!resSettlement.ok) {
            const errDetail = await resSettlement.json().catch(() => ({}));
            throw new Error('Settlement creation failed: ' + (errDetail.message || errDetail.msg || JSON.stringify(errDetail)));
        }

        // 3. Insert Starter Buildings
        const starterBuildings = [
            { id: generateUUID(), settlement_id: settlementId, building_type: 'town_hall', level: 1 },
            { id: generateUUID(), settlement_id: settlementId, building_type: 'sawmill', level: 1 },
            { id: generateUUID(), settlement_id: settlementId, building_type: 'smelter', level: 1 },
            { id: generateUUID(), settlement_id: settlementId, building_type: 'rice_farm', level: 1 },
            { id: generateUUID(), settlement_id: settlementId, building_type: 'barracks', level: 1 },
            { id: generateUUID(), settlement_id: settlementId, building_type: 'house', level: 1, house_variant: 1 }
        ];

        for (const building of starterBuildings) {
            const resB = await fetch(`${SUPABASE_URL}/buildings`, {
                method: 'POST',
                headers: getHeaders(),
                body: JSON.stringify(building)
            });
            if (!resB.ok) {
                const errDetail = await resB.json().catch(() => ({}));
                throw new Error(`Starter building '${building.building_type}' creation failed: ` + (errDetail.message || JSON.stringify(errDetail)));
            }
        }

        // 4. Insert Troops
        const troopTypes = ['swordsman', 'archer', 'spearman', 'cavalry', 'elephant'];
        for (const type of troopTypes) {
            const resT = await fetch(`${SUPABASE_URL}/troops`, {
                method: 'POST',
                headers: getHeaders(),
                body: JSON.stringify({
                    id: generateUUID(),
                    settlement_id: settlementId,
                    troop_type: type,
                    count: 10,
                    training_count: 0
                })
            });
            if (!resT.ok) {
                const errDetail = await resT.json().catch(() => ({}));
                throw new Error(`Starter troop '${type}' creation failed: ` + (errDetail.message || JSON.stringify(errDetail)));
            }
        }

        // 5. Generate some mock map nodes around the player
        const nodeTypes = ['bandit', 'forest', 'iron_mine', 'npc_settlement'];
        for (let i = 0; i < 4; i++) {
            await fetch(`${SUPABASE_URL}/map_nodes`, {
                method: 'POST',
                headers: getHeaders(),
                body: JSON.stringify({
                    id: generateUUID(),
                    node_type: nodeTypes[i],
                    map_x: mapX + (Math.random() > 0.5 ? 5 : -5) + Math.floor(Math.random() * 5),
                    map_y: mapY + (Math.random() > 0.5 ? 5 : -5) + Math.floor(Math.random() * 5),
                    defense_power: 30 + Math.floor(Math.random() * 30),
                    loot_pool: { wood: 100, iron: 50, rice: 100 },
                    owner_settlement_id: settlementId
                })
            });
        }

        refreshDashboardData();
        showToast('Test player and full starter kit generated!', 'success');
    } catch (err) {
        showToast('Error generating mock player: ' + err.message, 'danger');
    }
}

// ==========================================
// Cheats & Bulk Operations
// ==========================================

async function cheatAddResources() {
    try {
        showToast('Giving resources to everyone...', 'info');
        for (const s of appData.settlements) {
            await fetch(`${SUPABASE_URL}/settlements?id=eq.${s.id}`, {
                method: 'PATCH',
                headers: getHeaders(),
                body: JSON.stringify({
                    wood: s.wood + 10000,
                    iron: s.iron + 10000,
                    rice: s.rice + 10000,
                    liquor: s.liquor + 10000
                })
            });
        }
        refreshDashboardData();
        showToast('Added +10,000 resources to all settlements!', 'success');
    } catch (err) {
        showToast(err.message, 'danger');
    }
}

async function cheatCompleteAllUpgrades() {
    try {
        showToast('Completing all building upgrades...', 'info');
        const res = await fetch(`${SUPABASE_URL}/buildings?is_upgrading=eq.true&select=*`, {
            headers: getHeaders()
        });
        const upgrading = await res.json();
        
        if (upgrading.length === 0) {
            showToast('No buildings are currently upgrading.', 'warning');
            return;
        }

        for (const building of upgrading) {
            await fetch(`${SUPABASE_URL}/buildings?id=eq.${building.id}`, {
                method: 'PATCH',
                headers: getHeaders(),
                body: JSON.stringify({
                    level: building.level + 1,
                    is_upgrading: false,
                    upgrade_finish_at: null
                })
            });
        }
        refreshDashboardData();
        showToast(`Instantly completed ${upgrading.length} upgrades!`, 'success');
    } catch (err) {
        showToast(err.message, 'danger');
    }
}

async function cheatCompleteAllTraining() {
    try {
        showToast('Completing all troop training...', 'info');
        const res = await fetch(`${SUPABASE_URL}/troops?training_count=gt.0&select=*`, {
            headers: getHeaders()
        });
        const training = await res.json();

        if (training.length === 0) {
            showToast('No troops are currently training.', 'warning');
            return;
        }

        for (const troop of training) {
            await fetch(`${SUPABASE_URL}/troops?id=eq.${troop.id}`, {
                method: 'PATCH',
                headers: getHeaders(),
                body: JSON.stringify({
                    count: troop.count + troop.training_count,
                    training_count: 0,
                    training_finish_at: null
                })
            });
        }
        refreshDashboardData();
        showToast(`Instantly completed ${training.length} troop training queues!`, 'success');
    } catch (err) {
        showToast(err.message, 'danger');
    }
}

async function cheatClearAllTestData() {
    if (!confirm('Are you absolutely sure you want to clear ALL settlements and players? This will reset the game database.')) return;
    
    try {
        showToast('Clearing all game test data...', 'info');
        // Delete all settlements (this cascades or we delete tables in correct order)
        // Let's delete buildings, troops, map_nodes, settlements, players.
        await fetch(`${SUPABASE_URL}/achievements?select=*`, { method: 'DELETE', headers: getHeaders() });
        await fetch(`${SUPABASE_URL}/building_positions?select=*`, { method: 'DELETE', headers: getHeaders() });
        await fetch(`${SUPABASE_URL}/buildings?select=*`, { method: 'DELETE', headers: getHeaders() });
        await fetch(`${SUPABASE_URL}/caravans?select=*`, { method: 'DELETE', headers: getHeaders() });
        await fetch(`${SUPABASE_URL}/enemies?select=*`, { method: 'DELETE', headers: getHeaders() });
        await fetch(`${SUPABASE_URL}/events?select=*`, { method: 'DELETE', headers: getHeaders() });
        await fetch(`${SUPABASE_URL}/map_nodes?select=*`, { method: 'DELETE', headers: getHeaders() });
        await fetch(`${SUPABASE_URL}/march_queues?select=*`, { method: 'DELETE', headers: getHeaders() });
        await fetch(`${SUPABASE_URL}/notifications?select=*`, { method: 'DELETE', headers: getHeaders() });
        await fetch(`${SUPABASE_URL}/player_quests?select=*`, { method: 'DELETE', headers: getHeaders() });
        await fetch(`${SUPABASE_URL}/troops?select=*`, { method: 'DELETE', headers: getHeaders() });
        await fetch(`${SUPABASE_URL}/settlements?select=*`, { method: 'DELETE', headers: getHeaders() });
        
        refreshDashboardData();
        showToast('All player and game progress tables reset!', 'success');
    } catch (err) {
        showToast('Error clearing data: ' + err.message, 'danger');
    }
}

// ==========================================
// Quests & Seasons
// ==========================================

function populateQuestsTable() {
    const tbody = document.querySelector('#quests-table tbody');
    tbody.innerHTML = '';
    
    if (appData.quests.length === 0) {
        tbody.innerHTML = '<tr><td colspan="6" class="text-center">No quests found.</td></tr>';
        return;
    }

    appData.quests.forEach(quest => {
        const tr = document.createElement('tr');
        const activeBadge = quest.is_active 
            ? `<span class="badge badge-success">Active</span>` 
            : `<span class="badge badge-danger">Inactive</span>`;
            
        tr.innerHTML = `
            <td><strong>${quest.title}</strong><br><small class="text-muted">${quest.description}</small></td>
            <td>${quest.quest_type}</td>
            <td>${quest.requirement_type} (${quest.requirement_amount})</td>
            <td>
                W: ${quest.reward_wood} | I: ${quest.reward_iron} | R: ${quest.reward_rice} | L: ${quest.reward_liquor}
            </td>
            <td>${activeBadge}</td>
            <td>
                <button class="btn btn-secondary btn-sm" onclick="toggleQuestActive('${quest.id}', ${quest.is_active})">
                    ${quest.is_active ? 'Deactivate' : 'Activate'}
                </button>
            </td>
        `;
        tbody.appendChild(tr);
    });
}

async function toggleQuestActive(questId, currentStatus) {
    try {
        const res = await fetch(`${SUPABASE_URL}/quests?id=eq.${questId}`, {
            method: 'PATCH',
            headers: getHeaders(),
            body: JSON.stringify({ is_active: !currentStatus })
        });
        if (!res.ok) throw new Error('Toggle quest failed');
        refreshDashboardData();
        showToast('Quest status updated!', 'success');
    } catch (err) {
        showToast(err.message, 'danger');
    }
}

async function updateSeasonData() {
    const season = document.getElementById('current-season').value;
    try {
        const res = await fetch(`${SUPABASE_URL}/season?id=eq.1`, {
            method: 'PATCH',
            headers: getHeaders(),
            body: JSON.stringify({
                current_season: season,
                started_at: new Date().toISOString()
            })
        });
        if (!res.ok) throw new Error('Failed to update season');
        showToast('Active weather season updated successfully!', 'success');
    } catch (err) {
        showToast(err.message, 'danger');
    }
}

// ==========================================
// UI Helpers
// ==========================================

function generateUUID() {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
        var r = Math.random() * 16 | 0, v = c == 'x' ? r : (r & 0x3 | 0x8);
        return v.toString(16);
    });
}

function showToast(message, type = 'success') {
    const container = document.getElementById('alert-container');
    const toast = document.createElement('div');
    toast.className = `alert alert-${type}`;
    toast.innerHTML = `<i class="fa-solid ${type === 'success' ? 'fa-circle-check' : type === 'danger' ? 'fa-circle-xmark' : type === 'warning' ? 'fa-triangle-exclamation' : 'fa-circle-info'}"></i> <span>${message}</span>`;
    
    container.appendChild(toast);
    
    setTimeout(() => {
        toast.style.opacity = '0';
        toast.style.transform = 'translateX(100%)';
        setTimeout(() => toast.remove(), 300);
    }, 4000);
}
