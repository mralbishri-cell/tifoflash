import React, { useState, useEffect } from 'react';
import { Zap, Activity, Type, Gift, Play, StopCircle, Sliders, Paintbrush, AlertTriangle, Command, ListOrdered, Music } from 'lucide-react';
import { ShowPlanner } from './ShowPlanner';
import { AudioBeatSync } from './AudioBeatSync';

export function ActionControls({ onTriggerAction, selectedSectors, isBroadcasting, sectorColors = {} }) {
  const [activeTab, setActiveTab] = useState('GOAL');

  // Custom Controls State
  const [strobeColor, setStrobeColor] = useState('#00E676');
  const [strobeFreq, setStrobeFreq] = useState(150);
  const [strobeDuration, setStrobeDuration] = useState(8);

  const [waveStepMs, setWaveStepMs] = useState(250);

  const [wordText, setWordText] = useState('TIFO');
  const [wordColor, setWordColor] = useState('#00E5FF');

  const [sponsorTitle, setSponsorTitle] = useState('عرض خيالي من الراعي الرسمي - خصم 40%');
  const [sponsorCode, setSponsorCode] = useState('MATCH2026');

  // Row Target Filter State
  const [rowFilter, setRowFilter] = useState('ALL'); // 'ALL' | 'EVEN' | 'ODD' | 'LOWER' | 'UPPER'

  // Hardware Target Selector (LED Flash vs Screen Display vs Both)
  const [hardwareTarget, setHardwareTarget] = useState('BOTH'); // 'BOTH' | 'LED_ONLY' | 'SCREEN_ONLY'

  // Global Keyboard Hotkeys for Studio Operator
  useEffect(() => {
    const handleKeyDown = (e) => {
      // Ignore hotkeys when user is typing inside input or textarea
      if (['INPUT', 'TEXTAREA', 'SELECT'].includes(e.target.tagName)) return;

      if (e.code === 'Space') {
        e.preventDefault();
        handleStopAction();
      } else if (e.code === 'F1' || e.code === 'KeyG') {
        e.preventDefault();
        handleTriggerGoalFlash();
      } else if (e.code === 'F2' || e.code === 'KeyW') {
        e.preventDefault();
        handleTriggerWave();
      } else if (e.code === 'F4' || e.code === 'KeyE') {
        e.preventDefault();
        handleEmergencyAllWhite();
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [selectedSectors, strobeColor, strobeFreq, strobeDuration, waveStepMs]);

  const handleTriggerGoalFlash = () => {
    onTriggerAction({
      type: 'STROBE',
      target_type: selectedSectors.length === 10 ? 'ALL' : 'SECTOR',
      target_ids: selectedSectors,
      target_row_filter: rowFilter,
      hardware_target: hardwareTarget,
      color_hex: strobeColor,
      flash_frequency_ms: Number(strobeFreq),
      duration_seconds: Number(strobeDuration),
    });
  };

  const handleTriggerWave = () => {
    onTriggerAction({
      type: 'WAVE',
      target_type: 'SECTOR',
      target_ids: selectedSectors,
      color_hex: '#00E676',
      flash_frequency_ms: 100,
      wave_delay_step_ms: Number(waveStepMs),
      duration_seconds: 12,
    });
  };

  const handleTriggerWord = () => {
    onTriggerAction({
      type: 'TEXT_DISPLAY',
      target_type: 'SECTOR',
      target_ids: selectedSectors,
      color_hex: wordColor,
      text_char: wordText.toUpperCase(),
      duration_seconds: 10,
    });
  };

  const handleTriggerSponsor = () => {
    onTriggerAction({
      type: 'SPONSOR_POPUP',
      target_type: selectedSectors.length === 10 ? 'ALL' : 'SECTOR',
      target_ids: selectedSectors,
      duration_seconds: 5,
      sponsor: {
        title: sponsorTitle,
        image_url: 'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?w=800&q=80',
        coupon_code: sponsorCode,
        link_url: 'https://example.com/stadium-offer',
      },
    });
  };

  const handleTriggerTifoPaint = () => {
    onTriggerAction({
      type: 'TIFO_PAINT',
      target_type: 'SECTOR_MAP',
      target_ids: Object.keys(sectorColors),
      duration_seconds: 30,
      sector_colors: sectorColors,
    });
  };

  const handleEmergencyAllWhite = () => {
    onTriggerAction({
      type: 'SOLID_COLOR',
      target_type: 'ALL',
      target_ids: [],
      color_hex: '#FFFFFF',
      duration_seconds: 300,
    });
  };

  const handleStopAction = () => {
    onTriggerAction({
      type: 'IDLE',
      target_type: 'ALL',
      target_ids: [],
      duration_seconds: 0,
    });
  };

  const activePaintedCount = Object.keys(sectorColors).length;

  return (
    <div className="glass-panel rounded-2xl p-6 border border-slate-800 space-y-6">
      {/* Console Header */}
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <h2 className="text-xl font-bold text-white flex items-center gap-2">
            <Zap className="w-5 h-5 text-emerald-400" />
            غرفة تفعيل الإشارات المباشرة | Realtime Trigger Console
          </h2>
          <p className="text-xs text-slate-400 mt-1">
            اختر نوع العرض واضبط الإعدادات للتأثير التزامني المباشر في الملعب
          </p>
        </div>

        <div className="flex items-center gap-2">
          {/* Emergency All-White Button */}
          <button
            onClick={handleEmergencyAllWhite}
            className="px-3.5 py-2 bg-amber-500/20 hover:bg-amber-500/30 border border-amber-500/50 text-amber-300 font-bold rounded-xl text-xs flex items-center gap-2 transition"
            title="تفعيل الإضاءة البيضاء الثابتة لجميع المدرجات (Hotkey: F4)"
          >
            <AlertTriangle className="w-4 h-4 text-amber-400 animate-pulse" />
            طوارئ (All-White F4)
          </button>

          {/* Stop All Button */}
          <button
            onClick={handleStopAction}
            className="px-4 py-2 bg-red-950/80 hover:bg-red-900 border border-red-500/40 text-red-300 font-bold rounded-xl text-xs flex items-center gap-2 transition shadow-lg shadow-red-950/50"
            title="إيقاف جميع التأثيرات فوراً (Hotkey: Space)"
          >
            <StopCircle className="w-4 h-4 text-red-400" />
            إيقاف الكل (Space)
          </button>
        </div>
      </div>

      {/* Preset Mode Tabs */}
      <div className="grid grid-cols-2 sm:grid-cols-6 gap-2">
        {[
          { id: 'GOAL', label: 'Goal Strobe ⚡', icon: Zap, color: 'text-emerald-400' },
          { id: 'MUSIC', label: 'Music Sync 🎵', icon: Music, color: 'text-cyan-400' },
          { id: 'PLANNER', label: 'Show Planner 🎬', icon: ListOrdered, color: 'text-amber-400' },
          { id: 'PAINT', label: 'Tifo Painter 🎨', icon: Paintbrush, color: 'text-purple-400' },
          { id: 'WAVE', label: 'Wave Effect 🌊', icon: Activity, color: 'text-cyan-400' },
          { id: 'SPONSOR', label: 'Sponsor Push 🎁', icon: Gift, color: 'text-amber-400' },
        ].map((tab) => {
          const IconComp = tab.icon;
          const isSelected = activeTab === tab.id;
          return (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              className={`p-3 rounded-xl border text-xs font-bold transition flex items-center justify-center gap-2 ${
                isSelected
                  ? 'bg-slate-800 border-emerald-500 text-white shadow-lg'
                  : 'bg-slate-900/60 border-slate-800 text-slate-400 hover:border-slate-700'
              }`}
            >
              <IconComp className={`w-4 h-4 ${tab.color}`} />
              {tab.label}
            </button>
          );
        })}
      </div>

      {/* Row Target Filter Bar */}
      <div className="bg-slate-900/80 p-3 rounded-xl border border-slate-800 flex flex-wrap items-center justify-between gap-3 text-xs">
        <span className="font-bold text-slate-300 flex items-center gap-1.5">
          <Sliders className="w-4 h-4 text-cyan-400" />
          تصفية الصفوف المستهدفة (Row Filter):
        </span>
        <div className="flex flex-wrap items-center gap-1.5">
          {[
            { id: 'ALL', label: 'جميع الصفوف (All Rows)' },
            { id: 'EVEN', label: 'الصفوف الزوجية (Even Rows 2,4,6)' },
            { id: 'ODD', label: 'الصفوف الفردية (Odd Rows 1,3,5)' },
            { id: 'LOWER', label: 'الصفوف السفلية (Lower 1-15)' },
            { id: 'UPPER', label: 'الصفوف العلوية (Upper 16+)' },
          ].map((rf) => (
            <button
              key={rf.id}
              onClick={() => setRowFilter(rf.id)}
              className={`px-2.5 py-1 rounded-lg text-[11px] font-bold transition ${
                rowFilter === rf.id
                  ? 'bg-cyan-500 text-black shadow font-black'
                  : 'bg-slate-800 text-slate-400 hover:text-white'
              }`}
            >
              {rf.label}
            </button>
          ))}
        </div>
      </div>

      {/* Hardware Light Source Target Bar */}
      <div className="bg-slate-900/80 p-3 rounded-xl border border-slate-800 flex flex-wrap items-center justify-between gap-3 text-xs">
        <span className="font-bold text-slate-300 flex items-center gap-1.5">
          <Zap className="w-4 h-4 text-emerald-400" />
          مصدر الإضاءة المستهدف بالجوال (Hardware Target):
        </span>
        <div className="flex flex-wrap items-center gap-1.5">
          {[
            { id: 'BOTH', label: '🔄 كلاهما (الفلاش + شاشة الجوال)' },
            { id: 'LED_ONLY', label: '⚡ الفلاش الخلفي فقط (Rear Camera LED)' },
            { id: 'SCREEN_ONLY', label: '📱 شاشة الجوال فقط (Screen Display)' },
          ].map((ht) => (
            <button
              key={ht.id}
              onClick={() => setHardwareTarget(ht.id)}
              className={`px-3 py-1 rounded-lg text-[11px] font-bold transition ${
                hardwareTarget === ht.id
                  ? 'bg-emerald-500 text-black shadow font-black'
                  : 'bg-slate-800 text-slate-400 hover:text-white'
              }`}
            >
              {ht.label}
            </button>
          ))}
        </div>
      </div>

      {/* Tab Panels */}
      <div className="bg-slate-950/80 p-5 rounded-xl border border-slate-800">
        {activeTab === 'GOAL' && (
          <div className="space-y-4">
            <h3 className="text-sm font-bold text-emerald-400 flex items-center gap-2">
              <Sliders className="w-4 h-4" /> إعدادات Goal Strobe (الومضات السريعة للملعب)
            </h3>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div>
                <label className="text-xs text-slate-400 block mb-1">
                  اللون الرئيسي / Color HEX
                </label>
                <div className="flex items-center gap-2">
                  <input
                    type="color"
                    value={strobeColor}
                    onChange={(e) => setStrobeColor(e.target.value)}
                    className="w-9 h-9 rounded bg-slate-900 border border-slate-700 cursor-pointer"
                  />
                  <input
                    type="text"
                    value={strobeColor}
                    onChange={(e) => setStrobeColor(e.target.value)}
                    className="bg-slate-900 border border-slate-800 rounded px-3 py-1.5 text-xs text-white flex-1"
                  />
                </div>
              </div>

              <div>
                <label className="text-xs text-slate-400 block mb-1">
                  تردد الومضات / Flash Frequency ({strobeFreq}ms)
                </label>
                <input
                  type="range"
                  min="50"
                  max="500"
                  step="25"
                  value={strobeFreq}
                  onChange={(e) => setStrobeFreq(e.target.value)}
                  className="w-full accent-emerald-500"
                />
              </div>

              <div>
                <label className="text-xs text-slate-400 block mb-1">
                  مدة العرض / Duration ({strobeDuration}s)
                </label>
                <input
                  type="number"
                  value={strobeDuration}
                  onChange={(e) => setStrobeDuration(e.target.value)}
                  className="bg-slate-900 border border-slate-800 rounded px-3 py-1.5 text-xs text-white w-full"
                />
              </div>
            </div>

            <button
              onClick={handleTriggerGoalFlash}
              disabled={selectedSectors.length === 0}
              className="w-full mt-2 py-3 bg-emerald-500 hover:bg-emerald-400 disabled:opacity-50 text-black font-black rounded-xl text-sm flex items-center justify-center gap-2 transition shadow-lg shadow-emerald-500/20"
            >
              <Play className="w-4 h-4 fill-black" />
              بث ومضات الهدف للملعب (BROADCAST STROBE) • [F1 / G]
            </button>
          </div>
        )}

        {activeTab === 'MUSIC' && (
          <AudioBeatSync
            onTriggerAction={onTriggerAction}
            selectedSectors={selectedSectors}
          />
        )}

        {activeTab === 'PLANNER' && (
          <ShowPlanner
            onTriggerAction={onTriggerAction}
            selectedSectors={selectedSectors}
            sectorColors={sectorColors}
          />
        )}

        {activeTab === 'PAINT' && (
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <h3 className="text-sm font-bold text-purple-400 flex items-center gap-2">
                <Paintbrush className="w-4 h-4" /> بث خريطة التيفو الملونة (Sector Color Tifo Broadcast)
              </h3>
              <span className="text-xs text-purple-300 bg-purple-950/60 px-2.5 py-1 rounded-full border border-purple-500/30">
                القطاعات الملونة: {activePaintedCount}
              </span>
            </div>

            <p className="text-xs text-slate-400">
              يقوم هذا الخيار بإرسال خريطة الألوان المحددة في خريطة الملعب أعلاه مباشرةً إلى هواتف الجماهير في كل قطاع لتشكيل لوحة التيفو الملونة.
            </p>

            <button
              onClick={handleTriggerTifoPaint}
              disabled={activePaintedCount === 0}
              className="w-full py-3 bg-purple-500 hover:bg-purple-400 disabled:opacity-50 text-black font-black rounded-xl text-sm flex items-center justify-center gap-2 transition shadow-lg shadow-purple-500/20"
            >
              <Play className="w-4 h-4 fill-black" />
              بث التيفو الملون للملعب (BROADCAST TIFO PAINT)
            </button>
          </div>
        )}

        {activeTab === 'WAVE' && (
          <div className="space-y-4">
            <h3 className="text-sm font-bold text-cyan-400 flex items-center gap-2">
              <Sliders className="w-4 h-4" /> إعدادات موجة الضوء التتابع (Wave Step Controller)
            </h3>

            <div>
              <label className="text-xs text-slate-400 block mb-1">
                فارق التأخير بين المدرجات / Delay Step ({waveStepMs}ms)
              </label>
              <input
                type="range"
                min="100"
                max="1000"
                step="50"
                value={waveStepMs}
                onChange={(e) => setWaveStepMs(e.target.value)}
                className="w-full accent-cyan-500"
              />
            </div>

            <button
              onClick={handleTriggerWave}
              disabled={selectedSectors.length === 0}
              className="w-full py-3 bg-cyan-500 hover:bg-cyan-400 disabled:opacity-50 text-black font-black rounded-xl text-sm flex items-center justify-center gap-2 transition shadow-lg shadow-cyan-500/20"
            >
              <Play className="w-4 h-4 fill-black" />
              إطلاق موجة الملعب المتتابعة (TRIGGER WAVE) • [F2 / W]
            </button>
          </div>
        )}

        {activeTab === 'WORD' && (
          <div className="space-y-4">
            <h3 className="text-sm font-bold text-pink-400 flex items-center gap-2">
              <Sliders className="w-4 h-4" /> منسّق الحروف والكلام التفاعلي (Tifo Word Builder)
            </h3>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="text-xs text-slate-400 block mb-1">
                  النص أو الحرف البارز / Target Word or Character
                </label>
                <input
                  type="text"
                  maxLength={6}
                  value={wordText}
                  onChange={(e) => setWordText(e.target.value)}
                  className="bg-slate-900 border border-slate-800 rounded px-3 py-2 text-sm text-white w-full uppercase font-mono font-bold"
                />
              </div>

              <div>
                <label className="text-xs text-slate-400 block mb-1">
                  لون الشاشة / Screen Color
                </label>
                <input
                  type="color"
                  value={wordColor}
                  onChange={(e) => setWordColor(e.target.value)}
                  className="w-full h-10 rounded bg-slate-900 border border-slate-700 cursor-pointer"
                />
              </div>
            </div>

            <button
              onClick={handleTriggerWord}
              disabled={selectedSectors.length === 0}
              className="w-full py-3 bg-pink-500 hover:bg-pink-400 disabled:opacity-50 text-black font-black rounded-xl text-sm flex items-center justify-center gap-2 transition shadow-lg shadow-pink-500/20"
            >
              <Play className="w-4 h-4 fill-black" />
              عرض الحرف على شاشات الجماهير (BROADCAST TEXT)
            </button>
          </div>
        )}

        {activeTab === 'SPONSOR' && (
          <div className="space-y-4">
            <h3 className="text-sm font-bold text-amber-400 flex items-center gap-2">
              <Sliders className="w-4 h-4" /> بث بطاقة الراعي الرسمي (Sponsor Voucher Broadcast)
            </h3>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="text-xs text-slate-400 block mb-1">
                  عنوان العرض / Promo Title
                </label>
                <input
                  type="text"
                  value={sponsorTitle}
                  onChange={(e) => setSponsorTitle(e.target.value)}
                  className="bg-slate-900 border border-slate-800 rounded px-3 py-2 text-xs text-white w-full"
                />
              </div>

              <div>
                <label className="text-xs text-slate-400 block mb-1">
                  كود الخصم / Coupon Code
                </label>
                <input
                  type="text"
                  value={sponsorCode}
                  onChange={(e) => setSponsorCode(e.target.value)}
                  className="bg-slate-900 border border-slate-800 rounded px-3 py-2 text-xs text-amber-400 font-mono font-bold w-full uppercase"
                />
              </div>
            </div>

            <button
              onClick={handleTriggerSponsor}
              disabled={selectedSectors.length === 0}
              className="w-full py-3 bg-amber-500 hover:bg-amber-400 disabled:opacity-50 text-black font-black rounded-xl text-sm flex items-center justify-center gap-2 transition shadow-lg shadow-amber-500/20"
            >
              <Play className="w-4 h-4 fill-black" />
              بث بطاقة الراعي للجماهير (PUSH SPONSOR OFFER)
            </button>
          </div>
        )}
      </div>

      {/* Studio Hotkeys Legend */}
      <div className="bg-slate-900/60 px-4 py-2.5 rounded-xl border border-slate-800/80 flex flex-wrap items-center justify-between text-[11px] text-slate-400">
        <span className="font-bold text-slate-300 flex items-center gap-1">
          <Command className="w-3.5 h-3.5 text-emerald-400" /> اختصارات الكيبورد السريعة (Studio Hotkeys):
        </span>
        <div className="flex items-center gap-3 font-mono">
          <span><kbd className="bg-slate-800 text-slate-200 px-1.5 py-0.5 rounded text-[10px]">F1 / G</kbd> Goal</span>
          <span><kbd className="bg-slate-800 text-slate-200 px-1.5 py-0.5 rounded text-[10px]">F2 / W</kbd> Wave</span>
          <span><kbd className="bg-slate-800 text-slate-200 px-1.5 py-0.5 rounded text-[10px]">F4 / E</kbd> Emergency</span>
          <span><kbd className="bg-slate-800 text-slate-200 px-1.5 py-0.5 rounded text-[10px]">Space</kbd> Stop</span>
        </div>
      </div>
    </div>
  );
}
