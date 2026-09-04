import React, { useState } from 'react';
import { StadiumMatrix, SECTORS_LIST } from './components/StadiumMatrix';
import { ActionControls } from './components/ActionControls';
import { LiveLogStream } from './components/LiveLogStream';
import { broadcastLiveAction, MATCH_ID } from './services/firebaseAdminService';
import { Zap, Radio, Users, Sparkles } from 'lucide-react';

export default function App() {
  const [selectedSectors, setSelectedSectors] = useState(SECTORS_LIST.map((s) => s.id));
  const [activeAction, setActiveAction] = useState(null);
  const [logs, setLogs] = useState([]);
  const [isBroadcasting, setIsBroadcasting] = useState(false);

  // Sector Color Painter State
  const [matrixMode, setMatrixMode] = useState('SELECT'); // 'SELECT' | 'PAINTER'
  const [selectedBrush, setSelectedBrush] = useState('#00E676');
  const [sectorColors, setSectorColors] = useState({});

  const handleToggleSector = (id) => {
    setSelectedSectors((prev) =>
      prev.includes(id) ? prev.filter((item) => item !== id) : [...prev, id]
    );
  };

  const handleSelectAll = () => setSelectedSectors(SECTORS_LIST.map((s) => s.id));
  const handleClearAll = () => setSelectedSectors([]);

  const handleSectorColorChange = (sectorId, colorHex) => {
    setSectorColors((prev) => ({
      ...prev,
      [sectorId]: colorHex,
    }));
  };

  const handleApplyPreset = (presetName) => {
    if (presetName === 'RESET') {
      setSectorColors({});
      return;
    }

    const updated = {};
    if (presetName === 'TEAM') {
      // Saudi / Team Colors (Alternating Green & White)
      SECTORS_LIST.forEach((sec, idx) => {
        updated[sec.id] = idx % 2 === 0 ? '#00E676' : '#FFFFFF';
      });
    } else if (presetName === 'ALL_WHITE') {
      // Flash All White
      SECTORS_LIST.forEach((sec) => {
        updated[sec.id] = '#FFFFFF';
      });
    } else if (presetName === 'RAINBOW') {
      const colors = ['#00E676', '#00E5FF', '#D500F9', '#FFD600', '#FF1744', '#FF9100'];
      SECTORS_LIST.forEach((sec, idx) => {
        updated[sec.id] = colors[idx % colors.length];
      });
    }

    setSectorColors(updated);
  };

  const handleTriggerAction = async (payloadData) => {
    setIsBroadcasting(true);

    const result = await broadcastLiveAction(payloadData);
    const rec = result.record;

    setActiveAction(rec.type === 'IDLE' ? null : rec);

    const newLog = {
      time: new Date().toLocaleTimeString(),
      mode: result.mode,
      type: rec.type,
      target_type: rec.target_type,
      target_ids: rec.target_ids,
      payload: rec.payload,
    };

    setLogs((prev) => [newLog, ...prev.slice(0, 19)]);
    setIsBroadcasting(false);
  };

  return (
    <div className="min-h-screen bg-[#090d16] text-slate-100 p-4 md:p-8 selection:bg-emerald-500 selection:text-black">
      {/* Top Header */}
      <header className="max-w-7xl mx-auto mb-8 flex flex-wrap items-center justify-between gap-4 glass-panel p-6 rounded-2xl border border-slate-800">
        <div className="flex items-center gap-4">
          <div className="w-12 h-12 rounded-2xl bg-gradient-to-tr from-emerald-500 via-cyan-400 to-purple-500 flex items-center justify-center shadow-lg shadow-emerald-500/20">
            <Zap className="w-7 h-7 text-black stroke-[2.5]" />
          </div>
          <div>
            <h1 className="text-2xl font-black tracking-tight text-white flex items-center gap-2">
              TIFO FLASH{' '}
              <span className="text-xs bg-emerald-500/20 text-emerald-400 px-2.5 py-1 rounded-full border border-emerald-500/30 font-mono">
                ADMIN V3.0 STUDIO
              </span>
            </h1>
            <p className="text-xs text-slate-400 mt-0.5">
              غرفة تحكم التيفو الضوئي التفاعلي والمباشر في الملعب | Interactive Stadium Tifo & Strobe Control
            </p>
          </div>
        </div>

        <div className="flex items-center gap-4">
          <div className="bg-slate-900 px-4 py-2 rounded-xl border border-slate-800 flex items-center gap-3 text-xs">
            <Radio className="w-4 h-4 text-emerald-400 animate-pulse" />
            <div>
              <div className="text-slate-400 text-[10px]">المباراة النشطة</div>
              <div className="font-bold text-white font-mono">{MATCH_ID}</div>
            </div>
          </div>

          <div className="bg-slate-900 px-4 py-2 rounded-xl border border-slate-800 flex items-center gap-3 text-xs">
            <Users className="w-4 h-4 text-cyan-400" />
            <div>
              <div className="text-slate-400 text-[10px]">القطاعات المتصلة</div>
              <div className="font-bold text-cyan-400 font-mono">10 / 10 Sectors</div>
            </div>
          </div>
        </div>
      </header>

      {/* Main Grid Layout */}
      <main className="max-w-7xl mx-auto grid grid-cols-1 lg:grid-cols-12 gap-6">
        {/* Left Column: Stadium Matrix & Realtime Triggers (8 cols) */}
        <div className="lg:col-span-8 space-y-6">
          <StadiumMatrix
            selectedSectors={selectedSectors}
            onToggleSector={handleToggleSector}
            onSelectAll={handleSelectAll}
            onClearAll={handleClearAll}
            activeAction={activeAction}
            sectorColors={sectorColors}
            onSectorColorChange={handleSectorColorChange}
            activeMode={matrixMode}
            onChangeMode={setMatrixMode}
            selectedBrush={selectedBrush}
            onSelectBrush={setSelectedBrush}
            onApplyPreset={handleApplyPreset}
          />

          <ActionControls
            selectedSectors={selectedSectors}
            onTriggerAction={handleTriggerAction}
            isBroadcasting={isBroadcasting}
            sectorColors={sectorColors}
          />
        </div>

        {/* Right Column: Live Audit Stream & Payload Inspection (4 cols) */}
        <div className="lg:col-span-4">
          <LiveLogStream logs={logs} activeAction={activeAction} />
        </div>
      </main>
    </div>
  );
}
