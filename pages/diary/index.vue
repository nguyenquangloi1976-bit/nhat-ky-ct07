<template>
  <div>
    <!-- Header -->
    <div class="flex justify-between items-center mb-4">
      <h1 class="text-xl font-bold text-gray-800">Ghi nhật ký thi công</h1>
      <div class="flex items-center gap-3">
        <input type="date" v-model="selectedDate" @change="onDateChange"
          class="input-field text-sm" />
        <NuxtLink to="/diary/history" class="text-sm text-gray-500 hover:text-primary-600">
          ← Danh sách
        </NuxtLink>
      </div>
    </div>

    <div v-if="loading" class="text-center text-gray-400 py-12">Đang tải...</div>

    <template v-else>
      <!-- Tabs loại công trình -->
      <div class="tabs-strip mb-4">
        <button v-for="t in types" :key="t.id"
          @click="selectTab(t.id)"
          :class="[
            'px-4 py-2 rounded-lg text-sm whitespace-nowrap transition',
            selectedTypeId === t.id
              ? 'bg-primary-600 text-white'
              : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
          ]">
          {{ t.name }}
          <span v-if="getTypeEntryCount(t.id)" class="ml-1 opacity-80">({{ getTypeEntryCount(t.id) }})</span>
        </button>
      </div>

      <!-- Chưa có loại công trình -->
      <div v-if="!types.length" class="bg-white rounded-lg border p-12 text-center text-gray-400">
        Chưa có loại công trình. Vào <NuxtLink to="/admin/projects" class="text-primary-600 underline">Quản lý dự án</NuxtLink> để thêm.
      </div>

      <!-- Nội dung tab -->
      <template v-else-if="selectedTypeId">
        <!-- Chips công trình -->
        <div v-if="structuresForTab.length" class="chips-strip mb-4">
          <button v-for="s in structuresForTab" :key="s.id"
            @click="selectStructure(s.id)"
            :class="[
              'chip-btn',
              selectedStructureId === s.id ? 'active' : ''
            ]">
            {{ s.name }}
            <span v-if="entryStatusMap[s.id]" class="chip-dot" :class="entryStatusMap[s.id]"></span>
          </button>
          <button v-if="isAdmin" @click="openQuickAddStructure"
            class="chip-btn !border-dashed !border-primary-400 !text-primary-600 hover:!bg-primary-50"
            title="Thêm công trình mới">
            + Thêm
          </button>
        </div>
        <div v-else class="bg-white rounded-lg border p-8 text-center text-sm">
          <p class="text-gray-400 mb-3">Chưa có công trình nào cho loại "{{ types.find(t => t.id === selectedTypeId)?.name }}"</p>
          <div class="flex items-center justify-center gap-3">
            <NuxtLink to="/admin/structures" class="text-primary-600 hover:underline text-sm">
              Quản lý công trình →
            </NuxtLink>
            <button v-if="isAdmin" @click="openQuickAddStructure"
              class="px-3 py-1.5 bg-primary-600 text-white rounded-lg text-sm hover:bg-primary-700">
              + Thêm nhanh
            </button>
          </div>
        </div>

        <!-- ===== Bảng nhật ký + Tìm kiếm hạng mục ===== -->
        <div v-if="selectedStructureId" class="bg-white rounded-lg shadow-sm border">
          <!-- Header -->
          <div class="p-3 border-b flex justify-between items-center">
            <h3 class="font-semibold text-gray-700 text-sm">
              {{ structuresForTab.find(s => s.id === selectedStructureId)?.name }}
              <span class="text-gray-400 font-normal ml-2">— {{ formatDateVN(selectedDate) }}</span>
            </h3>
            <div class="flex items-center gap-2">
              <button v-if="isBridge && isAdmin && !entry?.is_locked" @click="openBridgeSetup"
                class="text-xs text-primary-600 hover:underline">
                {{ hasBridgeParts ? 'Sửa số trụ, số nhịp' : 'Khai báo mố, trụ, nhịp' }}
              </button>
              <button v-if="isBridge && isAdmin && hasBridgeParts" @click="openDesignQty"
                class="text-xs text-amber-600 hover:underline">
                KL thiết kế
              </button>
              <button v-if="entry && !entry.is_locked && rows.length" ref="addMoreBtn"
                @click="scrollToPicker"
                class="px-2.5 py-1 rounded bg-primary-50 text-primary-700 border border-primary-200 text-xs font-medium hover:bg-primary-100 transition">
                ＋ Bổ sung hạng mục
              </button>
              <span v-if="entry?.is_locked" class="status-badge locked">ĐÃ KHÓA</span>
              <span v-else-if="entry" class="status-badge draft">NHÁP</span>
            </div>
          </div>

          <div v-if="loadingItems" class="p-8 text-center text-gray-400 text-sm">Đang tải...</div>

          <template v-else>
            <!-- Recorded items table -->
            <div class="overflow-x-auto">
              <table class="w-full text-sm">
                <thead>
                  <tr class="bg-gray-50 text-gray-500 text-xs uppercase tracking-wide">
                    <th class="text-left px-3 py-2 min-w-[110px]">Bộ phận</th>
                    <th class="text-left px-3 py-2 min-w-[180px]">Hạng mục</th>
                    <th class="text-center px-2 py-2 w-14">ĐV</th>
                    <th class="text-center px-2 py-2 w-20">KL TK</th>
                    <th v-if="showLeftRight" class="text-center px-2 py-2 w-16">Bên</th>
                    <th class="text-center px-2 py-2 w-16"
                      :title="isLinear ? 'Lớp thứ mấy (lớp đắp, lớp móng)' : 'Đợt thi công thứ mấy của hạng mục này (vd: cọc số 1, 2, 3…)'">
                      {{ isLinear ? 'Lớp' : 'Đợt' }}
                    </th>
                    <th v-if="isLinear" class="text-center px-2 py-2 w-28">Từ Km</th>
                    <th v-if="isLinear" class="text-center px-2 py-2 w-28">Đến Km</th>
                    <th class="text-center px-2 py-2 w-28">KL thực hiện</th>
                    <th class="text-left px-2 py-2">Ghi chú</th>
                    <th v-if="!entry?.is_locked" class="w-16"></th>
                  </tr>
                </thead>
                <tbody>
                  <!-- Các dòng nhật ký -->
                  <tr v-for="row in rows" :key="row.line.uid"
                    class="border-t border-gray-100 bg-primary-50/30">
                    <td class="px-3 py-1.5 font-semibold text-primary-700 whitespace-nowrap">{{ row.item?.group_name || '—' }}</td>
                    <td class="px-3 py-1.5 font-medium text-gray-800">{{ row.item?.name }}</td>
                    <td class="px-2 py-1.5 text-center text-gray-500 text-xs">{{ row.item?.unit }}</td>
                    <td class="px-2 py-1.5 text-center text-gray-400 text-xs">{{ row.item?.design_quantity ?? '—' }}</td>
                    <!-- Bên T/P -->
                    <td v-if="showLeftRight" class="px-2 py-1.5 text-center">
                      <template v-if="entry?.is_locked">{{ row.line.side || '—' }}</template>
                      <select v-else v-model="row.line.side" class="input-xs w-14"
                        @change="autoCalcK95(row)">
                        <option :value="null">—</option>
                        <option value="T">T</option>
                        <option value="P">P</option>
                      </select>
                    </td>
                    <!-- Đợt / Lớp -->
                    <td class="px-2 py-1.5 text-center">
                      <template v-if="entry?.is_locked">{{ row.line.batch_number || '' }}</template>
                      <input v-else v-model.number="row.line.batch_number"
                        type="number" min="1" class="input-xs w-14 text-center"
                        @blur="autoCalcK95(row)" />
                    </td>
                    <!-- Lý trình (chỉ công trình theo tuyến) -->
                    <td v-if="isLinear" class="px-2 py-1.5 text-center">
                      <template v-if="entry?.is_locked">{{ row.line.km_from_text }}</template>
                      <input v-else v-model="row.line.km_from_text" @blur="normalizeKm(row.line, 'km_from_text'); autoCalcK95(row); checkOverlap(row)"
                        :class="['input-xs w-24 text-center', kmInvalid(row.line.km_from_text) ? 'border-red-500 bg-red-50' : '']"
                        placeholder="Km60+100" />
                    </td>
                    <td v-if="isLinear" class="px-2 py-1.5 text-center">
                      <template v-if="entry?.is_locked">{{ row.line.km_to_text }}</template>
                      <input v-else v-model="row.line.km_to_text" @blur="normalizeKm(row.line, 'km_to_text'); autoCalcK95(row); checkOverlap(row)"
                        :class="['input-xs w-24 text-center', kmInvalid(row.line.km_to_text) ? 'border-red-500 bg-red-50' : '']"
                        placeholder="Km60+300" />
                      <div v-if="row.line._overlapWarning" class="text-xs text-red-500 mt-0.5 whitespace-nowrap">
                        ⚠️ {{ row.line._overlapWarning }}
                      </div>
                    </td>
                    <!-- Khối lượng -->
                    <td class="px-2 py-1.5 text-center relative">
                      <template v-if="entry?.is_locked">
                        <span class="font-semibold">{{ row.line.quantity || '' }}</span>
                      </template>
                      <div v-else class="relative inline-flex items-center">
                        <input v-model.number="row.line.quantity"
                          type="number" min="0"
                          :step="isIntegerUnit(row.item?.unit) ? 1 : 0.01"
                          @blur="isIntegerUnit(row.item?.unit) && (row.line.quantity = Math.round(row.line.quantity || 0))"
                          :class="['input-xs w-24 text-right', row.line._autoCalc ? 'bg-green-50 border-green-300' : '']" />
                        <span v-if="row.line._autoCalc"
                          :title="'Tự tính từ DTPL: ' + (row.line._autoCalcFormula || '')"
                          class="absolute -right-4 top-0 text-green-600 text-xs cursor-help">⚡</span>
                      </div>
                    </td>
                    <!-- Ghi chú -->
                    <td class="px-2 py-1.5">
                      <template v-if="entry?.is_locked">{{ row.line.notes || '' }}</template>
                      <input v-else v-model="row.line.notes" class="input-xs w-full" placeholder="..." />
                    </td>
                    <!-- Thêm đoạn / Xóa -->
                    <td v-if="!entry?.is_locked" class="px-2 py-1.5 text-center whitespace-nowrap">
                      <button @click="duplicateLine(row.line)" :title="isLinear ? 'Thêm một đoạn lý trình khác cho hạng mục này' : 'Thêm một đợt khác cho hạng mục này'"
                        class="text-primary-500 hover:text-primary-700 text-base leading-none mr-2">+</button>
                      <button @click="removeDiaryLine(row.line)" title="Xóa dòng"
                        class="text-red-400 hover:text-red-600 text-lg leading-none">×</button>
                    </td>
                  </tr>

                  <!-- Empty -->
                  <tr v-if="!rows.length">
                    <td :colspan="totalCols" class="px-3 py-6 text-center text-gray-400 text-sm">
                      Chưa ghi hạng mục nào. Chọn bộ phận rồi bấm hạng mục bên dưới để thêm.
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>

            <!-- Cầu chưa khai báo bộ phận -->
            <div v-if="!hasBridgeParts && !entry?.is_locked" class="p-4 border-t bg-yellow-50 text-sm text-yellow-900">
              Công trình này chưa có hạng mục. Khai báo tại
              <NuxtLink to="/admin/kl-thiet-ke" class="text-primary-600 underline font-medium">Khối lượng thiết kế</NuxtLink>
              <span v-if="isBridge"> hoặc </span>
              <button v-if="isBridge && isAdmin" @click="openBridgeSetup" class="px-3 py-1 bg-primary-600 text-white rounded hover:bg-primary-700">
                Tạo nhanh theo mố/trụ/nhịp
              </button>
              <span v-if="!isAdmin && !isBridge" class="ml-1">Nhờ quản trị viên khai báo.</span>
            </div>

            <!-- Chọn nhanh: Bộ phận → Hạng mục -->
            <div v-if="!entry?.is_locked" ref="pickerSection" class="p-3 border-t">
              <div class="text-xs font-semibold text-gray-500 uppercase tracking-wide mb-2">1. Chọn bộ phận</div>
              <div class="flex flex-wrap gap-1.5 mb-3">
                <span v-for="g in groupList" :key="g" class="inline-flex items-center gap-0.5">
                  <button @click="selectedGroup = g"
                    :class="['px-2.5 py-1 rounded-l border text-sm transition',
                      g !== 'Khác' ? 'border-r-0' : 'rounded-r',
                      selectedGroup === g ? 'bg-primary-600 text-white border-primary-600' : 'bg-white text-gray-700 border-gray-300 hover:border-primary-400',
                      groupsWithLines.has(g) && selectedGroup !== g ? 'ring-1 ring-yellow-400' : '']">
                    {{ g }}
                  </button>
                  <button v-if="g !== 'Khác'" @click.stop="deleteGroup(g)" :title="'Xóa bộ phận ' + g"
                    :class="['px-1 py-1 rounded-r border border-l-0 text-sm transition',
                      selectedGroup === g ? 'bg-primary-600 text-primary-200 border-primary-600 hover:text-white' : 'bg-white text-gray-400 border-gray-300 hover:text-red-500 hover:border-red-400']">
                    ×
                  </button>
                </span>
                <button @click="openAddInGroup('')" title="Thêm một bộ phận mới cùng hạng mục đầu tiên của nó"
                  class="px-2.5 py-1 rounded border border-dashed border-primary-400 text-sm text-primary-600 hover:bg-primary-50">
                  + Bộ phận mới
                </button>
              </div>
              <template v-if="selectedGroup">
                <div class="text-xs font-semibold text-gray-500 uppercase tracking-wide mb-2">
                  2. Bấm hạng mục của {{ selectedGroup }} để thêm vào nhật ký
                </div>
                <div class="flex flex-wrap gap-1.5">
                  <button v-for="w in itemsOfGroup" :key="w._key" @click="addFromSuggestion(w)"
                    class="px-2.5 py-1 rounded border border-gray-300 bg-gray-50 text-sm hover:bg-primary-50 hover:border-primary-400">
                    {{ w.name }} <span class="text-xs text-gray-400">({{ w.unit }})</span>
                  </button>
                  <button @click="openAddInGroup(selectedGroup)" :title="'Thêm hạng mục mới vào ' + selectedGroup"
                    class="px-2.5 py-1 rounded border border-dashed border-primary-400 text-sm text-primary-600 hover:bg-primary-50">
                    + Thêm hạng mục
                  </button>
                </div>
              </template>
            </div>

            <!-- Search dropdown to add items -->
            <div v-if="!entry?.is_locked" class="p-3 border-t relative">
              <div class="relative">
                <input ref="searchInput"
                  v-model="searchQuery"
                  @focus="showSuggestions = true"
                  @blur="closeSuggestionsDelayed"
                  class="input-field w-full !pl-9"
                  placeholder="Hoặc gõ để tìm hạng mục, thêm hạng mục mới..." />
                <span class="absolute left-2.5 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none">🔍</span>
              </div>

              <!-- Suggestions dropdown -->
              <div v-if="showSuggestions && (filteredSuggestions.length || searchQuery)"
                class="absolute left-3 right-3 mt-1 bg-white border border-gray-200 rounded-lg shadow-lg max-h-64 overflow-y-auto z-40">

                <!-- Grouped suggestions -->
                <template v-for="(group, gi) in groupedSuggestions" :key="gi">
                  <div v-if="group.label && group.items.length"
                    class="px-3 py-1.5 bg-gray-50 text-xs font-semibold text-gray-500 uppercase sticky top-0 border-b">
                    {{ group.label }}
                  </div>
                  <div v-for="s in group.items" :key="s._key"
                    @mousedown.prevent="addFromSuggestion(s)"
                    class="px-3 py-2 hover:bg-primary-50 cursor-pointer text-sm flex justify-between items-center border-b border-gray-50">
                    <div>
                      <span class="font-medium text-gray-800">{{ s.name }}</span>
                      <span v-if="s.group_name && !selectedGroup" class="text-gray-400 ml-1.5 text-xs">· {{ s.group_name }}</span>
                    </div>
                    <span class="text-xs text-gray-400 ml-2 flex-shrink-0">{{ s.unit || '' }}</span>
                  </div>
                </template>

                <!-- No results -->
                <div v-if="!filteredSuggestions.length && searchQuery"
                  class="px-3 py-3 text-center text-gray-400 text-sm">
                  Không tìm thấy "{{ searchQuery }}"
                </div>

                <!-- Add new -->
                <div @mousedown.prevent="openAddWorkItemFromSearch"
                  class="px-3 py-2.5 border-t text-primary-600 hover:bg-primary-50 cursor-pointer text-sm font-medium sticky bottom-0 bg-white">
                  + Thêm hạng mục mới{{ searchQuery ? `: "${searchQuery}"` : '' }}
                </div>
              </div>
            </div>
          </template>
        </div>

        <!-- Thông tin bổ sung + Actions -->
        <div v-if="selectedStructureId && !loadingItems" class="mt-4">
          <!-- Thời tiết + ghi chú -->
          <div class="bg-white rounded-lg border p-4 mb-3">
            <h3 class="text-xs font-semibold text-gray-500 uppercase tracking-wide mb-3">Thông tin bổ sung</h3>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label class="block text-xs font-medium text-gray-500 uppercase mb-1">THỜI TIẾT</label>
                <select v-model="entryMeta.weather" :disabled="entry?.is_locked" class="input-field w-full text-sm">
                  <option value="">-- Chọn --</option>
                  <option>Nắng</option>
                  <option>Mưa</option>
                  <option>Nhiều mây</option>
                  <option>Nắng gián đoạn mưa</option>
                </select>
              </div>
              <div>
                <label class="block text-xs font-medium text-gray-500 uppercase mb-1">GHI CHÚ CHUNG</label>
                <input v-model="entryMeta.notes" :disabled="entry?.is_locked"
                  class="input-field w-full text-sm" placeholder="Ghi chú..." />
              </div>
            </div>
          </div>

          <!-- Actions -->
          <div class="flex items-center gap-3">
            <template v-if="!entry?.is_locked">
              <button @click="saveAll" :disabled="saving" class="btn-primary">
                {{ saving ? 'Đang lưu...' : 'Lưu nháp' }}
              </button>
              <button @click="saveAndLock" :disabled="saving" class="btn-success">
                Lưu & Khóa
              </button>
            </template>
            <template v-else>
              <span class="text-sm text-gray-500">Nhật ký đã khóa — chỉ xem</span>
              <button v-if="isAdmin" @click="doUnlock" class="text-sm text-primary-600 hover:underline">
                Mở khóa
              </button>
            </template>
          </div>
        </div>
      </template>
    </template>

    <!-- Modal thêm hạng mục mới -->
    <div v-if="showAddModal" class="fixed inset-0 bg-black/40 z-50 flex items-center justify-center"
      @click.self="showAddModal = false">
      <div class="bg-white rounded-lg shadow-xl p-6 w-full max-w-md">
        <h3 class="font-semibold text-gray-800 mb-4">Thêm hạng mục công việc</h3>
        <div class="space-y-3">
          <div>
            <label class="block text-sm text-gray-600 mb-1">Bộ phận</label>
            <input v-model="newWI.group_name" class="input-field w-full" placeholder="VD: Nền đường, Trụ T3, Mặt đường"
              list="group-suggestions" />
            <datalist id="group-suggestions">
              <option v-for="g in groupList" :key="g" :value="g" />
            </datalist>
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1">Tên hạng mục <span class="text-red-500">*</span></label>
            <input v-model="newWI.name" class="input-field w-full" placeholder="VD: Móng cọc khoan nhồi" />
          </div>
          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="block text-sm text-gray-600 mb-1">Đơn vị</label>
              <input v-model="newWI.unit" class="input-field w-full" placeholder="m³, tấn, m²" />
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">KL thiết kế</label>
              <input v-model.number="newWI.design_quantity" type="number" step="0.01"
                class="input-field w-full" placeholder="0" />
            </div>
          </div>
        </div>
        <div class="flex justify-end gap-2 mt-5">
          <button @click="showAddModal = false"
            class="px-4 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 text-sm">Hủy</button>
          <button @click="saveNewWorkItem" :disabled="!newWI.name"
            class="px-4 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700 disabled:opacity-40 text-sm font-medium">
            Lưu
          </button>
        </div>
      </div>
    </div>

    <!-- Modal khai báo bộ phận cầu -->
    <div v-if="showBridgeModal" class="fixed inset-0 bg-black/40 z-50 flex items-center justify-center"
      @click.self="showBridgeModal = false">
      <div class="bg-white rounded-lg shadow-xl p-6 w-full max-w-lg">
        <h3 class="font-semibold text-gray-800 mb-1">Khai báo kết cấu cầu</h3>
        <p class="text-sm text-gray-500 mb-4">
          Hệ thống tạo sẵn hạng mục cho từng bộ phận: 2 mố, các trụ, đúc dầm, các nhịp và hoàn thiện.
        </p>
        <div class="grid grid-cols-3 gap-3">
          <div>
            <label class="block text-sm text-gray-600 mb-1">Số mố</label>
            <input value="2" disabled class="input-field w-full bg-gray-100 text-center" />
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1">Số trụ</label>
            <input v-model.number="bridgeForm.piers" @input="bridgeForm.spans = (Number(bridgeForm.piers) || 0) + 1"
              type="number" min="0" max="60" class="input-field w-full text-center" />
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1">Số nhịp</label>
            <input v-model.number="bridgeForm.spans" type="number" min="1" max="61" class="input-field w-full text-center" />
          </div>
        </div>
        <p class="text-sm text-gray-600 mt-4">
          Sẽ có {{ bridgePreview.parts }} bộ phận: {{ bridgePreview.names }}.
          <span class="font-medium">Thêm mới {{ bridgePreview.newCount }} hạng mục</span>
          <span v-if="bridgePreview.existing"> ({{ bridgePreview.existing }} hạng mục đã có, giữ nguyên)</span>.
        </p>
        <p class="text-xs text-gray-400 mt-2">
          Cầu mở rộng hai bên: không cần tạo riêng trái, phải — khi ghi nhật ký chọn T hoặc P ở cột Bên.
          Giảm số trụ, số nhịp không xóa hạng mục đã tạo.
        </p>
        <div class="flex justify-end gap-2 mt-5">
          <button @click="showBridgeModal = false"
            class="px-4 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 text-sm">Hủy</button>
          <button @click="saveBridgeSetup" :disabled="savingBridge || !(bridgeForm.spans >= 1)"
            class="px-4 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700 disabled:opacity-40 text-sm font-medium">
            {{ savingBridge ? 'Đang tạo...' : 'Tạo hạng mục' }}
          </button>
        </div>
      </div>
    </div>

    <!-- Modal khai báo KL thiết kế cầu -->
    <div v-if="showDesignQtyModal" class="fixed inset-0 bg-black/40 z-50 flex items-center justify-center"
      @click.self="showDesignQtyModal = false">
      <div class="bg-white rounded-lg shadow-xl p-5 w-full max-w-4xl max-h-[85vh] overflow-y-auto">
        <div class="flex items-center justify-between mb-3">
          <h3 class="font-semibold text-gray-800">Khai báo KL thiết kế cầu</h3>
          <button @click="showDesignQtyModal = false" class="text-gray-400 hover:text-gray-600 text-xl leading-none">&times;</button>
        </div>
        <p class="text-xs text-gray-500 mb-3">Nhập khối lượng thiết kế cho các hạng mục chính. Nhấn Lưu để cập nhật.</p>

        <!-- Tabs bộ phận -->
        <div class="flex flex-wrap gap-1 mb-3 border-b pb-2">
          <button v-for="g in designQtyGroups" :key="g"
            @click="designQtyTab = g"
            class="px-2 py-1 text-xs rounded-md transition-colors"
            :class="designQtyTab === g ? 'bg-amber-100 text-amber-800 font-medium' : 'text-gray-500 hover:bg-gray-100'">
            {{ g }}
          </button>
        </div>

        <!-- Số dầm (chỉ hiện ở tab Đúc dầm) -->
        <div v-if="designQtyTab === 'Đúc dầm'" class="flex items-center gap-3 mb-3 p-2 bg-amber-50 rounded-lg">
          <label class="text-sm text-gray-700 font-medium whitespace-nowrap">Số dầm:</label>
          <input v-model.number="girderCount" type="number" min="1" step="1"
            class="input-field w-20 text-center text-sm" />
          <span class="text-xs text-gray-500">KL thiết kế = KL/1 dầm × {{ girderCount || 0 }} dầm</span>
        </div>

        <!-- Bảng hạng mục -->
        <table class="w-full text-sm border-collapse">
          <thead>
            <tr class="bg-gray-50 text-gray-600">
              <th class="text-left px-2 py-1.5 font-medium">Hạng mục</th>
              <th class="text-center px-2 py-1.5 font-medium w-16">ĐV</th>
              <th v-if="designQtyTab === 'Đúc dầm'" class="text-center px-2 py-1.5 font-medium w-28">KL/1 dầm</th>
              <th class="text-center px-2 py-1.5 font-medium w-28">
                {{ designQtyTab === 'Đúc dầm' ? 'Tổng' : 'KL thiết kế' }}
              </th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="item in designQtyItems" :key="item.id" class="border-b border-gray-100">
              <td class="px-2 py-1.5 text-gray-700">{{ item.name }}</td>
              <td class="px-2 py-1.5 text-center text-gray-500">{{ item.unit }}</td>
              <!-- Chế độ Đúc dầm: nhập KL/1 dầm, tự tính tổng -->
              <td v-if="designQtyTab === 'Đúc dầm'" class="px-2 py-1.5">
                <input v-model.number="girderPerUnit[item.id]"
                  type="number" min="0"
                  class="input-field w-full text-center text-sm"
                  :step="isIntegerUnit(item.unit) || item.unit === 'dầm' || item.unit === 'sợi' || item.unit === 'bộ' || item.unit === 'ngày' ? 1 : 0.01"
                  @input="designQtyValues[item.id] = Math.round(((girderPerUnit[item.id] || 0) * (girderCount || 0)) * 100) / 100" />
              </td>
              <td class="px-2 py-1.5">
                <template v-if="designQtyTab === 'Đúc dầm'">
                  <span class="block text-center text-gray-600 font-medium">
                    {{ designQtyValues[item.id] ? Number(designQtyValues[item.id]).toLocaleString('vi-VN') : '—' }}
                  </span>
                </template>
                <template v-else>
                  <input v-model.number="designQtyValues[item.id]"
                    type="number" min="0"
                    class="input-field w-full text-center text-sm"
                    :step="isIntegerUnit(item.unit) || item.unit === 'dầm' || item.unit === 'sợi' || item.unit === 'bộ' || item.unit === 'ngày' ? 1 : 0.01" />
                </template>
              </td>
            </tr>
          </tbody>
        </table>

        <div class="flex justify-end gap-2 mt-4">
          <button @click="showDesignQtyModal = false"
            class="px-4 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 text-sm">Hủy</button>
          <button @click="saveDesignQty" :disabled="savingDesignQty"
            class="px-4 py-2 bg-amber-600 text-white rounded-lg hover:bg-amber-700 disabled:opacity-40 text-sm font-medium">
            {{ savingDesignQty ? 'Đang lưu...' : 'Lưu KL thiết kế' }}
          </button>
        </div>
      </div>
    </div>

    <!-- Modal thêm công trình nhanh -->
    <div v-if="showStructureModal" class="fixed inset-0 bg-black/40 z-50 flex items-center justify-center"
      @click.self="showStructureModal = false">
      <div class="bg-white rounded-lg shadow-xl p-6 w-full max-w-md">
        <h3 class="font-semibold text-gray-800 mb-4">Thêm công trình mới</h3>
        <div class="space-y-3">
          <div>
            <label class="block text-sm text-gray-600 mb-1">Tên công trình <span class="text-red-500">*</span></label>
            <input v-model="newStruct.name" class="input-field w-full" placeholder="VD: Cầu Sông Công, Đường Km59–Km62" />
          </div>
          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="block text-sm text-gray-600 mb-1">Km bắt đầu</label>
              <input v-model="newStruct.km_start" class="input-field w-full" placeholder="Km64+200" />
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">Km kết thúc</label>
              <input v-model="newStruct.km_end" class="input-field w-full" placeholder="Km64+800" />
            </div>
          </div>
        </div>
        <div class="flex justify-end gap-2 mt-5">
          <button @click="showStructureModal = false"
            class="px-4 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 text-sm">Hủy</button>
          <button @click="saveQuickStructure" :disabled="!newStruct.name"
            class="px-4 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700 disabled:opacity-40 text-sm font-medium">
            Thêm
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: 'auth' })

const { $supabase } = useNuxtApp()
const { getTypes, getStructures, getWorkItems, addWorkItem: createWorkItem, addWorkItems, addStructure, updateStructure, updateWorkItem, deleteWorkItem } = useStructures()
const { getOrCreateEntry, saveLine, deleteLine, updateEntry, lockEntry, unlockEntry } = useDiary()
const { calcVolume, calcCumulativeVolume } = useLayerVolume()
const { currentProject } = useProject()
const { isAdmin } = useAuth()
const { success, error: showError } = useToast()

// --- State ---
const loading = ref(true)
const loadingItems = ref(false)
const saving = ref(false)
// Ngày hôm nay theo giờ máy (không dùng toISOString vì trước 7h sáng sẽ ra ngày hôm qua)
function todayLocal() {
  const d = new Date()
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
}
const selectedDate = ref(todayLocal())

const types = ref<any[]>([])
const allStructures = ref<any[]>([])
const selectedTypeId = ref('')
const selectedStructureId = ref('')

// Work items for selected structure
const workItems = ref<any[]>([])

// Catalog items for current type (templates)
const catalogItems = ref<any[]>([])

// Entry + lines
const entry = ref<any>(null)
const lines = ref<any[]>([]) // mỗi phần tử = 1 dòng nhật ký (một hạng mục có thể có nhiều dòng)
let uidSeq = 0
const entryMeta = reactive({ weather: '', notes: '' })

// Entry status badges
const entryStatusMap = ref<Record<string, 'draft' | 'locked'>>({})

// Search dropdown
const searchQuery = ref('')
const showSuggestions = ref(false)
const searchInput = ref<HTMLInputElement | null>(null)
const pickerSection = ref<HTMLElement | null>(null)

// Modals
const showAddModal = ref(false)
const newWI = reactive({ name: '', group_name: '', unit: '', design_quantity: null as number | null })

const showStructureModal = ref(false)
const newStruct = reactive({ name: '', km_start: '', km_end: '' })

// --- Computed ---
const showLeftRight = computed(() => currentProject.value?.has_left_right ?? false)

// Loại công trình đang chọn: theo tuyến (có lý trình) hay theo bộ phận (cầu, cống…)
const currentTypeCode = computed(() => types.value.find(t => t.id === selectedTypeId.value)?.code || '')
const isLinear = computed(() => !NON_LINEAR_TYPE_CODES.includes(currentTypeCode.value))
const isBridge = computed(() => currentTypeCode.value === 'CAU')
const hasBridgeParts = computed(() => workItems.value.length > 0)

// Đơn vị đếm nguyên — input step=1, tự làm tròn khi blur
const INTEGER_UNITS = ['cọc', 'chiếc', 'bộ', 'thanh', 'cái', 'tấm', 'trụ', 'cây', 'mố']
function isIntegerUnit(unit?: string | null): boolean {
  if (!unit) return false
  return INTEGER_UNITS.includes(unit.toLowerCase().trim())
}

const totalCols = computed(() => {
  let cols = 7 // bộ phận, hạng mục, ĐV, KL TK, đợt/lớp, KL, ghi chú
  if (isLinear.value) cols += 2 // từ km, đến km
  if (showLeftRight.value) cols++
  if (!entry.value?.is_locked) cols++
  return cols
})

// ----- Chọn nhanh theo bộ phận -----
const selectedGroup = ref('')
// Nguồn chọn nhanh: hạng mục đã gán cho công trình + danh mục mẫu của loại công trình
// (cầu chỉ dùng hạng mục theo bộ phận đã khai báo, không lấy danh mục mẫu)
const pickerCatalog = computed(() => (isBridge.value ? [] : catalogItems.value))
const groupList = computed(() => {
  const seen: string[] = []
  for (const it of [...pickerCatalog.value, ...workItems.value]) {
    const g = it.group_name || 'Khác'
    if (!seen.includes(g)) seen.push(g)
  }
  return seen
})
const itemsOfGroup = computed(() => {
  const inGroup = (it: any) => (it.group_name || 'Khác') === selectedGroup.value
  const wiByName = new Map(workItems.value.filter(inGroup).map(w => [w.name.toLowerCase(), w]))
  const out: any[] = []
  const used = new Set<string>()
  // Theo thứ tự danh mục mẫu; hạng mục nào đã gán cho công trình thì dùng bản đã gán
  for (const c of pickerCatalog.value.filter(inGroup)) {
    const key = c.name.toLowerCase()
    const w = wiByName.get(key)
    out.push(w ? { ...w, _key: 'wi_' + w.id, _source: 'work_item' } : { ...c, _key: 'cat_' + c.id, _source: 'catalog' })
    used.add(key)
  }
  for (const w of workItems.value.filter(inGroup)) {
    if (!used.has(w.name.toLowerCase())) out.push({ ...w, _key: 'wi_' + w.id, _source: 'work_item' })
  }
  return out
})
const groupsWithLines = computed(() => {
  const byId = new Map(workItems.value.map(w => [w.id, w.group_name || 'Khác']))
  return new Set(lines.value.map(l => byId.get(l.work_item_id)))
})

// ----- Khai báo bộ phận cầu -----
const showBridgeModal = ref(false)
const savingBridge = ref(false)
const bridgeForm = reactive({ piers: 0, spans: 1 })

const bridgeNewItems = computed(() => {
  const have = new Set(workItems.value.map(w => `${w.group_name}|${w.name}`))
  const all = buildBridgeItems(Math.max(0, Number(bridgeForm.piers) || 0), Math.max(1, Number(bridgeForm.spans) || 1))
  return { all, missing: all.filter(it => !have.has(`${it.group_name}|${it.name}`)) }
})
const bridgePreview = computed(() => {
  const p = Math.max(0, Number(bridgeForm.piers) || 0)
  const n = Math.max(1, Number(bridgeForm.spans) || 1)
  const names = ['Mố A1, Mố A2', p ? (p === 1 ? 'Trụ T1' : `Trụ T1–T${p}`) : '', 'Đúc dầm', n === 1 ? 'Nhịp 1' : `Nhịp 1–${n}`, 'Hoàn thiện']
  return {
    parts: bridgePartNames(p, n).length,
    names: names.filter(Boolean).join(', '),
    newCount: bridgeNewItems.value.missing.length,
    existing: bridgeNewItems.value.all.length - bridgeNewItems.value.missing.length,
  }
})

function openBridgeSetup() {
  const st = allStructures.value.find(s => s.id === selectedStructureId.value)
  const meta = st?.metadata?.bridge
  // Ưu tiên số đã khai báo; nếu chưa có thì đếm theo hạng mục hiện có
  const countOf = (re: RegExp) => new Set(workItems.value.map(w => w.group_name).filter((g: string) => re.test(g || ''))).size
  bridgeForm.piers = meta?.piers ?? countOf(/^Trụ T\d+$/)
  bridgeForm.spans = meta?.spans ?? (countOf(/^Nhịp \d+$/) || bridgeForm.piers + 1)
  showBridgeModal.value = true
}

async function saveBridgeSetup() {
  if (!selectedStructureId.value) return
  savingBridge.value = true
  try {
    const piers = Math.max(0, Number(bridgeForm.piers) || 0)
    const spans = Math.max(1, Number(bridgeForm.spans) || 1)
    // Thứ tự hiển thị theo thứ tự bộ phận: Mố → Trụ → Đúc dầm → Nhịp → Hoàn thiện
    const order = new Map(bridgeNewItems.value.all.map((it, i) => [`${it.group_name}|${it.name}`, 1000 + i]))
    const created = await addWorkItems(bridgeNewItems.value.missing.map(it => ({
      structure_id: selectedStructureId.value,
      group_name: it.group_name,
      name: it.name,
      unit: it.unit,
      sort_order: order.get(`${it.group_name}|${it.name}`),
    })))
    const st = allStructures.value.find(s => s.id === selectedStructureId.value)
    const metadata = { ...(st?.metadata || {}), bridge: { abutments: 2, piers, spans } }
    await updateStructure(selectedStructureId.value, { metadata } as any)
    if (st) st.metadata = metadata
    workItems.value = await getWorkItems(selectedStructureId.value)
    selectedGroup.value = 'Mố A1'
    showBridgeModal.value = false
    success(`Đã tạo ${created.length} hạng mục cho 2 mố, ${piers} trụ, ${spans} nhịp`)
  } catch (e: any) {
    showError(e.message)
  } finally {
    savingBridge.value = false
  }
}

// ----- Khai báo KL thiết kế cầu -----
const showDesignQtyModal = ref(false)
const savingDesignQty = ref(false)
const designQtyTab = ref('')
const designQtyValues = reactive<Record<string, number | null>>({})
// Đúc dầm: nhập KL/1 dầm → tổng = per × count
const girderCount = ref(0)
const girderPerUnit = reactive<Record<string, number | null>>({})

const designQtyGroups = computed(() => {
  const groups: string[] = []
  for (const w of workItems.value) {
    const g = w.group_name || ''
    if (g && !groups.includes(g)) groups.push(g)
  }
  return groups
})

const designQtyItems = computed(() => {
  return workItems.value.filter(w => (w.group_name || '') === designQtyTab.value)
})

function openDesignQty() {
  // Populate current design_quantity values
  for (const w of workItems.value) {
    designQtyValues[w.id] = w.design_quantity ?? null
  }
  // Lấy số dầm từ metadata hoặc từ số nhịp
  const st = allStructures.value.find(s => s.id === selectedStructureId.value)
  const meta = st?.metadata?.bridge
  girderCount.value = meta?.girder_count ?? meta?.spans ?? 0
  // Tính ngược KL/1 dầm từ design_quantity hiện tại
  const girderItems = workItems.value.filter(w => w.group_name === 'Đúc dầm')
  for (const w of girderItems) {
    const total = w.design_quantity ?? 0
    girderPerUnit[w.id] = girderCount.value > 0 && total > 0
      ? Math.round((total / girderCount.value) * 100) / 100
      : null
  }
  designQtyTab.value = designQtyGroups.value[0] || ''
  showDesignQtyModal.value = true
}

async function saveDesignQty() {
  savingDesignQty.value = true
  try {
    let count = 0
    for (const w of workItems.value) {
      const newVal = designQtyValues[w.id]
      const oldVal = w.design_quantity ?? null
      // Chỉ update khi thay đổi
      const nv = (newVal === null || newVal === undefined || newVal === 0) ? null : Number(newVal)
      const ov = (oldVal === null || oldVal === undefined || oldVal === 0) ? null : Number(oldVal)
      if (nv !== ov) {
        await updateWorkItem(w.id, { design_quantity: nv } as any)
        w.design_quantity = nv
        count++
      }
    }
    // Lưu số dầm vào metadata
    if (girderCount.value > 0 && selectedStructureId.value) {
      const st = allStructures.value.find(s => s.id === selectedStructureId.value)
      const meta = { ...(st?.metadata || {}), bridge: { ...(st?.metadata?.bridge || {}), girder_count: girderCount.value } }
      await updateStructure(selectedStructureId.value, { metadata: meta } as any)
      if (st) st.metadata = meta
    }
    showDesignQtyModal.value = false
    success(count > 0 ? `Đã cập nhật ${count} hạng mục` : 'Không có thay đổi')
  } catch (e: any) {
    showError(e.message)
  } finally {
    savingDesignQty.value = false
  }
}

const structuresForTab = computed(() => {
  return allStructures.value.filter(s => s.type_id === selectedTypeId.value)
})

// Các dòng nhật ký kèm thông tin hạng mục
const rows = computed(() => {
  const byId = new Map(workItems.value.map(w => [w.id, w]))
  return lines.value.map(line => ({ line, item: byId.get(line.work_item_id) }))
})

function newLine(workItemId: string, from: any = {}) {
  return {
    uid: ++uidSeq,
    id: null as string | null,
    work_item_id: workItemId,
    side: from.side ?? null,
    batch_number: from.batch_number ?? 1,
    km_from_text: '',
    km_to_text: '',
    quantity: 0,
    notes: '',
  }
}

function kmInvalid(text: string) {
  return !!text && parseKm(text) === null
}

function normalizeKm(line: any, field: 'km_from_text' | 'km_to_text') {
  const m = parseKm(line[field])
  if (m !== null) line[field] = formatKm(m)
}

// --- Auto-calculate K95 volume from DTPL layer_sections ---
const K95_PATTERN = /k95/i
function isK95Item(item: any): boolean {
  return !!item?.name && K95_PATTERN.test(item.name)
}

function findItemForLine(line: any): any {
  return workItems.value.find((w: any) => w.id === line.work_item_id)
}

const _calcTimers = new Map<string, ReturnType<typeof setTimeout>>()
async function autoCalcK95(row: any) {
  const item = row.item || findItemForLine(row.line)
  if (!isK95Item(item)) return

  const line = row.line
  if (!line.side || !line.batch_number) return

  const kmFrom = parseKm(line.km_from_text)
  const kmTo = parseKm(line.km_to_text)
  if (kmFrom === null || kmTo === null) return
  if (kmFrom === kmTo) return

  // Debounce per line (use temporary id or index)
  const key = line.id || line._tempId || 'new'
  if (_calcTimers.has(key)) clearTimeout(_calcTimers.get(key)!)
  _calcTimers.set(key, setTimeout(async () => {
    _calcTimers.delete(key)
    try {
      const result = await calcVolume({
        side: line.side as 'T' | 'P',
        layer: Number(line.batch_number),
        kmFrom: Math.min(kmFrom, kmTo),
        kmTo: Math.max(kmFrom, kmTo),
      })
      if (result.volume > 0) {
        line.quantity = result.volume
        line._autoCalc = true
        line._autoCalcFormula = result.formula
      }
    } catch (e) {
      console.warn('Auto-calc K95 failed:', e)
    }
  }, 400))
}


// --- Overlap detection ---
async function checkOverlap(row: any) {
  const item = row.item || findItemForLine(row.line)
  if (!item) return
  const line = row.line

  const kmFrom = parseKm(line.km_from_text)
  const kmTo = parseKm(line.km_to_text)
  if (kmFrom === null || kmTo === null || kmFrom === kmTo) {
    line._overlapWarning = ''
    return
  }
  const lo = Math.min(kmFrom, kmTo)
  const hi = Math.max(kmFrom, kmTo)

  // Query existing lines for same work_item, same side, same batch
  try {
    let query = $supabase
      .from('diary_lines')
      .select('id, km_from, km_to, batch_number, diary_entries!inner(entry_date, structure_id)')
      .eq('work_item_id', line.work_item_id)
      .not('km_from', 'is', null)

    if (currentProject.value) {
      query = query.eq('diary_entries.project_id', currentProject.value.id)
    }
    if (line.side) query = query.eq('side', line.side)
    if (line.batch_number) query = query.eq('batch_number', line.batch_number)
    // Exclude self
    if (line.id) query = query.neq('id', line.id)

    const { data: existing } = await query
    if (!existing || existing.length === 0) {
      line._overlapWarning = ''
      return
    }

    // Check overlap
    const overlaps: string[] = []
    for (const ex of existing) {
      const exLo = Math.min(Number(ex.km_from), Number(ex.km_to))
      const exHi = Math.max(Number(ex.km_from), Number(ex.km_to))
      if (exLo < hi && exHi > lo) {
        // Overlap detected
        const overlapStart = Math.max(lo, exLo)
        const overlapEnd = Math.min(hi, exHi)
        const date = ex.diary_entries?.entry_date || '?'
        overlaps.push(`${formatKm(overlapStart)}→${formatKm(overlapEnd)} (${date})`)
      }
    }

    if (overlaps.length > 0) {
      line._overlapWarning = `Trùng lý trình: ${overlaps.join('; ')}`
    } else {
      line._overlapWarning = ''
    }
  } catch (e) {
    console.warn('Overlap check failed:', e)
  }
}

// Suggestions for search dropdown
const filteredSuggestions = computed(() => {
  const query = searchQuery.value.toLowerCase().trim()
  // 1. Hạng mục đã gán cho công trình — lọc theo bộ phận đang chọn
  const grp = selectedGroup.value
  const fromWorkItems = workItems.value
    .filter(w => !grp || (w.group_name || 'Khác') === grp)
    .map(w => ({ ...w, _key: 'wi_' + w.id, _source: 'work_item' as const }))

  // 2. Catalog items for this type not already in work_items
  const wiNames = new Set(workItems.value.map(w => w.name.toLowerCase()))
  const fromCatalog = (isBridge.value ? [] : catalogItems.value)
    .filter(c => !wiNames.has(c.name.toLowerCase()))
    .map(c => ({ ...c, _key: 'cat_' + c.id, _source: 'catalog' as const }))

  const all = [...fromWorkItems, ...fromCatalog]

  if (!query) return all
  return all.filter(item =>
    item.name.toLowerCase().includes(query)
    || (item.group_name || '').toLowerCase().includes(query)
    || (item.unit || '').toLowerCase().includes(query)
  )
})

// Group suggestions for display
const groupedSuggestions = computed(() => {
  const fromWI = filteredSuggestions.value.filter(s => s._source === 'work_item')
  const fromCat = filteredSuggestions.value.filter(s => s._source === 'catalog')

  const groups: { label: string; items: any[] }[] = []
  if (fromWI.length) {
    groups.push({ label: 'Hạng mục đã gán', items: fromWI })
  }
  if (fromCat.length) {
    groups.push({ label: 'Danh mục mẫu', items: fromCat })
  }
  // If no grouping needed
  if (groups.length <= 1 && !fromCat.length && !fromWI.length) {
    return [{ label: '', items: filteredSuggestions.value }]
  }
  return groups
})

const existingGroups = computed(() => {
  const set = new Set(workItems.value.map(w => w.group_name).filter(Boolean))
  return Array.from(set)
})

// --- Methods ---

function formatDateVN(dateStr: string): string {
  if (!dateStr) return ''
  const [y, m, d] = dateStr.split('-')
  return `${d}/${m}/${y}`
}

function getTypeEntryCount(typeId: string) {
  const structIds = allStructures.value.filter(s => s.type_id === typeId).map(s => s.id)
  return structIds.filter(id => entryStatusMap.value[id]).length
}

function selectTab(typeId: string) {
  selectedTypeId.value = typeId
  selectedStructureId.value = ''
  workItems.value = []
  catalogItems.value = []
  entry.value = null
  lines.value = []
  searchQuery.value = ''
  showSuggestions.value = false

  // Auto-select first structure
  const structs = allStructures.value.filter(s => s.type_id === typeId)
  if (structs.length) {
    selectStructure(structs[0].id)
  }
}

async function selectStructure(structId: string) {
  selectedStructureId.value = structId
  selectedGroup.value = ''
  entry.value = null
  lines.value = []
  searchQuery.value = ''
  showSuggestions.value = false
  await loadStructureData()
}

function onDateChange() {
  loadTodayStatus()
  if (selectedStructureId.value) {
    loadStructureData()
  }
}

async function loadStructureData() {
  if (!selectedStructureId.value) return
  loadingItems.value = true

  try {
    // Load work items for this structure
    workItems.value = await getWorkItems(selectedStructureId.value)

    // Load catalog items for this type
    await loadCatalogItems()

    // Check if entry exists for this date
    const { data: existing } = await $supabase
      .from('diary_entries')
      .select('*')
      .eq('structure_id', selectedStructureId.value)
      .eq('entry_date', selectedDate.value)
      .maybeSingle()

    if (existing) {
      entry.value = existing
      entryMeta.weather = existing.weather || ''
      entryMeta.notes = existing.notes || ''
      entryStatusMap.value[selectedStructureId.value] = existing.is_locked ? 'locked' : 'draft'

      // Load existing lines
      const { data: dbLines } = await $supabase
        .from('diary_lines')
        .select('*')
        .eq('entry_id', existing.id)
        .order('created_at')

      lines.value = (dbLines || []).map((l: any) => ({
        uid: ++uidSeq,
        id: l.id,
        work_item_id: l.work_item_id,
        side: l.side,
        batch_number: l.batch_number,
        km_from_text: formatKm(l.km_from),
        km_to_text: formatKm(l.km_to),
        quantity: l.quantity,
        notes: l.notes || '',
      }))

      // Tự động chọn bộ phận đầu tiên có dòng nhật ký (giúp sửa/bổ sung nhanh hơn)
      if (!existing.is_locked && dbLines?.length) {
        const firstItem = workItems.value.find(w => w.id === dbLines[0].work_item_id)
        if (firstItem) {
          selectedGroup.value = firstItem.group_name || 'Khác'
        }
      }
    } else {
      entry.value = null
      lines.value = []
      entryMeta.weather = ''
      entryMeta.notes = ''
    }
  } catch (e: any) {
    showError(e.message)
  } finally {
    loadingItems.value = false
  }
}

// Load catalog items matching the type code of the selected type
async function loadCatalogItems() {
  const currentType = types.value.find(t => t.id === selectedTypeId.value)
  if (!currentType) {
    catalogItems.value = []
    return
  }

  try {
    const { data, error } = await $supabase
      .from('work_item_catalog')
      .select('*')
      .eq('type_code', currentType.code)
      .eq('is_active', true)
      .order('sort_order')
    if (error) throw error
    catalogItems.value = data || []
  } catch {
    catalogItems.value = []
  }
}

// Ensure entry exists (auto-create on first action)
async function ensureEntry(): Promise<any> {
  if (entry.value) return entry.value
  try {
    entry.value = await getOrCreateEntry(selectedStructureId.value, selectedDate.value)
    entryStatusMap.value[selectedStructureId.value] = 'draft'
    return entry.value
  } catch (e: any) {
    showError(e.message)
    return null
  }
}

// Add item from search suggestion
async function addFromSuggestion(suggestion: any) {
  showSuggestions.value = false
  searchQuery.value = ''

  if (suggestion._source === 'catalog') {
    // Create work_item from catalog template, then add line
    try {
      const created = await createWorkItem({
        structure_id: selectedStructureId.value,
        name: suggestion.name,
        group_name: suggestion.group_name || null,
        unit: suggestion.unit || null,
        design_quantity: suggestion.design_quantity || null,
        sort_order: workItems.value.length,
      })
      workItems.value.push(created)
      lines.value.push(newLine(created.id))
      // Auto-create entry
      await ensureEntry()
    } catch (e: any) {
      showError(e.message)
    }
  } else {
    // Hạng mục đã có: thêm một dòng nhật ký mới
    lines.value.push(newLine(suggestion.id))
    await ensureEntry()
  }
}

// Remove a diary line
async function removeDiaryLine(line: any) {
  if (line.id) {
    try {
      await deleteLine(line.id)
    } catch (e: any) {
      showError(e.message)
      return
    }
  }
  lines.value = lines.value.filter(l => l.uid !== line.uid)
}

// Thêm một dòng nữa cho cùng hạng mục (đoạn lý trình khác, lớp khác)
function duplicateLine(line: any) {
  const idx = lines.value.findIndex(l => l.uid === line.uid)
  lines.value.splice(idx + 1, 0, newLine(line.work_item_id, line))
}

function scrollToPicker() {
  pickerSection.value?.scrollIntoView({ behavior: 'smooth', block: 'start' })
}

function closeSuggestionsDelayed() {
  setTimeout(() => { showSuggestions.value = false }, 200)
}

async function saveAll(): Promise<boolean> {
  if (!entry.value && !lines.value.length) return false

  const bad = isLinear.value && lines.value.find(l => kmInvalid(l.km_from_text) || kmInvalid(l.km_to_text))
  if (bad) {
    showError('Lý trình chưa đúng dạng (vd: Km60+100). Sửa các ô viền đỏ rồi lưu lại.')
    return false
  }

  saving.value = true
  try {
    const ent = await ensureEntry()
    if (!ent) return false

    // Update entry meta
    await updateEntry(ent.id, {
      weather: entryMeta.weather || null,
      notes: entryMeta.notes || null,
    })

    // Save each line
    let kmSkipped = false
    for (const line of lines.value) {
      const a = isLinear.value ? parseKm(line.km_from_text) : null
      const b = isLinear.value ? parseKm(line.km_to_text) : null
      const saved = await saveLine({
        id: line.id || undefined,
        entry_id: ent.id,
        work_item_id: line.work_item_id,
        side: line.side || null,
        batch_number: line.batch_number || 1,
        quantity: line.quantity || 0,
        notes: line.notes || null,
        // Lý trình chỉ gửi với công trình theo tuyến
        ...(isLinear.value ? {
          km_from: a !== null && b !== null ? Math.min(a, b) : a,
          km_to: a !== null && b !== null ? Math.max(a, b) : b,
        } : {}),
      })
      line.id = saved.id
      if (saved._kmSkipped && (a !== null || b !== null)) kmSkipped = true
    }

    if (kmSkipped) {
      showError('Đã lưu khối lượng nhưng CHƯA lưu được lý trình: cần chạy file supabase/add-stations-to-lines.sql trong Supabase.')
    } else {
      success('Đã lưu nhật ký')
    }
    return true
  } catch (e: any) {
    showError(e.message)
    return false
  } finally {
    saving.value = false
  }
}

async function saveAndLock() {
  const ok = await saveAll()
  if (ok && entry.value) {
    try {
      await lockEntry(entry.value.id)
      entry.value.is_locked = true
      entryStatusMap.value[selectedStructureId.value] = 'locked'
      success('Đã khóa nhật ký')
    } catch (e: any) {
      showError(e.message)
    }
  }
}

async function doUnlock() {
  if (!entry.value) return
  try {
    await unlockEntry(entry.value.id)
    entry.value.is_locked = false
    entryStatusMap.value[selectedStructureId.value] = 'draft'
    success('Đã mở khóa')
  } catch (e: any) {
    showError(e.message)
  }
}

// Add work item modals
function openAddWorkItemFromSearch() {
  showSuggestions.value = false
  Object.assign(newWI, {
    name: searchQuery.value || '',
    group_name: selectedGroup.value && selectedGroup.value !== 'Khác' ? selectedGroup.value : '',
    unit: '',
    design_quantity: null,
  })
  searchQuery.value = ''
  showAddModal.value = true
}

// Mở form thêm hạng mục từ phần chọn bộ phận (group rỗng = tạo bộ phận mới)
function openAddInGroup(group: string) {
  Object.assign(newWI, {
    name: '',
    group_name: group && group !== 'Khác' ? group : '',
    unit: '',
    design_quantity: null,
  })
  showAddModal.value = true
}

async function deleteGroup(group: string) {
  if (!group || group === 'Khác') return
  const items = workItems.value.filter(w => (w.group_name || 'Khác') === group)
  if (!items.length) return
  const usedIds = new Set(lines.value.map(l => l.work_item_id))
  const hasData = items.some(w => usedIds.has(w.id))
  const msg = hasData
    ? `Bộ phận "${group}" có ${items.length} hạng mục, trong đó có hạng mục đã ghi nhật ký. Xóa sẽ mất dữ liệu. Tiếp tục?`
    : `Xóa bộ phận "${group}" (${items.length} hạng mục)?`
  if (!confirm(msg)) return
  try {
    for (const w of items) {
      await deleteWorkItem(w.id)
    }
    workItems.value = workItems.value.filter(w => (w.group_name || 'Khác') !== group)
    lines.value = lines.value.filter(l => !items.some(w => w.id === l.work_item_id))
    if (selectedGroup.value === group) selectedGroup.value = ''
    success(`Đã xóa bộ phận "${group}"`)
  } catch (e: any) {
    showError(e.message)
  }
}

function openAddWorkItem() {
  Object.assign(newWI, { name: '', group_name: '', unit: '', design_quantity: null })
  showAddModal.value = true
}

// Hạng mục mới xếp cuối bộ phận của nó; bộ phận mới xếp sau cùng
function sortOrderForNewItem(group: string) {
  const all = workItems.value.map(w => Number(w.sort_order) || 0)
  const inGroup = workItems.value.filter(w => (w.group_name || '') === (group || '')).map(w => Number(w.sort_order) || 0)
  if (inGroup.length) return Math.max(...inGroup)
  return all.length ? Math.max(...all) + 1 : 0
}

async function saveNewWorkItem() {
  if (!newWI.name || !selectedStructureId.value) return
  try {
    const created = await createWorkItem({
      structure_id: selectedStructureId.value,
      name: newWI.name,
      group_name: newWI.group_name || null,
      unit: newWI.unit || null,
      design_quantity: newWI.design_quantity || null,
      sort_order: sortOrderForNewItem(newWI.group_name),
    })
    workItems.value.push(created)
    selectedGroup.value = created.group_name || 'Khác'
    // Auto-add to diary
    lines.value.push(newLine(created.id))
    await ensureEntry()
    showAddModal.value = false
    success('Đã thêm: ' + created.name)
  } catch (e: any) {
    showError(e.message)
  }
}

// Quick-add structure
function openQuickAddStructure() {
  Object.assign(newStruct, { name: '', km_start: '', km_end: '' })
  showStructureModal.value = true
}

async function saveQuickStructure() {
  if (!newStruct.name || !selectedTypeId.value) return
  try {
    const station = [newStruct.km_start, newStruct.km_end].filter(Boolean).join(' → ') || null
    const created = await addStructure({
      type_id: selectedTypeId.value,
      code: newStruct.name.replace(/\s+/g, '_').toUpperCase().slice(0, 20),
      name: newStruct.name,
      station,
      sort_order: structuresForTab.value.length,
    } as any)
    allStructures.value.push(created)
    showStructureModal.value = false
    success('Đã thêm: ' + created.name)
    selectStructure(created.id)
  } catch (e: any) {
    showError(e.message)
  }
}

// Load today's entry status for badges
async function loadTodayStatus() {
  try {
    const structIds = allStructures.value.map(s => s.id)
    if (!structIds.length) return

    const { data } = await $supabase
      .from('diary_entries')
      .select('structure_id, is_locked')
      .eq('entry_date', selectedDate.value)
      .in('structure_id', structIds)

    const map: Record<string, 'draft' | 'locked'> = {}
    for (const row of data || []) {
      map[row.structure_id] = row.is_locked ? 'locked' : 'draft'
    }
    entryStatusMap.value = map
  } catch { /* ignore */ }
}

// --- Init ---
onMounted(async () => {
  try {
    const [t, s] = await Promise.all([getTypes(), getStructures()])
    types.value = t
    allStructures.value = s

    // Mở từ trang khác kèm ngày và công trình (vd: /diary?date=2026-11-17&structure=...)
    const route = useRoute()
    const qDate = String(route.query.date || '')
    if (/^\d{4}-\d{2}-\d{2}$/.test(qDate)) selectedDate.value = qDate

    await loadTodayStatus()

    const target = allStructures.value.find(st => st.id === String(route.query.structure || ''))
    if (target) {
      selectedTypeId.value = target.type_id
      await selectStructure(target.id)
    } else if (types.value.length) {
      // Auto-select first type + structure
      selectTab(types.value[0].id)
    }
  } catch (e: any) {
    showError(e.message)
  } finally {
    loading.value = false
  }
})
</script>

<style scoped>
.input-field {
  @apply px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-primary-500 focus:border-primary-500;
}
.input-xs {
  @apply px-2 py-1 border border-gray-300 rounded text-sm focus:ring-1 focus:ring-primary-500 focus:border-primary-500;
}

.tabs-strip {
  @apply flex gap-2 overflow-x-auto pb-1;
  scrollbar-width: thin;
}

.chips-strip {
  @apply flex gap-2 overflow-x-auto py-1;
  scrollbar-width: thin;
}
.chip-btn {
  @apply flex-shrink-0 px-3 py-1.5 text-sm rounded-full border border-gray-300
    text-gray-600 hover:border-primary-400 hover:text-primary-600 transition-colors
    flex items-center gap-1.5;
}
.chip-btn.active {
  @apply bg-primary-600 text-white border-primary-600;
}
.chip-dot {
  @apply w-2 h-2 rounded-full;
}
.chip-dot.draft {
  @apply bg-yellow-400;
}
.chip-dot.locked {
  @apply bg-green-500;
}

.status-badge {
  @apply px-2.5 py-0.5 text-xs font-medium rounded-full;
}
.status-badge.draft {
  @apply bg-yellow-100 text-yellow-700;
}
.status-badge.locked {
  @apply bg-gray-100 text-gray-600;
}

.btn-primary {
  @apply px-5 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700 disabled:opacity-50 text-sm font-medium;
}
.btn-success {
  @apply px-5 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-50 text-sm font-medium;
}
.btn-outlined {
  @apply px-4 py-1.5 border border-dashed border-gray-400 text-gray-600 rounded-lg hover:border-primary-500 hover:text-primary-600 transition-colors;
}
</style>
