import React, { useState, useEffect } from 'react';
import { Zap, Activity, Type, Gift, Play, StopCircle, Sliders, Paintbrush, AlertTriangle, Command, ListOrdered, Music, Trophy } from 'lucide-react';
import { ShowPlanner } from './ShowPlanner';
import { AudioBeatSync } from './AudioBeatSync';
import { updateActiveMatchInfo } from '../services/firebaseAdminService';

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

  // Active Match Manager State
  const [homeTeam, setHomeTeam] = useState('الهلال');
  const [awayTeam, setAwayTeam] = useState('النصر');
  const [stadiumName, setStadiumName] = useState('أرينا العاصمة المغطاة');
  const [statusText, setStatusText] = useState('مباشر الان 🔥');
  const [matchUpdateNotice, setMatchUpdateNotice] = useState('');

  // Row Target Filter State
  const [rowFilter, setRowFilter] = useState('ALL');

  // Hardware Target Selector
  const [hardwareTarget, setHardwareTarget] = useState('BOTH');

  // Global Keyboard Hotkeys for Studio Operator
  useEffect(() => {
    const handleKeyDown = (e) => {
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
      target_row_filter: rowFilter,
      hardware_target: hardwareTarget,
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
      target_row_filter: rowFilter,
      hardware_target: hardwareTarget,
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
      target_row_filter: rowFilter,
      hardware_target: hardwareTarget,
      duration_seconds: 5,
      sponsor: {
        title: sponsorTitle,
        image_url: 'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?w=800&q=80',
        coupon_code: sponsorCode,
        link_url: 'https://example.com/stadium-offer',
      },
    });
  };

  const handleBroadcastMatchInfo = async () => {
    setMatchUpdateNotice('جاري التحديث على الفايربيس...');
    const result = await updateActiveMatchInfo({
      homeTeam,
      awayTeam,
      stadiumName,
      statusText,
      isLive: true,
    });
    if (result && result.success) {
      setMatchUpdateNotice('✨ تم تحديث بيانات المباراة بنجاح على جوالات جميع المشجعين!');
      setTimeout(() => setMatchUpdateNotice(''), 4000);
    }
  };

  const handleEmergencyAllWhite = () => {
    onTriggerAction({
      type: 'SOLID_COLOR',
      target_type: 'ALL',
      target_ids: [],
      hardware_target: hardwareTarget,
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
      <div className="grid grid-cols-2 sm:grid-cols-7 gap-2">
        {[
          { id: 'GOAL', label: 'Goal Strobe ⚡', icon: Zap, color: 'text-emerald-400' },
          { id: 'MATCH_INFO', label: 'إدارة المباراة ⚽', icon: Trophy, color: 'text-amber-400' },
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

      {/* Active Tab Panel Rendering */}
      {activeTab === 'MATCH_INFO' && (
        <div className="bg-slate-900/80 p-5 rounded-xl border border-slate-800 space-y-4">
          <h3 className="text-sm font-bold text-amber-400 flex items-center gap-2">
            <Trophy className="w-4 h-4" />
            إدارة وتحديث بيانات المباراة الحية على جوالات المشجعين
          </h3>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="text-xs text-slate-400 block mb-1">الفريق الأول (Home Team):</label>
              <input
                type="text"
                value={homeTeam}
                onChange={(e) => setHomeTeam(e.target.value)}
                className="w-full px-3 py-2 bg-slate-950 border border-slate-700 rounded-lg text-white text-xs"
              />
            </div>
            <div>
              <label className="text-xs text-slate-400 block mb-1">الفريق الثاني (Away Team):</label>
              <input
                type="text"
                value={awayTeam}
                onChange={(e) => setAwayTeam(e.target.value)}
                className="w-full px-3 py-2 bg-slate-950 border border-slate-700 rounded-lg text-white text-xs"
              />
            </div>
            <div>
              <label className="text-xs text-slate-400 block mb-1">اسم الملعب (Stadium):</label>
              <input
                type="text"
                value={stadiumName}
                onChange={(e) => setStadiumName(e.target.value)}
                className="w-full px-3 py-2 bg-slate-950 border border-slate-700 rounded-lg text-white text-xs"
              />
            </div>
            <div>
              <label className="text-xs text-slate-400 block mb-1">نص الحالة (Match Status):</label>
              <input
                type="text"
                value={statusText}
                onChange={(e) => setStatusText(e.target.value)}
                className="w-full px-3 py-2 bg-slate-950 border border-slate-700 rounded-lg text-white text-xs"
              />
            </div>
          </div>

          {matchUpdateNotice && (
            <div className="p-2 bg-emerald-500/20 border border-emerald-500 text-emerald-300 text-xs font-bold rounded-lg text-center">
              {matchUpdateNotice}
            </div>
          )}

          <button
            onClick={handleBroadcastMatchInfo}
            className="w-full py-3 bg-gradient-to-r from-emerald-500 to-cyan-500 text-black font-extrabold rounded-xl hover:opacity-90 transition text-xs flex items-center justify-center gap-2"
          >
            <Play className="w-4 h-4 fill-black" />
            🚀 بث وتحديث المباراة حياً على جميع الجوالات المتصلة
          </button>
        </div>
      )}

      {activeTab === 'GOAL' && (
        <div className="bg-slate-900/80 p-5 rounded-xl border border-slate-800 space-y-4">
          <div className="flex flex-wrap items-center justify-between gap-4">
            <span className="text-xs font-bold text-white">إعدادات الوميض واللون:</span>
            <div className="flex items-center gap-2">
              <input
                type="color"
                value={strobeColor}
                onChange={(e) => setStrobeColor(e.target.value)}
                className="w-8 h-8 rounded border-0 cursor-pointer bg-transparent"
              />
              <input
                type="text"
                value={strobeColor}
                onChange={(e) => setStrobeColor(e.target.value)}
                className="w-24 px-2 py-1 bg-slate-950 border border-slate-700 rounded text-xs text-white uppercase font-mono"
              />
            </div>
          </div>
          <button
            onClick={handleTriggerGoalFlash}
            className="w-full py-3 bg-gradient-to-r from-emerald-500 to-cyan-500 text-black font-extrabold rounded-xl hover:opacity-90 transition text-xs flex items-center justify-center gap-2"
          >
            <Zap className="w-4 h-4 fill-black" />
            تفعيل وميض الفلاش (Goal Celebration Strobe)
          </button>
        </div>
      )}

      {activeTab === 'WAVE' && (
        <div className="bg-slate-900/80 p-5 rounded-xl border border-slate-800 space-y-4">
          <button
            onClick={handleTriggerWave}
            className="w-full py-3 bg-gradient-to-r from-cyan-500 to-blue-500 text-black font-extrabold rounded-xl hover:opacity-90 transition text-xs flex items-center justify-center gap-2"
          >
            <Activity className="w-4 h-4" />
            إطلاق تأثير التيفو الموجي (Wave Strobe)
          </button>
        </div>
      )}

      {activeTab === 'MUSIC' && (
        <AudioBeatSync onTriggerBeat={onTriggerAction} />
      )}

      {activeTab === 'PLANNER' && (
        <ShowPlanner onTriggerAction={onTriggerAction} />
      )}
    </div>
  );
}
