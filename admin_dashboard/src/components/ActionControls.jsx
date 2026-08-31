import React, { useState } from 'react';
import { Zap, Activity, Type, Gift, Play, StopCircle, Sliders } from 'lucide-react';

export function ActionControls({ onTriggerAction, selectedSectors, isBroadcasting }) {
  const [activeTab, setActiveTab] = useState('GOAL');
  
  // Custom Controls State
  const [strobeColor, setStrobeColor] = useState('#00E676');
  const [strobeFreq, setStrobeFreq] = useState(150);
  const [strobeDuration, setStrobeDuration] = useState(8);

  const [waveStepMs, setWaveStepMs] = useState(250);
  const [waveDirection, setWaveDirection] = useState('L2R');
  const [waveStyle, setWaveStyle] = useState('RADIAL_RIPPLE');
  const [waveColor, setWaveColor] = useState('#00E5FF');

  const [wordText, setWordText] = useState('TIFO');
  const [wordColor, setWordColor] = useState('#00E5FF');

  const [sponsorTitle, setSponsorTitle] = useState('عرض خيالي من الراعي الرسمي - خصم 40%');
  const [sponsorCode, setSponsorCode] = useState('MATCH2026');

  const handleTriggerGoalFlash = () => {
    onTriggerAction({
      type: 'STROBE',
      target_type: selectedSectors.length === 10 ? 'ALL' : 'SECTOR',
      target_ids: selectedSectors,
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
      color_hex: waveColor,
      flash_frequency_ms: 100,
      wave_delay_step_ms: Number(waveStepMs),
      wave_direction: waveDirection,
      wave_style: waveStyle,
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
        link_url: 'https://example.com/stadium-offer'
      }
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

  return (
    <div className="glass-panel rounded-2xl p-6 border border-slate-800">
      <div className="flex items-center justify-between mb-6">
        <div>
          <h2 className="text-xl font-bold text-white flex items-center gap-2">
            <Zap className="w-5 h-5 text-emerald-400" />
            غرفة تفعيل الإشارات المباشرة | Realtime Trigger Console
          </h2>
          <p className="text-xs text-slate-400 mt-1">
            اختر نوع العرض واضبط الإعدادات للتأثير التزامني المباشر
          </p>
        </div>

        <button
          onClick={handleStopAction}
          className="px-4 py-2 bg-red-950/80 hover:bg-red-900 border border-red-500/40 text-red-300 font-bold rounded-xl text-xs flex items-center gap-2 transition"
        >
          <StopCircle className="w-4 h-4 text-red-400" />
          إيقاف جميع التأثيرات (STOP ALL)
        </button>
      </div>

      {/* Preset Mode Tabs */}
      <div className="grid grid-cols-2 sm:grid-cols-5 gap-2 mb-6">
        {[
          { id: 'STAR', label: 'استقبال النجم 🌟', icon: Zap, color: 'text-amber-400' },
          { id: 'GOAL', label: 'Goal Strobe ⚡', icon: Zap, color: 'text-emerald-400' },
          { id: 'WAVE', label: 'Wave Effect 🌊', icon: Activity, color: 'text-cyan-400' },
          { id: 'WORD', label: 'Word Builder 🔤', icon: Type, color: 'text-purple-400' },
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
                  ? 'bg-slate-800 border-amber-500 text-white shadow-lg'
                  : 'bg-slate-900/60 border-slate-800 text-slate-400 hover:border-slate-700'
              }`}
            >
              <IconComp className={`w-4 h-4 ${tab.color}`} />
              {tab.label}
            </button>
          );
        })}
      </div>

      {/* Tab Panels */}
      <div className="bg-slate-950/80 p-5 rounded-xl border border-slate-800">
        {activeTab === 'STAR' && (
          <div className="space-y-4">
            <h3 className="text-sm font-bold text-amber-400 flex items-center gap-2">
              <Zap className="w-4 h-4" /> عرض استقبال النجم التتابعي (Star Welcoming 4-Phase Show)
            </h3>
            <p className="text-xs text-slate-400">
              مسح ضوئي متتابّع بين مدرجات الشرق، الجنوب، الغرب، والشمال، متبوعاً بـ Strobe جماعي فائق السرعة في ختام الفعالية.
            </p>
            <button
              onClick={() => onTriggerAction({
                type: 'GOAL_CELEBRATION',
                target_type: 'ALL',
                target_ids: selectedSectors,
                color_hex: '#FFD700',
                duration_seconds: 12,
              })}
              disabled={selectedSectors.length === 0}
              className="w-full py-3 bg-gradient-to-r from-amber-500 to-yellow-400 hover:from-amber-400 hover:to-yellow-300 disabled:opacity-50 text-black font-black rounded-xl text-sm flex items-center justify-center gap-2 transition shadow-lg shadow-amber-500/20"
            >
              <Play className="w-4 h-4 fill-black" />
              إطلاق عرض استقبال النجم المتزامن (LAUNCH STAR SHOW)
            </button>
          </div>
        )}

        {activeTab === 'GOAL' && (
          <div className="space-y-4">
            <h3 className="text-sm font-bold text-emerald-400 flex items-center gap-2">
              <Sliders className="w-4 h-4" /> إعدادات Goal Strobe (الومضات السريعة للملعب)
            </h3>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div>
                <label className="text-xs text-slate-400 block mb-1">اللون الرئيسي / Color HEX</label>
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
                <label className="text-xs text-slate-400 block mb-1">تردد الومضات / Flash Frequency ({strobeFreq}ms)</label>
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
                <label className="text-xs text-slate-400 block mb-1">مدة العرض / Duration ({strobeDuration}s)</label>
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
              بث ومضات الهدف للملعب (BROADCAST STROBE)
            </button>
          </div>
        )}

        {activeTab === 'WAVE' && (
          <div className="space-y-4">
            <h3 className="text-sm font-bold text-cyan-400 flex items-center gap-2">
              <Sliders className="w-4 h-4" /> مصمم الموجات التفاعلي (Interactive Wave Designer)
            </h3>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {/* Wave Direction Selector */}
              <div>
                <label className="text-xs text-slate-400 block mb-1">اتجاه الحركة والتموج (Sweep Direction)</label>
                <select
                  value={waveDirection}
                  onChange={(e) => setWaveDirection(e.target.value)}
                  className="w-full bg-slate-900 border border-slate-800 text-cyan-300 font-bold rounded-lg px-3 py-2 text-xs focus:outline-none focus:border-cyan-500"
                >
                  <option value="L2R">من اليسار إلى اليمين ➡️ (Clockwise Sweep)</option>
                  <option value="R2L">من اليمين إلى اليسار ⬅️ (Counter Sweep)</option>
                  <option value="CENTER_OUT">انفجار ضوئي من المنتصف 💥 (Center Explosion)</option>
                  <option value="TOP_BOTTOM">شلال رأسي من أعلى المدرج 🌊 (Vertical Cascade)</option>
                </select>
              </div>

              {/* Wave Motion Visual Style */}
              <div>
                <label className="text-xs text-slate-400 block mb-1">المؤثر البصري المباشر (Visual Motion Style)</label>
                <select
                  value={waveStyle}
                  onChange={(e) => setWaveStyle(e.target.value)}
                  className="w-full bg-slate-900 border border-slate-800 text-amber-300 font-bold rounded-lg px-3 py-2 text-xs focus:outline-none focus:border-amber-500"
                >
                  <option value="RADIAL_RIPPLE">تموج إشعاعي ثلاثي الأبعاد 🌌 (3D Radial Ripple)</option>
                  <option value="INFERNO_PULSE">نبض الشعلة النارية 🔥 (Volcano Inferno Pulse)</option>
                  <option value="DIAMOND_SPARKLE">بريق النجوم والألماس 💎 (Diamond Sparkle Matrix)</option>
                </select>
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="text-xs text-slate-400 block mb-1">لون قمة الموجة / Crest Color</label>
                <div className="flex items-center gap-2">
                  <input
                    type="color"
                    value={waveColor}
                    onChange={(e) => setWaveColor(e.target.value)}
                    className="w-9 h-9 rounded bg-slate-900 border border-slate-700 cursor-pointer"
                  />
                  <input
                    type="text"
                    value={waveColor}
                    onChange={(e) => setWaveColor(e.target.value)}
                    className="bg-slate-900 border border-slate-800 rounded px-3 py-1.5 text-xs text-cyan-300 flex-1 font-mono"
                  />
                </div>
              </div>

              <div>
                <label className="text-xs text-slate-400 block mb-1">سرعة التموج / Wave Delay Step ({waveStepMs}ms)</label>
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
            </div>

            <button
              onClick={handleTriggerWave}
              disabled={selectedSectors.length === 0}
              className="w-full py-3 bg-gradient-to-r from-cyan-500 to-emerald-400 hover:from-cyan-400 hover:to-emerald-300 disabled:opacity-50 text-black font-black rounded-xl text-sm flex items-center justify-center gap-2 transition shadow-lg shadow-cyan-500/20"
            >
              <Play className="w-4 h-4 fill-black" />
              إطلاق نموذج الموجة المصممة للملعب (LAUNCH DESIGNED WAVE)
            </button>
          </div>
        )}

        {activeTab === 'WORD' && (
          <div className="space-y-4">
            <h3 className="text-sm font-bold text-purple-400 flex items-center gap-2">
              <Sliders className="w-4 h-4" /> منسّق الحروف والكلام التفاعلي (Tifo Word Builder)
            </h3>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="text-xs text-slate-400 block mb-1">النص أو الحرف البارز / Target Word or Character</label>
                <input
                  type="text"
                  maxLength={6}
                  value={wordText}
                  onChange={(e) => setWordText(e.target.value)}
                  className="bg-slate-900 border border-slate-800 rounded px-3 py-2 text-sm text-white w-full uppercase font-mono font-bold"
                />
              </div>

              <div>
                <label className="text-xs text-slate-400 block mb-1">لون الشاشة / Screen Color</label>
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
              className="w-full py-3 bg-purple-500 hover:bg-purple-400 disabled:opacity-50 text-black font-black rounded-xl text-sm flex items-center justify-center gap-2 transition shadow-lg shadow-purple-500/20"
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
                <label className="text-xs text-slate-400 block mb-1">عنوان العرض / Promo Title</label>
                <input
                  type="text"
                  value={sponsorTitle}
                  onChange={(e) => setSponsorTitle(e.target.value)}
                  className="bg-slate-900 border border-slate-800 rounded px-3 py-2 text-xs text-white w-full"
                />
              </div>

              <div>
                <label className="text-xs text-slate-400 block mb-1">كود الخصم / Coupon Code</label>
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
    </div>
  );
}
