import React, { useState, useEffect } from 'react';
import {
  Play,
  Pause,
  SkipForward,
  SkipBack,
  Square,
  Plus,
  Trash2,
  ListOrdered,
  Clock,
  Sparkles,
  Zap,
  Activity,
  Paintbrush,
  Gift,
  ShieldAlert,
} from 'lucide-react';

export const PRESET_SHOWS = {
  KICKOFF: {
    name: '🇸🇦 عرض دخلة المباراة (Kickoff Ceremony)',
    steps: [
      {
        id: 'k1',
        title: '1. انطلاق التيفو الملون',
        type: 'TIFO_PAINT',
        duration: 15,
        color_hex: '#00E676',
      },
      {
        id: 'k2',
        title: '2. موجة الملعب المتتابعة',
        type: 'WAVE',
        duration: 10,
        color_hex: '#00E5FF',
      },
      {
        id: 'k3',
        title: '3. ومضات الفلاش الاحتفالية',
        type: 'STROBE',
        duration: 8,
        color_hex: '#FFFFFF',
      },
      {
        id: 'k4',
        title: '4. عرض الراعي الرسمي',
        type: 'SPONSOR_POPUP',
        duration: 5,
        color_hex: '#FFD600',
      },
    ],
  },
  VICTORY: {
    name: '🏆 عرض التتويج والفوز (Victory Celebration)',
    steps: [
      {
        id: 'v1',
        title: '1. ومضات الذهبية الاحتفالية',
        type: 'STROBE',
        duration: 12,
        color_hex: '#FFD600',
      },
      {
        id: 'v2',
        title: '2. موجة النصر السريعة',
        type: 'WAVE',
        duration: 10,
        color_hex: '#00E676',
      },
      {
        id: 'v3',
        title: '3. عاصفة الفلاش المضيء',
        type: 'STROBE',
        duration: 15,
        color_hex: '#FFFFFF',
      },
    ],
  },
};

export function ShowPlanner({ onTriggerAction, selectedSectors = [], sectorColors = {} }) {
  const [sequence, setSequence] = useState(PRESET_SHOWS.KICKOFF.steps);
  const [activeStepIndex, setActiveStepIndex] = useState(null);
  const [isPlaying, setIsPlaying] = useState(false);
  const [timeLeft, setTimeLeft] = useState(0);

  // New Step Form State
  const [newTitle, setNewTitle] = useState('');
  const [newType, setNewType] = useState('STROBE');
  const [newDuration, setNewDuration] = useState(10);
  const [newColor, setNewColor] = useState('#00E676');

  // Timer Effect for Auto Playback
  useEffect(() => {
    let timer = null;
    if (isPlaying && activeStepIndex !== null) {
      timer = setInterval(() => {
        setTimeLeft((prev) => {
          if (prev <= 1) {
            // Advance to next step if available
            if (activeStepIndex + 1 < sequence.length) {
              const nextIdx = activeStepIndex + 1;
              setActiveStepIndex(nextIdx);
              executeStep(sequence[nextIdx]);
              return sequence[nextIdx].duration;
            } else {
              // End of sequence
              setIsPlaying(false);
              setActiveStepIndex(null);
              onTriggerAction({
                type: 'IDLE',
                target_type: 'ALL',
                target_ids: [],
                duration_seconds: 0,
              });
              return 0;
            }
          }
          return prev - 1;
        });
      }, 1000);
    }

    return () => {
      if (timer) clearInterval(timer);
    };
  }, [isPlaying, activeStepIndex, sequence]);

  const executeStep = (step) => {
    if (!step) return;

    if (step.type === 'TIFO_PAINT') {
      onTriggerAction({
        type: 'TIFO_PAINT',
        target_type: 'SECTOR_MAP',
        target_ids: Object.keys(sectorColors),
        duration_seconds: step.duration,
        sector_colors: sectorColors,
      });
    } else if (step.type === 'WAVE') {
      onTriggerAction({
        type: 'WAVE',
        target_type: 'SECTOR',
        target_ids: selectedSectors,
        color_hex: step.color_hex || '#00E676',
        flash_frequency_ms: 100,
        wave_delay_step_ms: 250,
        duration_seconds: step.duration,
      });
    } else if (step.type === 'SPONSOR_POPUP') {
      onTriggerAction({
        type: 'SPONSOR_POPUP',
        target_type: 'ALL',
        target_ids: [],
        duration_seconds: step.duration,
        sponsor: {
          title: 'عرض استثنائي من الراعي الرسمي لمباراة اليوم 🎁',
          image_url: 'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?w=800&q=80',
          coupon_code: 'MATCH2026',
          link_url: 'https://example.com/stadium-offer',
        },
      });
    } else {
      // STROBE / SOLID_COLOR
      onTriggerAction({
        type: step.type,
        target_type: selectedSectors.length === 10 ? 'ALL' : 'SECTOR',
        target_ids: selectedSectors,
        color_hex: step.color_hex || '#00E676',
        flash_frequency_ms: 150,
        duration_seconds: step.duration,
      });
    }
  };

  const handleStartPlayback = (startIndex = 0) => {
    if (sequence.length === 0) return;
    const targetIdx = startIndex >= 0 && startIndex < sequence.length ? startIndex : 0;
    setActiveStepIndex(targetIdx);
    setTimeLeft(sequence[targetIdx].duration);
    setIsPlaying(true);
    executeStep(sequence[targetIdx]);
  };

  const handlePausePlayback = () => {
    setIsPlaying(false);
  };

  const handleResumePlayback = () => {
    if (activeStepIndex !== null) {
      setIsPlaying(true);
    } else {
      handleStartPlayback(0);
    }
  };

  const handleStopPlayback = () => {
    setIsPlaying(false);
    setActiveStepIndex(null);
    setTimeLeft(0);
    onTriggerAction({
      type: 'IDLE',
      target_type: 'ALL',
      target_ids: [],
      duration_seconds: 0,
    });
  };

  const handleNextStep = () => {
    const nextIdx = (activeStepIndex ?? -1) + 1;
    if (nextIdx < sequence.length) {
      setActiveStepIndex(nextIdx);
      setTimeLeft(sequence[nextIdx].duration);
      setIsPlaying(true);
      executeStep(sequence[nextIdx]);
    } else {
      handleStopPlayback();
    }
  };

  const handlePrevStep = () => {
    const prevIdx = (activeStepIndex ?? 1) - 1;
    if (prevIdx >= 0) {
      setActiveStepIndex(prevIdx);
      setTimeLeft(sequence[prevIdx].duration);
      setIsPlaying(true);
      executeStep(sequence[prevIdx]);
    }
  };

  const handleAddStep = () => {
    if (!newTitle.trim()) return;
    const newStep = {
      id: `step_${Date.now()}`,
      title: `${sequence.length + 1}. ${newTitle.trim()}`,
      type: newType,
      duration: Number(newDuration),
      color_hex: newColor,
    };
    setSequence((prev) => [...prev, newStep]);
    setNewTitle('');
  };

  const handleDeleteStep = (id) => {
    setSequence((prev) => prev.filter((s) => s.id !== id));
  };

  const handleLoadPreset = (presetKey) => {
    const preset = PRESET_SHOWS[presetKey];
    if (preset) {
      handleStopPlayback();
      setSequence(preset.steps);
    }
  };

  const activeStep = activeStepIndex !== null ? sequence[activeStepIndex] : null;

  return (
    <div className="space-y-6">
      {/* Header & Presets Bar */}
      <div className="flex flex-wrap items-center justify-between gap-4 bg-slate-900/90 p-4 rounded-xl border border-slate-800">
        <div>
          <h3 className="text-sm font-bold text-white flex items-center gap-2">
            <ListOrdered className="w-4 h-4 text-emerald-400" />
            مُخطط ومُشغّل العروض المجدولة | Show Sequence Timeline
          </h3>
          <p className="text-xs text-slate-400 mt-0.5">
            قم بإعداد خطوات العرض الضوئي لتشغيلها تلقائياً بالعداد أو التنقل بينها يدوياً
          </p>
        </div>

        {/* Preset Loaders */}
        <div className="flex items-center gap-2">
          <span className="text-xs text-slate-400 flex items-center gap-1 font-bold">
            <Sparkles className="w-3.5 h-3.5 text-amber-400" /> تحميل خطة:
          </span>
          <button
            onClick={() => handleLoadPreset('KICKOFF')}
            className="px-3 py-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-emerald-400 border border-emerald-500/30 text-xs font-bold transition"
          >
            🇸🇦 دخلة المباراة
          </button>
          <button
            onClick={() => handleLoadPreset('VICTORY')}
            className="px-3 py-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-amber-400 border border-amber-500/30 text-xs font-bold transition"
          >
            🏆 التتويج بالفوز
          </button>
        </div>
      </div>

      {/* Active Timeline Player Control Box */}
      <div className="bg-gradient-to-r from-slate-950 via-slate-900 to-slate-950 p-5 rounded-2xl border border-emerald-500/30 shadow-xl relative overflow-hidden">
        <div className="flex flex-wrap items-center justify-between gap-4 relative z-10">
          {/* Current Playing Step Info */}
          <div>
            <div className="text-xs text-slate-400 font-bold uppercase tracking-wider flex items-center gap-2">
              <span className="w-2 h-2 rounded-full bg-emerald-400 animate-ping"></span>
              الخطوة الحالية في العرض:
            </div>
            <div className="text-lg font-black text-white mt-1 flex items-center gap-2">
              {activeStep ? (
                <>
                  <span className="text-emerald-400">{activeStep.title}</span>
                  <span className="text-xs px-2.5 py-0.5 rounded-full bg-emerald-950 text-emerald-300 border border-emerald-500/30 font-mono">
                    {activeStep.type}
                  </span>
                </>
              ) : (
                <span className="text-slate-500 text-base">لا يوجد عرض شغال حالياً (متوقف)</span>
              )}
            </div>
          </div>

          {/* Countdown Timer */}
          <div className="flex items-center gap-3">
            <div className="bg-slate-900/90 px-4 py-2 rounded-xl border border-slate-800 text-center">
              <div className="text-[10px] text-slate-400 font-bold uppercase">الزمن المتبقي</div>
              <div className="text-2xl font-black font-mono text-emerald-400">
                {timeLeft} <span className="text-xs font-normal text-slate-400">ثانية</span>
              </div>
            </div>
          </div>

          {/* Player Transport Controls */}
          <div className="flex items-center gap-2 bg-slate-900/90 p-1.5 rounded-xl border border-slate-800">
            <button
              onClick={handlePrevStep}
              disabled={activeStepIndex === null || activeStepIndex === 0}
              className="p-2.5 rounded-lg bg-slate-800 hover:bg-slate-700 disabled:opacity-30 text-white transition"
              title="الخطوة السابقة"
            >
              <SkipBack className="w-4 h-4" />
            </button>

            {isPlaying ? (
              <button
                onClick={handlePausePlayback}
                className="px-4 py-2 bg-amber-500 hover:bg-amber-400 text-black font-black rounded-lg text-xs flex items-center gap-1.5 transition shadow"
              >
                <Pause className="w-4 h-4 fill-black" /> إيقاف مؤقت
              </button>
            ) : (
              <button
                onClick={handleResumePlayback}
                className="px-4 py-2 bg-emerald-500 hover:bg-emerald-400 text-black font-black rounded-lg text-xs flex items-center gap-1.5 transition shadow shadow-emerald-500/20"
              >
                <Play className="w-4 h-4 fill-black" /> بدء/استئناف العرض
              </button>
            )}

            <button
              onClick={handleNextStep}
              disabled={sequence.length === 0}
              className="px-3.5 py-2 rounded-lg bg-cyan-500 hover:bg-cyan-400 text-black font-black text-xs flex items-center gap-1 transition shadow"
              title="الخطوة التالية فوراً"
            >
              التالي <SkipForward className="w-4 h-4 fill-black" />
            </button>

            <button
              onClick={handleStopPlayback}
              className="p-2.5 rounded-lg bg-red-950 hover:bg-red-900 text-red-400 transition"
              title="إيقاف الكلي"
            >
              <Square className="w-4 h-4 fill-red-400" />
            </button>
          </div>
        </div>
      </div>

      {/* Sequence Steps Table / List */}
      <div className="bg-slate-950 p-4 rounded-xl border border-slate-800 space-y-3">
        <h4 className="text-xs font-bold text-slate-300 uppercase tracking-wider mb-2">
          قائمة خطوات العرض المجدولة ({sequence.length} خطوات)
        </h4>

        <div className="space-y-2">
          {sequence.map((step, idx) => {
            const isCurrent = activeStepIndex === idx;
            return (
              <div
                key={step.id}
                className={`p-3 rounded-xl border transition flex items-center justify-between gap-3 ${
                  isCurrent
                    ? 'bg-emerald-950/60 border-emerald-500 text-white shadow-lg'
                    : 'bg-slate-900/60 border-slate-800 text-slate-300'
                }`}
              >
                <div className="flex items-center gap-3">
                  <span
                    className={`w-7 h-7 rounded-full flex items-center justify-center font-bold text-xs ${
                      isCurrent
                        ? 'bg-emerald-500 text-black font-black'
                        : 'bg-slate-800 text-slate-400'
                    }`}
                  >
                    {idx + 1}
                  </span>

                  <div>
                    <div className="font-bold text-sm text-white flex items-center gap-2">
                      {step.title}
                      {step.color_hex && (
                        <span
                          className="w-3 h-3 rounded-full border border-white/40"
                          style={{ backgroundColor: step.color_hex }}
                        />
                      )}
                    </div>
                    <div className="text-[11px] text-slate-400 flex items-center gap-3 mt-0.5">
                      <span className="font-mono text-cyan-400">التأثير: {step.type}</span>
                      <span className="flex items-center gap-1 font-mono text-amber-400">
                        <Clock className="w-3 h-3" /> {step.duration} ثواني
                      </span>
                    </div>
                  </div>
                </div>

                <div className="flex items-center gap-2">
                  <button
                    onClick={() => handleStartPlayback(idx)}
                    className="px-3 py-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-emerald-400 text-xs font-bold flex items-center gap-1"
                  >
                    <Play className="w-3 h-3 fill-emerald-400" /> تشغيل هنا
                  </button>

                  <button
                    onClick={() => handleDeleteStep(step.id)}
                    className="p-1.5 rounded-lg bg-slate-800 hover:bg-red-950 text-slate-500 hover:text-red-400 transition"
                  >
                    <Trash2 className="w-3.5 h-3.5" />
                  </button>
                </div>
              </div>
            );
          })}
        </div>

        {/* Add New Step Form */}
        <div className="pt-4 mt-4 border-t border-slate-800/80">
          <h5 className="text-xs font-bold text-slate-400 block mb-2">إضافة خطوة جديدة للعرض:</h5>
          <div className="grid grid-cols-1 sm:grid-cols-12 gap-2">
            <input
              type="text"
              placeholder="اسم الخطوة (مثال: ومضات الحماس)"
              value={newTitle}
              onChange={(e) => setNewTitle(e.target.value)}
              className="sm:col-span-4 bg-slate-900 border border-slate-800 rounded-lg px-3 py-2 text-xs text-white"
            />
            <select
              value={newType}
              onChange={(e) => setNewType(e.target.value)}
              className="sm:col-span-3 bg-slate-900 border border-slate-800 rounded-lg px-3 py-2 text-xs text-white"
            >
              <option value="STROBE">STROBE (ومضات فلاش)</option>
              <option value="TIFO_PAINT">TIFO_PAINT (تيفو ملون)</option>
              <option value="WAVE">WAVE (موجة ملفتة)</option>
              <option value="SPONSOR_POPUP">SPONSOR (بطاقة الراعي)</option>
            </select>
            <input
              type="number"
              min="2"
              max="60"
              value={newDuration}
              onChange={(e) => setNewDuration(e.target.value)}
              className="sm:col-span-2 bg-slate-900 border border-slate-800 rounded-lg px-3 py-2 text-xs text-white"
              title="المدة بالثواني"
            />
            <input
              type="color"
              value={newColor}
              onChange={(e) => setNewColor(e.target.value)}
              className="sm:col-span-1 h-9 rounded bg-slate-900 border border-slate-800 cursor-pointer w-full"
            />
            <button
              onClick={handleAddStep}
              className="sm:col-span-2 py-2 bg-emerald-500 hover:bg-emerald-400 text-black font-bold rounded-lg text-xs flex items-center justify-center gap-1 transition"
            >
              <Plus className="w-4 h-4" /> إضافة الخطوة
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
