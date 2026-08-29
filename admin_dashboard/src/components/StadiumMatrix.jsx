import React from 'react';
import { Shield, Layers, CheckCircle2 } from 'lucide-react';

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

export function StadiumMatrix({ selectedSectors, onToggleSector, onSelectAll, onClearAll, activeAction }) {
  const isAllSelected = selectedSectors.length === SECTORS_LIST.length;

  return (
    <div className="glass-panel rounded-2xl p-6 border border-slate-800">
      <div className="flex flex-wrap items-center justify-between gap-4 mb-6">
        <div>
          <h2 className="text-xl font-bold text-white flex items-center gap-2">
            <Layers className="w-5 h-5 text-emerald-400" />
            خريطة القطاعات والمنصات | Stadium Sectors Matrix
          </h2>
          <p className="text-xs text-slate-400 mt-1">
            انقر على المدرجات لتحديد النطاق المستهدف بالعرض الضوئي (Selected: {selectedSectors.length}/{SECTORS_LIST.length})
          </p>
        </div>

        <div className="flex items-center gap-2">
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
      </div>

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
            const isActive = activeAction && (activeAction.target_type === 'ALL' || activeAction.target_ids.includes(sector.id));

            return (
              <button
                key={sector.id}
                onClick={() => onToggleSector(sector.id)}
                className={`p-4 rounded-xl text-right transition-all duration-200 flex flex-col justify-between h-28 border ${
                  isSelected
                    ? 'bg-emerald-950/50 border-emerald-500 text-white shadow-lg shadow-emerald-950/50'
                    : 'bg-slate-900/60 border-slate-800 text-slate-400 hover:border-slate-700'
                } ${isActive ? 'ring-2 ring-emerald-400 animate-pulse' : ''}`}
              >
                <div className="flex items-center justify-between w-full">
                  <span className="text-xs font-bold px-2 py-0.5 rounded bg-slate-800/80 text-emerald-400">
                    {sector.group}
                  </span>
                  {isSelected && <CheckCircle2 className="w-4 h-4 text-emerald-400" />}
                </div>

                <div>
                  <div className="font-bold text-sm text-white">{sector.nameAr}</div>
                  <div className="text-[10px] text-slate-400">{sector.nameEn}</div>
                </div>

                {isActive && (
                  <div className="text-[10px] font-bold text-emerald-400 flex items-center gap-1">
                    <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-ping"></span>
                    مُضاء الآن ⚡
                  </div>
                )}
              </button>
            );
          })}
        </div>
      </div>
    </div>
  );
}
