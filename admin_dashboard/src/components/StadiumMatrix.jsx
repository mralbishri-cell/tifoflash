import React from 'react';
import { Shield, Layers, CheckCircle2, Paintbrush, Sparkles, RotateCcw } from 'lucide-react';

export const SECTORS_LIST = [
  { id: 'SEC_EAST_101', nameAr: 'شرقي 101', nameEn: 'East 101', group: 'EAST', col: 1, row: 1 },
  { id: 'SEC_EAST_102', nameAr: 'شرقي 102', nameEn: 'East 102', group: 'EAST', col: 2, row: 1 },
  { id: 'SEC_EAST_103', nameAr: 'شرقي 103', nameEn: 'East 103', group: 'EAST', col: 3, row: 1 },
  { id: 'SEC_EAST_104', nameAr: 'شرقي 104', nameEn: 'East 104', group: 'EAST', col: 4, row: 1 },

  { id: 'SEC_CURVE_L1', nameAr: 'منحنى L1', nameEn: 'Curve Left', group: 'CURVE_L', col: 0, row: 2 },
  { id: 'SEC_WEST_201', nameAr: 'غربي 201', nameEn: 'West 201', group: 'WEST', col: 2, row: 2 },
  { id: 'SEC_WEST_202', nameAr: 'غربي 202', nameEn: 'West 202', group: 'WEST', col: 3, row: 2 },
  { id: 'SEC_CURVE_R1', nameAr: 'منحنى R1', nameEn: 'Curve Right', group: 'CURVE_R', col: 5, row: 2 },

  { id: 'SEC_NORTH_301', nameAr: 'شمالي 301', nameEn: 'North 301', group: 'NORTH', col: 2, row: 3 },
  { id: 'SEC_SOUTH_401', nameAr: 'جنوبي 401', nameEn: 'South 401', group: 'SOUTH', col: 3, row: 3 },
];

export const PALETTE_COLORS = [
  { name: 'أخضر تيفو', hex: '#00E676' },
  { name: 'أبيض فلاش', hex: '#FFFFFF' },
  { name: 'أزرق سماوي', hex: '#00E5FF' },
  { name: 'أصفر ذهبي', hex: '#FFD600' },
  { name: 'بنفسجي ملفت', hex: '#D500F9' },
  { name: 'أحمر ناري', hex: '#FF1744' },
  { name: 'برتقالي', hex: '#FF9100' },
];

export function StadiumMatrix({
  selectedSectors,
  onToggleSector,
  onSelectAll,
  onClearAll,
  activeAction,
  sectorColors = {},
  onSectorColorChange,
  activeMode = 'SELECT', // 'SELECT' | 'PAINTER'
  onChangeMode,
  selectedBrush = '#00E676',
  onSelectBrush,
  onApplyPreset
}) {
  const isAllSelected = selectedSectors.length === SECTORS_LIST.length;

  const handleSectorClick = (sectorId) => {
    if (activeMode === 'PAINTER') {
      if (onSectorColorChange) {
        onSectorColorChange(sectorId, selectedBrush);
      }
    } else {
      onToggleSector(sectorId);
    }
  };

  return (
    <div className="glass-panel rounded-2xl p-6 border border-slate-800 space-y-6">
      {/* Header & Controls */}
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <h2 className="text-xl font-bold text-white flex items-center gap-2">
            <Layers className="w-5 h-5 text-emerald-400" />
            خريطة القطاعات ورسام التيفو التفاعلي | Stadium Tifo Matrix
          </h2>
          <p className="text-xs text-slate-400 mt-1">
            {activeMode === 'PAINTER'
              ? 'انقر على القطاع لتلوينه بلون الفرشاة المختار مباشرة'
              : `تحديد القطاعات المستهدفة بالعرض الضوئي (Selected: ${selectedSectors.length}/${SECTORS_LIST.length})`}
          </p>
        </div>

        {/* Mode Toggle Buttons */}
        <div className="flex items-center gap-2 bg-slate-900 p-1.5 rounded-xl border border-slate-800">
          <button
            onClick={() => onChangeMode && onChangeMode('SELECT')}
            className={`px-3 py-1.5 rounded-lg text-xs font-bold transition flex items-center gap-1.5 ${
              activeMode === 'SELECT'
                ? 'bg-emerald-500 text-black shadow'
                : 'text-slate-400 hover:text-white'
            }`}
          >
            <CheckCircle2 className="w-3.5 h-3.5" />
            تحديد القطاعات
          </button>
          <button
            onClick={() => onChangeMode && onChangeMode('PAINTER')}
            className={`px-3 py-1.5 rounded-lg text-xs font-bold transition flex items-center gap-1.5 ${
              activeMode === 'PAINTER'
                ? 'bg-purple-500 text-white shadow'
                : 'text-slate-400 hover:text-white'
            }`}
          >
            <Paintbrush className="w-3.5 h-3.5" />
            رسم التيفو التفاعلي
          </button>
        </div>
      </div>

      {/* Painter Toolbar (shown in PAINTER mode) */}
      {activeMode === 'PAINTER' && (
        <div className="bg-slate-900/90 p-4 rounded-xl border border-purple-500/30 flex flex-wrap items-center justify-between gap-4 animate-fadeIn">
          {/* Palette Colors */}
          <div className="flex items-center gap-2">
            <span className="text-xs font-bold text-slate-300 flex items-center gap-1">
              <Paintbrush className="w-3.5 h-3.5 text-purple-400" /> لون الفرشاة:
            </span>
            <div className="flex items-center gap-1.5">
              {PALETTE_COLORS.map((col) => (
                <button
                  key={col.hex}
                  onClick={() => onSelectBrush && onSelectBrush(col.hex)}
                  title={col.name}
                  className={`w-7 h-7 rounded-full border-2 transition-transform ${
                    selectedBrush === col.hex
                      ? 'scale-125 border-white shadow-lg'
                      : 'border-slate-700 hover:scale-110'
                  }`}
                  style={{ backgroundColor: col.hex }}
                />
              ))}
            </div>
          </div>

          {/* Quick Preset Themes */}
          <div className="flex items-center gap-2">
            <span className="text-xs font-bold text-slate-300 flex items-center gap-1">
              <Sparkles className="w-3.5 h-3.5 text-amber-400" /> أنماط جاهزة:
            </span>
            <button
              onClick={() => onApplyPreset && onApplyPreset('TEAM')}
              className="px-2.5 py-1 rounded bg-slate-800 hover:bg-slate-700 text-emerald-400 border border-emerald-500/30 text-[11px] font-bold"
            >
              🇸🇦 أخضر وأبيض
            </button>
            <button
              onClick={() => onApplyPreset && onApplyPreset('ALL_WHITE')}
              className="px-2.5 py-1 rounded bg-slate-800 hover:bg-slate-700 text-white border border-slate-600 text-[11px] font-bold"
            >
              ⚡ أبيض فلاش
            </button>
            <button
              onClick={() => onApplyPreset && onApplyPreset('RAINBOW')}
              className="px-2.5 py-1 rounded bg-slate-800 hover:bg-slate-700 text-cyan-400 border border-cyan-500/30 text-[11px] font-bold"
            >
              🌈 تدرج ملون
            </button>
            <button
              onClick={() => onApplyPreset && onApplyPreset('RESET')}
              className="px-2 py-1 rounded bg-red-950/40 hover:bg-red-900/50 text-red-400 border border-red-500/20 text-[11px] font-bold flex items-center gap-1"
            >
              <RotateCcw className="w-3 h-3" /> مسح
            </button>
          </div>
        </div>
      )}

      {/* Quick Select Buttons (shown in SELECT mode) */}
      {activeMode === 'SELECT' && (
        <div className="flex items-center justify-end gap-2">
          <button
            onClick={onSelectAll}
            className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition ${
              isAllSelected
                ? 'bg-emerald-500 text-black font-bold'
                : 'bg-slate-800 hover:bg-slate-700 text-slate-200'
            }`}
          >
            تحديد الكل (Stadium-Wide)
          </button>
          <button
            onClick={onClearAll}
            className="px-3 py-1.5 rounded-lg text-xs font-semibold bg-slate-800 hover:bg-slate-700 text-slate-400"
          >
            إلغاء التحديد
          </button>
        </div>
      )}

      {/* Stadium Pitch Visualizer Grid */}
      <div className="relative bg-slate-950 p-6 rounded-xl border border-slate-800 overflow-hidden">
        {/* Field Green Marker */}
        <div className="absolute inset-x-12 top-1/2 -translate-y-1/2 h-20 bg-emerald-950/40 border border-emerald-500/20 rounded-xl flex items-center justify-center pointer-events-none">
          <div className="text-emerald-500/30 text-xs font-bold tracking-widest uppercase flex items-center gap-2">
            <Shield className="w-4 h-4" />
            الملعب الرئيسي • STADIUM PITCH
          </div>
        </div>

        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 relative z-10">
          {SECTORS_LIST.map((sector) => {
            const isSelected = selectedSectors.includes(sector.id);
            const isActive =
              activeAction &&
              (activeAction.target_type === 'ALL' || activeAction.target_ids.includes(sector.id));
            const paintedColor = sectorColors[sector.id];

            return (
              <button
                key={sector.id}
                onClick={() => handleSectorClick(sector.id)}
                style={
                  paintedColor
                    ? {
                        borderColor: paintedColor,
                        boxShadow: `0 0 15px ${paintedColor}22`,
                      }
                    : {}
                }
                className={`p-4 rounded-xl text-right transition-all duration-200 flex flex-col justify-between h-28 border ${
                  paintedColor
                    ? 'bg-slate-900/90 text-white'
                    : isSelected
                    ? 'bg-emerald-950/50 border-emerald-500 text-white shadow-lg shadow-emerald-950/50'
                    : 'bg-slate-900/60 border-slate-800 text-slate-400 hover:border-slate-700'
                } ${isActive ? 'ring-2 ring-emerald-400 animate-pulse' : ''}`}
              >
                <div className="flex items-center justify-between w-full">
                  <span className="text-xs font-bold px-2 py-0.5 rounded bg-slate-800/80 text-emerald-400 flex items-center gap-1">
                    {sector.group}
                    {paintedColor && (
                      <span
                        className="w-2.5 h-2.5 rounded-full inline-block border border-white/50"
                        style={{ backgroundColor: paintedColor }}
                      />
                    )}
                  </span>
                  {activeMode === 'SELECT' && isSelected && (
                    <CheckCircle2 className="w-4 h-4 text-emerald-400" />
                  )}
                  {activeMode === 'PAINTER' && (
                    <Paintbrush className="w-3.5 h-3.5 text-purple-400" />
                  )}
                </div>

                <div>
                  <div className="font-bold text-sm text-white">{sector.nameAr}</div>
                  <div className="text-[10px] text-slate-400">{sector.nameEn}</div>
                </div>

                {isActive ? (
                  <div className="text-[10px] font-bold text-emerald-400 flex items-center gap-1">
                    <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-ping"></span>
                    مُضاء الآن ⚡
                  </div>
                ) : paintedColor ? (
                  <div
                    className="text-[10px] font-mono font-bold truncate"
                    style={{ color: paintedColor }}
                  >
                    لون التيفو: {paintedColor}
                  </div>
                ) : null}
              </button>
            );
          })}
        </div>
      </div>
    </div>
  );
}
